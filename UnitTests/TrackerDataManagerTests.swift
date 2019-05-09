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

    func testEntityForUrl() {

        let manager = DefaultTrackerDataManager()
        manager.entities = ["google.com": Entity(name: "Google", properties: [], prevalence: 0.0) ]

        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://www.google.com")!))
        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://google.com")!))
        XCTAssertNotNil(manager.entity(forUrl: URL(string: "https://hello.world.google.com")!))

        XCTAssertNil(manager.entity(forUrl: URL(string: "https://www.example.com")!))
        XCTAssertNil(manager.entity(forUrl: URL(string: "https://example.com")!))
        XCTAssertNil(manager.entity(forUrl: URL(string: "https://notgoogle.com")!))

    }

}
