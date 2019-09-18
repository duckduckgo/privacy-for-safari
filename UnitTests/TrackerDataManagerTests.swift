//
//  TrackerDataManagerTests.swift
//  UnitTests
//
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
@testable import TrackerBlocking

class TrackerDataManagerTests: XCTestCase {

    func testWhenUrlDomainMatchesEntityThenItIsReturned() {

        let trackerData = TrackerData(trackers: [:],
                                      entities: ["google.com": Entity(displayName: "Google", domains: [], prevalence: 0.0) ],
                                      domains: [:])
        let manager = DefaultTrackerDataManager()
        manager.trackerData = trackerData

        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://www.google.com")!))
        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://google.com")!))
        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://hello.world.google.com")!))

        XCTAssertNil(manager.entity(forUrl: URL(string: "https://www.example.com")!))
        XCTAssertNil(manager.entity(forUrl: URL(string: "https://example.com")!))
        XCTAssertNil(manager.entity(forUrl: URL(string: "https://notgoogle.com")!))

    }

    func testWhenUrlDomainMatchesKnownTrackerThenItIsReturned() {

        let facebookTracker = KnownTracker(domain: "facebook.com", defaultAction: .block, owner: nil, prevalence: 1.0, subdomains: nil, rules: nil)
        let trackerData = TrackerData(trackers: ["facebook.com": facebookTracker],
                                      entities: [:],
                                      domains: [:])
        let manager = DefaultTrackerDataManager()
        manager.trackerData = trackerData

        XCTAssertNotNil(manager.knownTracker(forUrl: URL(string: "https://facebook.com/tracker.js")!))
        XCTAssertNotNil(manager.knownTracker(forUrl: URL(string: "https://sub.facebook.com/tracker.js")!))
        XCTAssertNil(manager.knownTracker(forUrl: URL(string: "https://notfacebook.com/tracker.js")!))
    }

}
