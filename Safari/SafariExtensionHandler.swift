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

    enum Messages: String {
        case resourceLoaded
    }
    
    struct Trackers {
        var loaded = [DetectedTracker]()
        var blocked = [DetectedTracker]()
    }

    struct Data {

        static var currentPage = PageData()
        static var trackersPerPage = [SFSafariPage: Trackers]()
        
    }
    
    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)
        updateRetentionData()
    }
    
    override func contentBlocker(withIdentifier contentBlockerIdentifier: String, blockedResourcesWith urls: [URL], on page: SFSafariPage) {
        page.getPropertiesWithCompletionHandler { properties in
            guard let pageUrl = properties?.url else { return }
            
            var resources = Data.trackersPerPage[page, default: Trackers()]
            let trackerDetection = Dependencies.shared.trackerDetection
            resources.blocked += urls.map { trackerDetection.detectedTrackerFrom(resourceUrl: $0, onPageWithUrl: pageUrl) }
            Data.trackersPerPage[page] = resources
        }
    
    }
    
    override func page(_ page: SFSafariPage, willNavigateTo url: URL?) {
        Data.trackersPerPage.removeValue(forKey: page)
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
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getToolbarItem { toolbarItem in
            toolbarItem?.showPopover()
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")

        Data.currentPage = PageData()

        window.getToolbarItem { toolbarItem in
            toolbarItem?.setImage(NSImage(named: NSImage.Name("LogoToolbarItemIcon")))
        }

        window.getActiveTab { tabs in
            tabs?.getActivePage(completionHandler: { page in
                guard let page = page else { return }                
                page.getPropertiesWithCompletionHandler({ properties in
                    Data.currentPage = PageData(url: properties?.url)
                    self.updateToolbar(forPage: page)
                })
            })
        }

    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        SafariExtensionViewController.shared.pageData = Data.currentPage
        SafariExtensionViewController.shared.viewWillAppear()
    }

    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        
        guard let resource = userInfo?["resource"] as? String else {
            return
        }
        
        page.getPropertiesWithCompletionHandler { properties in
            let trackerDetection = Dependencies.shared.trackerDetection
            guard let pageUrl = properties?.url,
                let resourceUrl = URL(withResource: resource, relativeTo: pageUrl),
                let tracker = trackerDetection.detectTrackerFor(resourceUrl: resourceUrl, onPageWithUrl: pageUrl),
                !tracker.isFirstParty else {
                    return
            }

            var trackers = Data.trackersPerPage[page, default: Trackers()]
            trackers.loaded += [ tracker ]
            Data.trackersPerPage[page] = trackers
            
            self.updateToolbar(forPage: page)
        }

    }

    private func updateToolbar(forPage page: SFSafariPage) {
        page.getContainingTab { tab in
            tab.getContainingWindow(completionHandler: { window in
                window?.getToolbarItem { toolbarItem in
                    guard let toolbarItem = toolbarItem else { return }
                    self.update(toolbarItem, forPage: page)
                }
            })
        }
    }
    
    private func update(_ toolbarItem: SFSafariToolbarItem, forPage page: SFSafariPage) {
        guard let url = Data.currentPage.url else {
            toolbarItem.setImage(NSImage(named: NSImage.Name("LogoToolbarItemIcon")))
            return
        }
        
        if let count = Data.trackersPerPage[page]?.loaded.count {
            toolbarItem.setBadgeText(count > 0 ? "\(count)" : nil)
        }
        
        let trackers = Data.trackersPerPage[page, default: Trackers()]
        Data.currentPage.loadedTrackers = trackers.loaded
        Data.currentPage.blockedTrackers = trackers.blocked
        let grade = Data.currentPage.calculateGrade()
        let site = Dependencies.shared.trustedSitesManager.isTrusted(url: url) ? grade.site : grade.enhanced
        let grading = site.grade
        toolbarItem.setImage(grading.image)
    }
    
    private func updateRetentionData() {
        let bundle = Bundle(for: type(of: self))
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: bundle.bundleIdentifier!) { state, _ in
            if state?.isEnabled ?? false {
                Statistics.Dependencies.shared.statisticsLoader.refreshAppRetentionAtb(atLocation: "seh", completion: nil)
            }
        }
    }
}

extension Grade.Grading {

    static let images: [Grade.Grading: NSImage] = [
        .a: NSImage(named: "ToolbarGradeA")!,
        .bPlus: NSImage(named: "ToolbarGradeBPlus")!,
        .b: NSImage(named: "ToolbarGradeB")!,
        .cPlus: NSImage(named: "ToolbarGradeCPlus")!,
        .c: NSImage(named: "ToolbarGradeC")!,
        .d: NSImage(named: "ToolbarGradeD")!,
        .dMinus: NSImage(named: "ToolbarGradeD")!
    ]

    var image: NSImage? {
        return Grade.Grading.images[self]
    }
    
}
