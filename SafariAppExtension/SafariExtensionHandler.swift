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

// See https://developer.apple.com/videos/play/wwdc2019/720/
class SafariExtensionHandler: SFSafariExtensionHandler {
    
    class Data {
        
        static let shared = Data()
        
        private(set) var pageData: PageData = PageData()
        private(set) var currentPage: SFSafariPage?
        
        private var trackersPerPage = [SFSafariPage: Trackers]()
        
        func trackers(forPage page: SFSafariPage) -> Trackers {
            return trackersPerPage[page, default: Trackers()]
        }
        
        func trackers(_ trackers: [DetectedTracker], loadedOnPage page: SFSafariPage) {
            DiagnosticSupport.dump(trackers, blocked: false)
            var pageTrackers = trackersPerPage[page, default: Trackers()]
            pageTrackers.loaded += trackers
            trackersPerPage[page] = pageTrackers
            if page == currentPage {
                refreshDashboard()
            }
        }
        
        func trackers(_ trackers: [DetectedTracker], blockedOnPage page: SFSafariPage) {
            DiagnosticSupport.dump(trackers, blocked: true)
            var pageTrackers = trackersPerPage[page, default: Trackers()]
            pageTrackers.blocked += trackers
            trackersPerPage[page] = pageTrackers
            if page == currentPage {
                refreshDashboard()
            }
        }
        
        func setCurrentPage(to page: SFSafariPage?, withUrl url: URL?) {
            pageData = PageData(url: url)
            
            guard let page = page else { return }
            
            currentPage = page
            
            let trackers = trackersPerPage[page, default: Trackers()]
            pageData.loadedTrackers = trackers.loaded
            pageData.blockedTrackers = trackers.blocked
            
            refreshDashboard()
        }
        
        func clear(_ page: SFSafariPage) {
            NSLog("Clearing data for page \(page as Any)")
            
            trackersPerPage.removeValue(forKey: page)
            
            if page == currentPage {
                currentPage = nil
            }
        }
                
        private func refreshDashboard(_ function: StaticString = #function) {
            NSLog("refreshing dashboard from \(function)")
            DispatchQueue.main.async {
                SafariExtensionViewController.shared.pageData = self.pageData
            }
        }
    }
    
    enum Messages: String {
        case resourceLoaded
    }
    
    struct Trackers {
        var loaded = [DetectedTracker]()
        var blocked = [DetectedTracker]()
    }
    
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
    }
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        guard let message = Messages(rawValue: messageName) else {
            return
        }
        
        switch message {
        case .resourceLoaded:
            handleResourceLoadedMessage(userInfo, onPage: page)
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        NSLog("validateToolbarItem")
        
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
        NSLog("popoverWillShow \(Data.shared.pageData.url?.absoluteString ?? "<no url>")")
        SafariExtensionViewController.shared.pageData = Data.shared.pageData
        SafariExtensionViewController.shared.viewWillAppear()
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        guard let resources = userInfo?["resources"] as? [[String: String]] else {
            return
        }
        
        NSLog("checking \(resources.count) resources ")
        
        page.getPropertiesWithCompletionHandler { properties in
            let trackerDetection = Dependencies.shared.trackerDetection
            guard let pageUrl = properties?.url else { return }
            
            NSLog("\(resources.count) found on \(pageUrl)")
            
            var detectedTrackers = [DetectedTracker]()
            resources.forEach { resource in
                if let url = resource["url"],
                    let resourceUrl = URL(withResource: url, relativeTo: pageUrl),
                    let detectedTracker = trackerDetection.detectTrackerFor(resourceUrl: resourceUrl,
                                                                    onPageWithUrl: pageUrl,
                                                                    asResourceType: resource["type"]) {
                    detectedTrackers.append(detectedTracker)
                }
            }
            
            NSLog("\(detectedTrackers.count) detected trackers")
            
            guard !detectedTrackers.isEmpty else { return }
            Data.shared.trackers(detectedTrackers, loadedOnPage: page)
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
        
        NSLog("Setting toolbar to \(grade)")
        toolbarItem.setImage(grading.image)
    }
    
    private func updateRetentionData() {
        let bundle = Bundle(for: type(of: self))
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: bundle.bundleIdentifier!) { state, _ in
            if state?.isEnabled ?? false {
                StatisticsLoader().refreshAppRetentionAtb(atLocation: "seh", completion: nil)
            }
        }
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
