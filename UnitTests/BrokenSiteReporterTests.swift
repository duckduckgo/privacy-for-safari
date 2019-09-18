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
@testable import TrackerBlocking
@testable import SafariAppExtension

class BrokenSiteReporterTests: XCTestCase {

    func test() {
        let url = URL(string: "http://www.example.com")!
        let trackers = [ tracker("google.com/gtm.js"), tracker("facebook.com/sneaky.png") ]
        
        let apiRequest = MockAPIRequest()
        let statisticsStore = MockStatisticsStore()
        statisticsStore.installAtb = "v66-1"
        
        let trackerDataServiceStore = MockTrackerDataServiceStore(etag: "etag666")
    
        let appVersion = AppVersion(bundle: self)
        
        let reporter = BrokenSiteReporter(statisticsStore: { statisticsStore },
                                          trackerDataServiceStore: trackerDataServiceStore,
                                          apiRequest: { apiRequest },
                                          appVersion: appVersion)
        
        reporter.reportBreakageOn(url: url, withBlockedTrackers: trackers, inCategory: "Other")
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual("/t/epbf_safari", apiRequest.requests[0].path)
        XCTAssertEqual([
            "category": "Other",
            "upgradedHttps": "false",
            "siteUrl": "http://www.example.com",
            "blockedTrackers": "google.com,facebook.com",
            "surrogates": "",
            "extensionVersion": "2.0",
            "atb": "v66-1",
            "tds": "etag666"
        ], apiRequest.requests[0].params)
        
    }
    
    private func tracker(_ path: String) -> DetectedTracker {
        let resource = URL(string: "http://" + path)!
        let page = URL(string: "http://www.example.com")!
        return DetectedTracker(matchedTracker: nil, resource: resource, page: page, owner: nil, prevalence: 0, isFirstParty: false, action: .block)
    }
    
}

extension BrokenSiteReporterTests: InfoBundle {
    
    func object(forInfoDictionaryKey key: String) -> Any? {
        return "2.0"
    }
}
