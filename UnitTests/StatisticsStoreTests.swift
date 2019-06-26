//
//  StatisticsStoreTests.swift
//  UnitTests
//
//  Created by Chris Brind on 13/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
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
