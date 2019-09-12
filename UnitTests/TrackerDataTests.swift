//
//  TrackerDataTests.swift
//  UnitTests
//
//  Created by Chris Brind on 20/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import XCTest
@testable import TrackerBlocking

class TrackerDataTests: XCTestCase {

    func testLoadData() {
        let url = Bundle(for: TrackerDataTests.self).url(forResource: "sample-tracker-data", withExtension: "json")!
        let trackerData = TrackerData.decode(contentsOf: url)
        XCTAssertNotNil(trackerData)
        XCTAssertEqual(2, trackerData?.trackers.count)
        XCTAssertEqual(1, trackerData?.entities.count)
        XCTAssertEqual(3, trackerData?.domains.count)        
    }
    
    func testLoadBundledData() {
        let trackerDataManager = DefaultTrackerDataManager()
        XCTAssertEqual(419, trackerDataManager.trackerData?.trackers.count)
        XCTAssertEqual(315, trackerDataManager.trackerData?.entities.count)
        XCTAssertEqual(1852, trackerDataManager.trackerData?.domains.count)
    }
    
}
