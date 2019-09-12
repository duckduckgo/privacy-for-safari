//
//  TrackerDataManagerTests.swift
//  UnitTests
//
//  Created by Christopher Brind on 09/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
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
