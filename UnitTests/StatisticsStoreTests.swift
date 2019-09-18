//
//  StatisticsStoreTests.swift
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

@testable import Core
@testable import Statistics

class StatisticsStoreTests: XCTestCase {
    
    let userDefaults = UserDefaults(suiteName: "test")
    
    override func setUp() {
        super.setUp()
        userDefaults?.removePersistentDomain(forName: "test")
    }
    
    func testWhenNewStoreIsEmpty() {
        
        let store = DefaultStatisticsStore(userDefaults: userDefaults)
        XCTAssertNil(store.installAtb)
        XCTAssertNil(store.appRetentionAtb)
        XCTAssertNil(store.searchRetentionAtb)
        XCTAssertNil(store.installDate)

    }
    
    func testWhenNewInstanceOfStoreCreatedThenValuesAreReflected() {
        
        var store = DefaultStatisticsStore(userDefaults: userDefaults)
        store.installAtb = "installAtb"
        store.appRetentionAtb = "appRetentionAtb"
        store.searchRetentionAtb = "searchRetentionAtb"
        store.installDate = Date(timeIntervalSince1970: 5.0)
        
        XCTAssertEqual("installAtb", store.installAtb)
        XCTAssertEqual("appRetentionAtb", store.appRetentionAtb)
        XCTAssertEqual("searchRetentionAtb", store.searchRetentionAtb)
        XCTAssertEqual(Date(timeIntervalSince1970: 5.0), store.installDate)

        store = DefaultStatisticsStore(userDefaults: userDefaults)
        XCTAssertEqual("installAtb", store.installAtb)
        XCTAssertEqual("appRetentionAtb", store.appRetentionAtb)
        XCTAssertEqual("searchRetentionAtb", store.searchRetentionAtb)
        XCTAssertEqual(Date(timeIntervalSince1970: 5.0), store.installDate)

    }
    
}
