//
//  BrokenSiteReporter.swift
//  TrackerBlocking
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

import Foundation
import Statistics
import Core

public class BrokenSiteReporter {

    private let statisticsStore: StatisticsStore.Factory
    private let trackerDataServiceStore: TrackerDataServiceStore
    private let apiRequest: APIRequest.Factory
    private let appVersion: AppVersion
    
    public init(statisticsStore: @escaping StatisticsStore.Factory = { Statistics.Dependencies.shared.statisticsStore },
                trackerDataServiceStore: TrackerDataServiceStore = TrackerDataServiceUserDefaults(),
                apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest(baseUrl: .improving) },
                appVersion: AppVersion = DefaultAppVersion()) {
        self.statisticsStore = statisticsStore
        self.trackerDataServiceStore = trackerDataServiceStore
        self.apiRequest = apiRequest
        self.appVersion = appVersion
    }
    
    /// Reports can be viewed on kibana (ddg internal only) at
    /// https://kibana.duckduckgo.com/goto/d85e0b877f5d2a2ddf59d7cf598328e4
    public func reportBreakageOn(url: URL, withBlockedTrackers blockedTrackers: [DetectedTracker], inCategory category: String) {
            
        let blockedTrackersParam = blockedTrackers.compactMap { $0.resource.host }.joined(separator: ",")
        
        let params = [
            "category": category,
            "siteUrl": url.absoluteString,
            "upgradedHttps": "false",
            "tds": trackerDataServiceStore.etag ?? "",
            "blockedTrackers": blockedTrackersParam,
            "surrogates": "", // blank, we don't use them
            "extensionVersion": appVersion.versionNumber,
            "atb": statisticsStore().installAtb ?? ""
        ]
        
        apiRequest().get("/t/epbf_safari", withParams: params) { _, _, _ in }
    }
    
}
