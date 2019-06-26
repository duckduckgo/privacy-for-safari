//
//  StatisticsLoaderTests.swift
//  UnitTests
//
//  Created by Chris Brind on 12/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import XCTest

@testable import Core
@testable import Statistics

class StatisticsLoaderTests: XCTestCase {
    
    func testWhenAtbNeedsUpdatingThenAppAtbIsRefreshed() {
        
        let store = MockStatisticsStore()
        store.installAtb = "v173-2"
        store.installDate = Date()
        store.appRetentionAtb = "v173-5"
        Dependencies.shared = MockStatisticsDependencies(statisticsStore: store)
        
        let apiRequest = MockAPIRequest()
        apiRequest.addResponse(200, body: "{ \"version\": \"v174-1\" }")
        
        let loader = DefaultStatisticsLoader(apiRequest: apiRequest)
        loader.refreshAppRetentionAtb(atLocation: "test") { }
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual(apiRequest.requests[0].path, DefaultStatisticsLoader.Paths.atb)
        XCTAssertEqual(apiRequest.requests[0].params ?? [:], [
            "at": "app_use",
            "atb": "v173-2",
            "set_atb": "v173-5",
            "l": "test"
            ])
        
        XCTAssertEqual("v174-1", store.appRetentionAtb)
        XCTAssertNil(store.searchRetentionAtb)
    }
    
    func testWhenAtbNeedsUpdatingThenSearchAtbIsRefreshed() {
        
        let store = MockStatisticsStore()
        store.installAtb = "v173-2"
        store.installDate = Date()
        store.searchRetentionAtb = "v173-5"
        Dependencies.shared = MockStatisticsDependencies(statisticsStore: store)
        
        let apiRequest = MockAPIRequest()
        apiRequest.addResponse(200, body: "{ \"version\": \"v174-1\" }")
        
        let loader = DefaultStatisticsLoader(apiRequest: apiRequest)
        loader.refreshSearchRetentionAtb(atLocation: "test", completion: nil)
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual(apiRequest.requests[0].path, DefaultStatisticsLoader.Paths.atb)
        XCTAssertEqual(apiRequest.requests[0].params ?? [:], [
            "at": "search",
            "atb": "v173-2",
            "set_atb": "v173-5",
            "l": "test"
            ])
        
        XCTAssertEqual("v174-1", store.searchRetentionAtb)
        XCTAssertNil(store.appRetentionAtb)
        
    }
    
    func testWhenAtbIsInstalledThenAppAtbIsRefreshed() {

        let store = MockStatisticsStore()
        store.installAtb = "v173-2"
        store.installDate = Date()
        Dependencies.shared = MockStatisticsDependencies(statisticsStore: store)
        
        let apiRequest = MockAPIRequest()
        apiRequest.addResponse(200, body: "{ \"version\": \"v174-1\" }")

        let loader = DefaultStatisticsLoader(apiRequest: apiRequest)
        loader.refreshAppRetentionAtb(atLocation: "test") { }
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual(apiRequest.requests[0].path, DefaultStatisticsLoader.Paths.atb)
        XCTAssertEqual(apiRequest.requests[0].params ?? [:], [
            "at": "app_use",
            "atb": "v173-2"
            ])

        XCTAssertEqual("v174-1", store.appRetentionAtb)
        XCTAssertNil(store.searchRetentionAtb)
    }

    func testWhenAtbIsInstalledThenSearchAtbIsRefreshed() {
        
        let store = MockStatisticsStore()
        store.installAtb = "v173-2"
        store.installDate = Date()
        Dependencies.shared = MockStatisticsDependencies(statisticsStore: store)
        
        let apiRequest = MockAPIRequest()
        apiRequest.addResponse(200, body: "{ \"version\": \"v174-1\" }")
        
        let loader = DefaultStatisticsLoader(apiRequest: apiRequest)
        loader.refreshSearchRetentionAtb(atLocation: "test", completion: nil)
        
        XCTAssertEqual(1, apiRequest.requests.count)
        XCTAssertEqual(apiRequest.requests[0].path, DefaultStatisticsLoader.Paths.atb)
        XCTAssertEqual(apiRequest.requests[0].params ?? [:], [
            "at": "search",
            "atb": "v173-2"
            ])
        
        XCTAssertEqual("v174-1", store.searchRetentionAtb)
        XCTAssertNil(store.appRetentionAtb)

    }

    func testWhenNoAtbThenAtbIsInstalled() {
        let store = MockStatisticsStore()
        Dependencies.shared = MockStatisticsDependencies(statisticsStore: store)

        let apiRequest = MockAPIRequest()
        apiRequest.addResponse(200, body: "{ \"version\": \"v173-1\" }")
        apiRequest.addResponse(200)
        
        let loader = DefaultStatisticsLoader(apiRequest: apiRequest)
        loader.refreshAppRetentionAtb(atLocation: "test") { }

        XCTAssertEqual(2, apiRequest.requests.count)

        XCTAssertEqual(apiRequest.requests[0].path, DefaultStatisticsLoader.Paths.atb)
        XCTAssertNil(apiRequest.requests[0].params)
        
        XCTAssertEqual(apiRequest.requests[1].path, DefaultStatisticsLoader.Paths.exti)
        XCTAssertEqual(apiRequest.requests[1].params, ["atb": "v173-1", "l": "test"])
        
        XCTAssertEqual("v173-1", store.installAtb)
        XCTAssertNotNil(store.installDate)
    }
    
}
