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
import os

// See https://developer.apple.com/videos/play/wwdc2019/720/
class SafariExtensionHandler: SFSafariExtensionHandler {
    
    class Data {
        
        static let shared = Data()
        
        private(set) var pageData: PageData = PageData()
        private(set) var currentPage: SFSafariPage?
        
        private var activePageTrackers = [Int: Trackers]()

        /// An in-memory cache of trackers seen on previos urls.  Used when navigating backwards and forward and site is not reloaded by Safari.
        private var trackersCache = NSCache<NSString, Trackers>()
        
        init() {
            trackersCache.countLimit = 1000
        }
        
        func trackers(forActivePage page: SFSafariPage) -> Trackers {
            return activePageTrackers[page.pageId, default: Trackers()]
        }
        
        func cachedTrackers(forUrl url: String) -> Trackers? {
            return trackersCache.object(forKey: url as NSString)
        }
                
        func trackers(_ trackers: [DetectedTracker], loadedOnPage page: SFSafariPage, forUrl url: String) {
            DiagnosticSupport.dump(trackers, blocked: false)
            
            let pageTrackers = activePageTrackers[page.pageId, default: Trackers()]
            pageTrackers.loaded += trackers
            activePageTrackers[page.pageId] = pageTrackers
            trackersCache.setObject(pageTrackers, forKey: url as NSString)
            
            if page == currentPage {
                refreshDashboard()
            }
        }
        
        func trackers(_ trackers: [DetectedTracker], blockedOnPage page: SFSafariPage) {
            DiagnosticSupport.dump(trackers, blocked: true)
            
            trackers.forEach {
                os_log("BLOCKED %{public}s on %s", log: generalLog, type: .default, $0.resource.absoluteString, $0.page.absoluteString)
            }
                        
            let pageTrackers = activePageTrackers[page.pageId, default: Trackers()]
            pageTrackers.blocked += trackers
            activePageTrackers[page.pageId] = pageTrackers
            if page == currentPage {
                refreshDashboard()
            }
        }
        
        func setCurrentPage(to page: SFSafariPage?, withUrl url: URL?) {
            pageData = PageData(url: url)
            
            guard let page = page else { return }
            currentPage = page
            
            var trackers = activePageTrackers[page.pageId, default: Trackers()]

            if !trackers.trackersDetected, let url = url, let cached = cachedTrackers(forUrl: url.absoluteString) {
                os_log("Using cached result for page trackers", log: generalLog, type: .default)
                trackers = cached
            }

            pageData.loadedTrackers = trackers.loaded
            pageData.blockedTrackers = trackers.blocked
            refreshDashboard()
        }
        
        func clear(_ page: SFSafariPage) {
            activePageTrackers.removeValue(forKey: page.pageId)
            if page == currentPage {
                currentPage = nil
            }
        }
                
        private func refreshDashboard(_ function: StaticString = #function) {
            DispatchQueue.main.async {
                SafariExtensionViewController.shared.pageData = self.pageData
            }
        }
    }
    
    enum Messages: String {
        case resourceLoaded
        case beforeUnload
        case userAgent
    }
    
    class Trackers {
        var loaded = [DetectedTracker]()
        var blocked = [DetectedTracker]()
        
        var trackersDetected: Bool {
            return !loaded.isEmpty || !blocked.isEmpty
        }
    }

    private let pixel: Pixel = Dependencies.shared.pixel
    private let deepDetection = DeepDetection()

    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)
        updateRetentionData()
    }
    
    override func contentBlocker(withIdentifier contentBlockerIdentifier: String, blockedResourcesWith urls: [URL], on page: SFSafariPage) {
        page.getPropertiesWithCompletionHandler { properties in
            guard let pageUrl = properties?.url else { return }
            
            let trackerDetection = Dependencies.shared.trackerDetection
            Data.shared.trackers(urls.map { trackerDetection.detectedTrackerFrom(resourceUrl: $0, onPageWithUrl: pageUrl) }, blockedOnPage: page)
        }
        
    }
    
    // This doesn't appear to get called when the page is closed though
    override func page(_ page: SFSafariPage, willNavigateTo url: URL?) {
        Data.shared.clear(page)
        Data.shared.setCurrentPage(to: page, withUrl: url)
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        guard let message = Messages(rawValue: messageName) else {
            return
        }
        
        switch message {
        case .resourceLoaded:
            handleResourceLoadedMessage(userInfo, onPage: page)
            
        case .beforeUnload:
            handleBeforeUnloadMessage(onPage: page)
            
        case .userAgent:
            handleUserAgentMessage(userInfo)
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
    
    func handleBeforeUnloadMessage(onPage page: SFSafariPage) {
        // Apple bug in getContainingTab documentation, tab can be nil
        page.getContainingTab { tab in
            let tab: SFSafariTab? = tab
            if tab == nil {
                os_log("Tab was closed", log: generalLog, type: .debug)
                Data.shared.clear(page)
            }
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
        Data.shared.setCurrentPage(to: nil, withUrl: nil)
        updateToolbar()
    }
    
    private func updateToolbar() {
        SFSafariApplication.getActiveWindow { window in
            window?.getToolbarItem { toolbarItem in
                guard let toolbarItem = toolbarItem else { return }
                toolbarItem.setImage(NSImage(named: NSImage.Name("LogoToolbarItemIcon")))
                window?.getActiveTab { tabs in
                    tabs?.getActivePage(completionHandler: { page in
                        guard let page = page else { return }
                        page.getPropertiesWithCompletionHandler({ properties in
                            Data.shared.setCurrentPage(to: page, withUrl: properties?.url)
                            self.update(toolbarItem)
                        })
                    })
                }
            }
        }
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        pixel.fire(.dashboardPopupOpened)
        SafariExtensionViewController.shared.pageData = Data.shared.pageData
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        guard let resources = userInfo?["resources"] as? [[String: String]] else { return }
                
        page.getPropertiesWithCompletionHandler { properties in
            let trackerDetection = Dependencies.shared.trackerDetection
            guard let pageUrl = properties?.url else { return }
            
            var detectedTrackers = [DetectedTracker]()
            resources.forEach { resource in
                self.deepDetection.check(resource: resource["url"], onPage: pageUrl)
                
                if let url = resource["url"],
                    let resourceUrl = URL(withResource: url, relativeTo: pageUrl),
                    let detectedTracker = trackerDetection.detectTrackerFor(resourceUrl: resourceUrl,
                                                                    onPageWithUrl: pageUrl,
                                                                    asResourceType: resource["type"]) {
                    detectedTrackers.append(detectedTracker)
                }
            }
            
            guard !detectedTrackers.isEmpty else { return }
            Data.shared.trackers(detectedTrackers, loadedOnPage: page, forUrl: pageUrl.absoluteString)
            self.updateToolbar()
        }
        
    }
    
    private func update(_ toolbarItem: SFSafariToolbarItem) {
        guard let url = Data.shared.pageData.url else {
            toolbarItem.setImage(NSImage(named: NSImage.Name("LogoToolbarItemIcon")))
            return
        }
        
        let grade = Data.shared.pageData.calculateGrade()
        let site = Dependencies.shared.trustedSitesManager.isTrusted(url: url) ? grade.site : grade.enhanced
        let grading = site.grade
        
        toolbarItem.setImage(grading.image)
    }
    
    private func updateRetentionData() {
        let bundle = Bundle(for: type(of: self))
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: bundle.bundleIdentifier!) { state, _ in
            if state?.isEnabled ?? false {
                DefaultStatisticsLoader().refreshAppRetentionAtb(atLocation: "seh", completion: nil)
            }
        }
    }
    
}

private extension SFSafariPage {
    var pageId: Int {
        return hash
    }
}

extension Grade.Grading {
    
    static let images: [Grade.Grading: NSImage] = [
        .a: NSImage(named: "PP Indicator Grade A")!,
        .bPlus: NSImage(named: "PP Indicator Grade B Plus")!,
        .b: NSImage(named: "PP Indicator Grade B")!,
        .cPlus: NSImage(named: "PP Indicator Grade C Plus")!,
        .c: NSImage(named: "PP Indicator Grade C")!,
        .d: NSImage(named: "PP Indicator Grade D")!,
        .dMinus: NSImage(named: "PP Indicator Grade D")!
    ]
    
    var image: NSImage? {
        return Grade.Grading.images[self]
    }
    
}
