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

actor DashboardData {

    class CachedData {

        private(set) var loadedTrackers = Set<DetectedTracker>()
        private(set) var blockedTrackers = Set<DetectedTracker>()
        private(set) var requests = Set<PageData.DetectedRequest>()

        var trackersDetected: Bool {
            return !loadedTrackers.isEmpty || !blockedTrackers.isEmpty
        }
            
        func append(loadedTrackers: Set<DetectedTracker>) {
            self.loadedTrackers = self.loadedTrackers.union(loadedTrackers)
        }
        
        func append(blockedTrackers: Set<DetectedTracker>) {
            self.blockedTrackers = self.blockedTrackers.union(blockedTrackers)
        }

        func append(requests: Set<PageData.DetectedRequest>) {
            self.requests = self.requests.union(requests)
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
    
    private var cache = [CacheKey: CachedData]()
        
    init() {
        os_log("DashboardData init", log: lifecycleLog, type: .debug)
    }
    
    deinit {
        os_log("DashboardData deinit", log: lifecycleLog, type: .debug)
    }

    func hasResourceBeenSeenBefore(_ resourceURL: URL, onPage page: SFSafariPage, withUrl url: URL) -> Bool {
        let data = cache(forPage: page, withUrl: url.absoluteString)
        return data.loadedTrackers.contains(where: {
            $0.resource == resourceURL
        })
    }

    func pageForDomain(_ domain: String) -> SFSafariPage? {
        return cache.keys.first(where: { URL(string: $0.url)?.host == domain })?.page
    }
    
    func cache(forPage page: SFSafariPage, withUrl url: String) -> CachedData {
        let key = createKey(forPage: page, withUrl: url)
        
        if let cached = cache[key] {
            os_log("Trackers found in cache for page %d %s %d/%d", log: generalLog, type: .default,
                   page.hash, url, cached.blockedTrackers.count, cached.loadedTrackers.count)
            return cached
        }
        os_log("No trackers found in cache for page %d %s", log: generalLog, type: .default, page.hash, url)
        let data = CachedData()
        cache[key] = data
        return data
    }

    func blockedTrackers(_ trackers: Set<DetectedTracker>, onPage page: SFSafariPage, forUrl url: String) {
        #if DEBUG
        DiagnosticSupport.dump(trackers, blocked: true)
        #endif

        let cache = cache(forPage: page, withUrl: url)
        cache.append(blockedTrackers: trackers)

        if page == currentPage {
            refreshDashboard()
        }
    }

    func loadedTrackers(_ trackers: Set<DetectedTracker>,
                        andRequests requests: Set<PageData.DetectedRequest>,
                        onPage page: SFSafariPage, forUrl url: String) {
        #if DEBUG
        DiagnosticSupport.dump(trackers, blocked: false)
        #endif

        os_log("SEH loadedTrackers %{public}s", log: generalLog, type: .debug, "\(requests)")

        let cache = cache(forPage: page, withUrl: url)
        cache.append(loadedTrackers: trackers)
        cache.append(requests: requests)

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
        
        let cache = cache(forPage: page, withUrl: url.absoluteString)
        pageData.loadedTrackers = cache.loadedTrackers
        pageData.blockedTrackers = cache.blockedTrackers
        pageData.otherRequests = cache.requests
        refreshDashboard()
    }
    
    func clearCache(forPage page: SFSafariPage, withUrl url: String) {
        os_log("Clearing cache for page %d %s", log: generalLog, type: .default, page.hash, url)
        cache[createKey(forPage: page, withUrl: url)] = nil
    }

    func evictInactivePages() async {
        for entry in self.cache {
            let properties = await entry.key.page.properties()
            guard !(properties?.isActive ?? false) else { return }
            self.cache = self.cache.filter { $0.key.page != entry.key.page }
        }
    }
    
    private func refreshDashboard() {
        let pageData = self.pageData
        Task { @MainActor in
            SafariExtensionViewController.shared.pageData = pageData
        }
    }
    
    private func createKey(forPage page: SFSafariPage, withUrl url: String) -> CacheKey {
        let noQueryString = url.components(separatedBy: "?")[0]
        return CacheKey(page: page, url: noQueryString)
    }
}
