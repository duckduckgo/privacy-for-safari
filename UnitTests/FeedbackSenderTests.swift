//
//  BrokenSiteReporterTests.swift
//  UnitTests
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

import XCTest
import Core
@testable import Feedback
@testable import TrackerBlocking

class FeedbackSenderTests: XCTestCase {

    func test() {
        
        let apiRequest = MockAPIRequest()
        let statisticsStore = MockStatisticsStore()
        statisticsStore.installAtb = "v66-1"
        
        let trackerDataServiceStore = MockTrackerDataServiceStore(etag: "etag666")
    
        let appVersion = DefaultAppVersion(bundle: self)
        
        let sender = FeedbackSender(statisticsStore: { statisticsStore },
                                          trackerDataServiceStore: trackerDataServiceStore,
                                          apiRequest: { apiRequest },
                                          appVersion: appVersion,
                                          browserVersionProvider: self)
        
        let comment = "This app is awesome!"
        
        sender.send(feedback: comment)
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual("/feedback.js", apiRequest.requests[0].path)
        XCTAssertEqual(apiRequest.requests[0].method, .post)
        XCTAssertEqual([
            "reason": "general",
            "url": "", // not needed
            "comment": comment,
            "browser": "Safari",
            "browser_version": "99",
            "v": "2.0",
            "atb": "v66-1",
            "tds": "etag666",
            "type": "extension-feedback"
        ], apiRequest.requests[0].params)
        
    }
    
    private func tracker(_ path: String) -> DetectedTracker {
        let resource = URL(string: "http://" + path)!
        let page = URL(string: "http://www.example.com")!
        return DetectedTracker(matchedTracker: nil, resource: resource, page: page, owner: nil, prevalence: 0, isFirstParty: false, action: .block)
    }
    
}

extension FeedbackSenderTests: InfoBundle {
    
    func object(forInfoDictionaryKey key: String) -> Any? {
        return "2.0"
    }
}

extension FeedbackSenderTests: BrowserVersionProvider {
    
    func browserVersion() -> String {
        return "99"
    }
    
}
