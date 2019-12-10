//
//  SafariExtensionHandler.swift
//  Safari
//
//  Copyright © 2019 DuckDuckGo. All rights reserved.
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
import SyncSupport
import os

// See https://developer.apple.com/videos/play/wwdc2019/720/
class SafariExtensionHandler: SFSafariExtensionHandler {

    enum Messages: String {
        case resourceLoaded
        case userAgent
        case beforeUnload
    }
    
    private let pixel: Pixel = Dependencies.shared.pixel
    private let deepDetection = DeepDetection()
    
    override func contentBlocker(withIdentifier contentBlockerIdentifier: String, blockedResourcesWith urls: [URL], on page: SFSafariPage) {
        page.getPropertiesOnQueue { properties in
            guard let pageUrl = properties?.url else { return }
            let trackerDetection = Dependencies.shared.trackerDetection
            DashboardData.shared.trackers(Set<DetectedTracker>(urls.map {
                trackerDetection.detectedTrackerFrom(resourceUrl: $0, onPageWithUrl: pageUrl)
            }), blockedOnPage: page, forUrl: pageUrl.absoluteString)
        }
    }
    
    // This doesn't appear to get called when the page is closed though
    override func page(_ page: SFSafariPage, willNavigateTo url: URL?) {
        DispatchQueue.dashboard.async {
            DashboardData.shared.clear(page)
            DashboardData.shared.setCurrentPage(to: page, withUrl: url)
            self.updateRetentionData()
        }
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        guard let message = Messages(rawValue: messageName) else {
            return
        }
        
        switch message {
        case .resourceLoaded:
            self.handleResourceLoadedMessage(userInfo, onPage: page)

        case .userAgent:
            self.handleUserAgentMessage(userInfo)

        case .beforeUnload:
            self.handleBeforeUnloadMessage(from: page)
        }
    }
    
    func handleBeforeUnloadMessage(from page: SFSafariPage) {
        DashboardData.shared.evictInactivePages()
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
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
        SyncScheduler.shared.schedule()
        DispatchQueue.dashboard.async {
            DashboardData.shared.setCurrentPage(to: nil, withUrl: nil)
            self.updateToolbar()
        }
    }
    
    private func updateToolbar() {
        SFSafariApplication.getActiveWindow { window in
            window?.getToolbarItem { toolbarItem in
                guard let toolbarItem = toolbarItem else { return }
                window?.getActiveTab { tabs in
                    tabs?.getActivePage(completionHandler: { page in
                        guard let page = page else {
                            toolbarItem.setImage(nil)
                            return
                        }
                        page.getPropertiesOnQueue { properties in
                            DashboardData.shared.setCurrentPage(to: page, withUrl: properties?.url)
                            self.update(toolbarItem)
                        }
                    })
                }
            }
        }
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        pixel.fire(.dashboardPopupOpened)
        SafariExtensionViewController.shared.pageData = DashboardData.shared.pageData
        SafariExtensionViewController.shared.currentWindow = window
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        
        guard let resources = userInfo?["resources"] as? [[String: String]] else { return }
                
        page.getPropertiesOnQueue { properties in
            let trackerDetection = Dependencies.shared.trackerDetection
            guard let pageUrl = properties?.url else { return }

            var detectedTrackers = Set<DetectedTracker>()
            resources.forEach { resource in
                self.deepDetection.check(resource: resource["url"], onPage: pageUrl)

                if let url = resource["url"],
                    let resourceUrl = URL(withResource: url, relativeTo: pageUrl),
                    let detectedTracker = trackerDetection.detectTrackerFor(resourceUrl: resourceUrl,
                                                                    onPageWithUrl: pageUrl,
                                                                    asResourceType: resource["type"]) {
                    detectedTrackers.insert(detectedTracker)
                }
            }

            guard !detectedTrackers.isEmpty else { return }
            DashboardData.shared.trackers(detectedTrackers, loadedOnPage: page, forUrl: pageUrl.absoluteString)
            self.updateToolbar()
        }
        
    }
    
    private func update(_ toolbarItem: SFSafariToolbarItem) {
        guard let url = DashboardData.shared.pageData.url else {
            toolbarItem.setImage(nil)
            SafariExtensionViewController.shared.pageData = DashboardData.shared.pageData
            return
        }
        
        let grade = DashboardData.shared.pageData.calculateGrade()
        let site = Dependencies.shared.trustedSitesManager.isTrusted(url: url) ? grade.site : grade.enhanced
        let grading = site.grade
        
        toolbarItem.setImage(grading.image)
    }
    
    private func updateRetentionData() {
        let bundle = Bundle(for: type(of: self))
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: bundle.bundleIdentifier!) { state, _ in
            if state?.isEnabled ?? false {
                DefaultStatisticsLoader.shared.refreshAppRetentionAtb(atLocation: AtbLocations.safariExtensionHandler, completion: nil)
            }
        }
    }

    override init() {
        os_log("SEH init", log: lifecycleLog)
        super.init()
        SyncScheduler.shared.schedule()
    }
        
    deinit {
        os_log("SEH deinit", log: lifecycleLog)
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
