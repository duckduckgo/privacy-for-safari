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
@testable import TrackerRadarKit

class TrackerDataManagerTests: XCTestCase {

    func testCanonicalURL() {
        let trackerData = TrackerData(trackers: [:],
                                      entities: [:],
                                      domains: [:],
                                      cnames: ["cheekycname.website.com": "example.tracker.com"])
        let manager = DefaultTrackerDataManager()
        manager.trackerData = trackerData
        let canonUrl = manager.canonicalURL(forUrl: URL(string: "https://cheekycname.website.com/somescript.js?x=1")!)
        XCTAssertEqual(URL(string: "https://example.tracker.com/somescript.js?x=1"), canonUrl)
    }

    func testWhenUrlDomainMatchesEntityThenItIsReturned() {

        let trackerData = TrackerData(trackers: [:],
                                      entities: ["Google": Entity(displayName: "Google!", domains: [], prevalence: 0.0) ],
                                      domains: ["google.com": "Google"])
        let manager = DefaultTrackerDataManager()
        manager.trackerData = trackerData

        XCTAssertEqual("Google!", manager.entity(forUrl: URL(string: "https://www.google.com")!)?.displayName)
        XCTAssertEqual("Google!", manager.entity(forUrl: URL(string: "https://google.com")!)?.displayName)
        XCTAssertEqual("Google!", manager.entity(forUrl: URL(string: "https://hello.world.google.com")!)?.displayName)

        XCTAssertNil(manager.entity(forUrl: URL(string: "https://www.example.com")!))
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
