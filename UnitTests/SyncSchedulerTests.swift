//
//  SyncSchedulerTests.swift
//  UnitTests
//
//  Created by Chris Brind on 26/11/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import XCTest
@testable import SyncSupport

class SyncSchedulerTests: XCTestCase {
    
    func testWhenLastSyncIsZeroThenTimeToSyncIsTrue() {
        XCTAssertTrue(SyncScheduler.isTimeToSync(lastSyncDateTime: 0))
    }

    func testWhenLastSyncLessThanDefaultThenTimeToSyncIsTrue() {
        let date = Date()
        let lastSync = date.timeIntervalSince1970 - SyncScheduler.SyncInterval.default - 1
        XCTAssertTrue(SyncScheduler.isTimeToSync(currentDate: date, lastSyncDateTime: lastSync))
    }

    func testWhenDifferenceInLastSyncGreaterThanDefaultThenTimeToSyncIsTrue() {
        let date = Date()
        let lastSync = date.timeIntervalSince1970 - SyncScheduler.SyncInterval.default + 1
        XCTAssertFalse(SyncScheduler.isTimeToSync(currentDate: date, lastSyncDateTime: lastSync))
    }

}
