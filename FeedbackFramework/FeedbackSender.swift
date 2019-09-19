//
//  FeedbackSender.swift
//  Feedback
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
import Core
import Statistics
import TrackerBlocking
import SafariServices

public protocol BrowserVersionProvider {
    
    func browserVersion() -> String
    
}

/// Submits feedback to
/// https://duckduckgo.com/feedback.js?type=extension-feedback
public struct FeedbackSender {
    
    private let statisticsStore: StatisticsStore.Factory
    private let trackerDataServiceStore: TrackerDataServiceStore
    private let apiRequest: APIRequest.Factory
    private let appVersion: AppVersion
    private let browserVersionProvider: BrowserVersionProvider
    
    public init(statisticsStore: @escaping StatisticsStore.Factory = { Statistics.Dependencies.shared.statisticsStore },
                trackerDataServiceStore: TrackerDataServiceStore = TrackerDataServiceUserDefaults(),
                apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest(baseUrl: .standard) },
                appVersion: AppVersion = DefaultAppVersion(),
                browserVersionProvider: BrowserVersionProvider = DefaultBrowserVersionProvider()) {
        self.statisticsStore = statisticsStore
        self.trackerDataServiceStore = trackerDataServiceStore
        self.apiRequest = apiRequest
        self.appVersion = appVersion
        self.browserVersionProvider = browserVersionProvider
    }

    /// After submission it ends up here:
    /// https://app.asana.com/0/429812482444398/list
    public func send(feedback: String) {
        
        let params = [
            "reason": "general",
            "url": "", // not needed
            "comment": feedback,
            "browser": "Safari",
            "browser_version": browserVersionProvider.browserVersion(),
            "v": appVersion.versionNumber,
            "atb": statisticsStore().installAtb ?? "",
            "tds": trackerDataServiceStore.etag ?? "",
            "type": "extension-feedback"
        ]
        
        apiRequest().post("/feedback.js", withParams: params) { _, _, _ in }
    }
    
}

public struct DefaultBrowserVersionProvider: BrowserVersionProvider {
    
    public init() { }
    
    // How to determine this accurately?
    public func browserVersion() -> String {
        return Statistics.Dependencies.shared.statisticsStore.browserVersion ?? ""
    }
    
}
