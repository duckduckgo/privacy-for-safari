//
//  SafariExtensionActor.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SafariServices
import TrackerBlocking
import Statistics
import os

/// This actor replaces the 'queue' mechanism in order to try and have concurrent access from the extension handler to the state held by the app.
actor SafariExtensionActor {

    enum Messages: String {
        case resourceLoaded
        case userAgent
        case beforeUnload
        case DOMContentLoaded
    }

    private let pixel: Pixel = Dependencies.shared.pixel
    private let deepDetection = DeepDetection()

    func contentBlocker(withIdentifier contentBlockerIdentifier: String, blockedResourcesWith urls: [URL], on page: SFSafariPage) async {
        let properties = await page.properties()
        guard let pageUrl = properties?.url else { return }
        let trackerDetection = Dependencies.shared.trackerDetection
        let trackerDataManager = Dependencies.shared.trackerDataManager
        let detectedTrackers = Set<DetectedTracker>(urls.map {            
            trackerDetection.detectedTrackerFrom(resourceUrl: trackerDataManager.canonicalURL(forUrl: $0), onPageWithUrl: pageUrl)
        })

        os_log("SEH contentBlocker %{public}s", log: generalLog, type: .debug, "\(detectedTrackers.map { $0.resource.absoluteString })")

        await DashboardData.shared.blockedTrackers(detectedTrackers, onPage: page, forUrl: pageUrl.absoluteString)
    }

    // This doesn't appear to get called when the page is closed though
    func page(_ page: SFSafariPage, willNavigateTo url: URL?) async {
        guard let url = url else {
            await SafariExtensionViewController.shared.dismissPopover()
            return
        }

        let tab = await page.containingTab()
        await DashboardData.shared.clearCache(forPage: page, withUrl: url.absoluteString)
        await DashboardData.shared.setCurrentPage(to: page, withUrl: url)
        await SafariTabAddClickAttribution.shared.handlePageNavigationToURL(url, inTab: tab)
    }

    func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) async {
        guard let message = Messages(rawValue: messageName) else {
            return
        }

        switch message {
        case .resourceLoaded:
            await self.handleResourceLoadedMessage(userInfo, onPage: page)        

        case .userAgent:
            self.handleUserAgentMessage(userInfo)

        case .beforeUnload:
            await self.handleBeforeUnloadMessage(from: page)

        case .DOMContentLoaded:
            await self.handleDOMContentLoadedMessage(from: page)
        }
    }

    func handleDOMContentLoadedMessage(from page: SFSafariPage) async {
        let properties = await page.properties()
        guard let url = properties?.url else {
            return
        }

        os_log("SEH handleDOMContentLoadedMessage %{public}s", log: generalLog, type: .debug, url.absoluteString)

        let tab = await page.containingTab()
        await SafariTabAddClickAttribution.shared.pageFinishedLoading(url, forTab: tab)
    }

    func handleBeforeUnloadMessage(from page: SFSafariPage) async {
        await DashboardData.shared.evictInactivePages()
        Task { // This can happen async from this actor
            await SafariTabAddClickAttribution.shared.clearExpiredVendors()
        }
    }

    func handleUserAgentMessage(_ userInfo: [String: Any]?) {
        guard let userAgent = userInfo?["userAgent"] as? String else { return }
        let values = userAgent.components(separatedBy: " ")
        guard let version = values.first(where: { $0.hasPrefix("Version/") }) else { return }
        let components = version.components(separatedBy: "/")
        guard components.count > 1 else { return }
        let safariVersion = components[1]
        var store = Statistics.Dependencies.shared.statisticsStore
        store.browserVersion = safariVersion
    }

    func validateToolbarItem(in window: SFSafariWindow) async {
        SyncScheduler.shared.schedule()
        await DashboardData.shared.setCurrentPage(to: nil, withUrl: nil)
        await self.updateToolbar()
    }

    @MainActor
    private func updateToolbar() async {
        guard let activeWindow = await SFSafariApplication.activeWindow(),
              let toolbarItem = await activeWindow.toolbarItem() else {
            os_log("SEH updateToolbar no window or toolbarItem", log: generalLog, type: .debug)
            return
        }

        guard let activePage = await activeWindow.activeTab()?.activePage(),
              let properties = await activePage.properties(),
              let url = properties.url else {
            await SafariExtensionViewController.shared.dismissPopover()
            toolbarItem.setImage(ToolbarIcon.currentIcon)
            return
        }

        await DashboardData.shared.setCurrentPage(to: activePage, withUrl: url)
        let grade = await DashboardData.shared.pageData.calculateGrade()
        let site = Dependencies.shared.trustedSitesManager.isTrusted(url: url) ? grade.site : grade.enhanced
        let grading = site.grade

        toolbarItem.setImage(grading.image)
    }

    @MainActor
    func popoverWillShow(in window: SFSafariWindow) async {
        pixel.fire(.dashboardPopupOpened)
        SafariExtensionViewController.shared.currentWindow = window
        SafariExtensionViewController.shared.pageData = await DashboardData.shared.pageData
    }

    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) async {

        guard let resources = userInfo?["resources"] as? [[String: String]] else { return }
        guard let pageUrl = await page.properties()?.url else { return }

        var detectedTrackers = Set<DetectedTracker>()
        var detectedRequests = Set<PageData.DetectedRequest>()

        for resource in resources {
            guard let url = resource["url"],
                  let resourceUrl = URL(withResource: url, relativeTo: pageUrl) else {
                return
            }

            self.deepDetection.check(resource: url, onPage: pageUrl)

            let canonicalResourceURL = Dependencies.shared.trackerDataManager.canonicalURL(forUrl: resourceUrl)

            // Only send pixels the first time we see ad click resources.  An ad click resource
            //  can load a bunch of other resources with the same host so we don't want to over count.
            if SafariTabAddClickAttribution.shared.isExemptAllowListResource(canonicalResourceURL),
               !(await DashboardData.shared.hasResourceBeenSeenBefore(canonicalResourceURL, onPage: page, withUrl: pageUrl)) {

                SafariTabAddClickAttribution.shared.firePixelForResourceIfNeeded(resourceURL: canonicalResourceURL, onPage: pageUrl)

                await SafariTabAddClickAttribution.shared.incrementAdClickPageLoadCounter()
            }

            // For the purposes of reporting, true first party requests should be ignored entirely.
            if isFirstPartyResource(resourceUrl, ofPage: pageUrl) {
                return
            }

            os_log("SEH handleResourceLoadedMessage %{public}s", log: generalLog, type: .debug, resourceUrl.absoluteString)
            updateTrackersOrRequests(&detectedTrackers, &detectedRequests,
                                     withResourceURL: canonicalResourceURL,
                                     ofType: resource["type"],
                                     forPage: pageUrl)
        }

        // Don't update unless needed
        if !detectedTrackers.isEmpty || !detectedRequests.isEmpty {
            await DashboardData.shared.loadedTrackers(detectedTrackers,
                                                      andRequests: detectedRequests,
                                                      onPage: page,
                                                      forUrl: pageUrl.absoluteString)
            await self.updateToolbar()
        }
    }

    func updateTrackersOrRequests(_ trackers: inout Set<DetectedTracker>,
                                  _ requests: inout Set<PageData.DetectedRequest>,
                                  withResourceURL resourceUrl: URL,
                                  ofType type: String?, forPage pageUrl: URL) {

        let trackerDetection = Dependencies.shared.trackerDetection
        if let detectedTracker = trackerDetection.detectTrackerFor(resourceUrl: resourceUrl,
                                                                      onPageWithUrl: pageUrl,
                                                                   asResourceType: type) {
            trackers.insert(detectedTracker)

        } else if let entityDomain = resourceUrl.eTLDPlus1Host,
                    let host = resourceUrl.host,
                    host != pageUrl.host {

            let mgr = Dependencies.shared.trackerDataManager
            let owner = mgr.owner(forUrl: resourceUrl) ?? entityDomain

            let displayName = mgr.entity(forUrl: resourceUrl)?.displayName ?? entityDomain
            requests.insert(.init(displayName: displayName, owner: owner, domain: host, url: resourceUrl))

        }
    }

    func isFirstPartyResource(_ resource: URL, ofPage page: URL) -> Bool {
        guard let resourceHost = resource.host,
              // not even possible to be first party if these don't match:
              resource.eTLDPlus1Host == page.eTLDPlus1Host
        else { return false }

        // No entry in the cnames list, means this is a first party request
        return Dependencies.shared.trackerDataManager.trackerData?.cnames?[resourceHost] == nil
    }

}

extension Grade.Grading {

    static let images: [Grade.Grading: NSImage] = [
        .a: NSImage(named: "PP Indicator Grade A")!,
        .bPlus: NSImage(named: "PP Indicator Grade B Plus")!,
        .b: NSImage(named: "PP Indicator Grade B")!,
        .cPlus: NSImage(named: "PP Indicator Grade C Plus")!,
        .c: NSImage(named: "PP Indicator Grade C")!,
        .d: NSImage(named: "PP Indicator Grade D")!
    ]

    var image: NSImage? {
        return Grade.Grading.images[self]
    }

}

extension TrackerDataManager {

    public func owner(forUrl url: URL) -> String? {
        for host in url.hostVariations ?? [] {
            os_log("findOwner checking host %{public}s", log: generalLog, type: .debug, host)
            if let entityName = trackerData?.domains[host] {
                os_log("findOwner finding entity name %{public}s", log: generalLog, type: .debug, entityName)
                return entityName
            }
        }
        os_log("findOwner no owner %{public}s", log: generalLog, type: .debug, url.absoluteString)
        return nil
    }

}
