//
//  DashboardData.swift
//  SafariAppExtension
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

import TrackerBlocking
import SafariServices
import os

class DashboardData {

    class Trackers {
        private(set) var loaded = [DetectedTracker]()
        private(set) var blocked = [DetectedTracker]()

        var trackersDetected: Bool {
            return !loaded.isEmpty || !blocked.isEmpty
        }
            
        func append(loadedTrackers: [DetectedTracker]) {
            loaded.append(contentsOf: loadedTrackers)
        }
        
        func append(blockedTrackers: [DetectedTracker]) {
            blocked.append(contentsOf: blockedTrackers)
        }

    }
    
    struct CacheKey: Hashable {
        
        let page: SFSafariPage
        let url: String
    
        func hash(into hasher: inout Hasher) {
            hasher.combine(page)
            hasher.combine(url)
        }
        
    }

    static let shared = DashboardData()
    
    private(set) var pageData: PageData = PageData()
    private(set) var currentPage: SFSafariPage?
    
    private var trackersCache = [CacheKey: Trackers]()
        
    init() {
        os_log("DashboardData init", log: lifecycleLog)
    }
    
    deinit {
        os_log("DashboardData deinit", log: lifecycleLog)
    }
    
    func cachedTrackers(forPage page: SFSafariPage, withUrl url: String) -> Trackers {
        let key = createKey(forPage: page, withUrl: url)
        
        if let cached = trackersCache[key] {
            os_log("Trackers found in cache for page %d %s %d/%d", log: generalLog, type: .default,
                   page.hash, url, cached.blocked.count, cached.loaded.count)
            return cached
        }
        os_log("No trackers found in cache for page %d %s", log: generalLog, type: .default, page.hash, url)
        let trackers = Trackers()
        trackersCache[key] = trackers
        return trackers
    }
            
    func trackers(_ trackers: [DetectedTracker], loadedOnPage page: SFSafariPage, forUrl url: String) {
        DiagnosticSupport.dump(trackers, blocked: false)
        
        let pageTrackers = cachedTrackers(forPage: page, withUrl: url)
        pageTrackers.append(loadedTrackers: trackers)
        
        if page == currentPage {
            refreshDashboard()
        }
    }
    
    func trackers(_ trackers: [DetectedTracker], blockedOnPage page: SFSafariPage, forUrl url: String) {
        DiagnosticSupport.dump(trackers, blocked: true)
        
        trackers.forEach {
            os_log("BLOCKED %{public}s on %s", log: generalLog, type: .default, $0.resource.absoluteString, $0.page.absoluteString)
        }
                    
        let pageTrackers = cachedTrackers(forPage: page, withUrl: url)
        pageTrackers.append(blockedTrackers: trackers)

        if page == currentPage {
            refreshDashboard()
        }
    }
    
    func setCurrentPage(to page: SFSafariPage?, withUrl url: URL?) {
        os_log("Page set with url %s", log: generalLog, type: .default, url?.absoluteString ?? "nil")
        pageData = PageData(url: url)
        
        guard let page = page, let url = url else {
            DispatchQueue.main.async { SafariExtensionViewController.shared.dismiss(self) }
            return
        }
        currentPage = page
        
        let trackers = cachedTrackers(forPage: page, withUrl: url.absoluteString)
        pageData.loadedTrackers = trackers.loaded
        pageData.blockedTrackers = trackers.blocked
        refreshDashboard()
    }
    
    func clearCache(forPage page: SFSafariPage, withUrl url: String) {
        os_log("Clearing cache for page %d %s", log: generalLog, type: .default, page.hash, url)
        trackersCache[createKey(forPage: page, withUrl: url)] = nil
    }
    
    func clear(_ page: SFSafariPage) {
        if page == currentPage {
            currentPage = nil
        }
    }

    func evictInactivePages() {
        DispatchQueue.dashboard.async {
            self.trackersCache.forEach { entry in
                entry.key.page.getPropertiesOnQueue { properties in
                    guard !(properties?.isActive ?? false) else { return }
                    self.trackersCache = self.trackersCache.filter { $0.key.page != entry.key.page }
                }
            }
        }
    }
    
    private func refreshDashboard() {
        DispatchQueue.dashboard.async {
            let pageData = self.pageData
            DispatchQueue.main.async {
                SafariExtensionViewController.shared.pageData = pageData
            }
        }
    }
    
    private func createKey(forPage page: SFSafariPage, withUrl url: String) -> CacheKey {
        let noQueryString = url.components(separatedBy: "?")[0]
        return CacheKey(page: page, url: noQueryString)
    }
}
