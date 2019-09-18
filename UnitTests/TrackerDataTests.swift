//
//  TrackerDataTests.swift
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
