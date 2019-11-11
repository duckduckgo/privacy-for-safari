//
//  SyncUserDefaultsTests.swift
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
@testable import HelperSupport

class SyncUserDefaultsTests: XCTestCase {
    
    let testGroupName = "test"
    
    override func setUp() {
        UserDefaults(suiteName: testGroupName)?.removePersistentDomain(forName: testGroupName)
    }
    
    func testLastWhenInitializedThenSyncTimestampIsZero() {
        let userDefaults = SyncUserDefaults(userDefaults: UserDefaults(suiteName: testGroupName)!)
        XCTAssertEqual(0.0, userDefaults.lastSyncTimestamp)
    }
    
    func testWhenLastSyncTimestampIsSetThenItIsPersisted() {
        let userDefaults = SyncUserDefaults(userDefaults: UserDefaults(suiteName: testGroupName)!)
        userDefaults.lastSyncTimestamp = 1.0
        XCTAssertEqual(1.0, userDefaults.lastSyncTimestamp)
    }
}
