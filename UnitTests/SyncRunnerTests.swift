//
//  SyncRunnerTests.swift
//  UnitTests
//
//  Created by duckduckgo on 16/09/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

import XCTest
@testable import TrackerBlocking

class SyncRunnerTests: XCTestCase {
    
    func testWhenServiceReturnsSuccessWithNewDataThenCompletionSucceeds() {
        let expect = expectation(description: "When service succeeds, response in completion is true")
        let testee = SyncRunner(trackerDataService: MockDataService(success: true, newData: true),
                                tempUnprotectedSitesDataService: MockDataService(success: true, newData: true),
                                trackerDataManager: MockTrackerDataManager(),
                                blockerListManager: MockBlockerListManager())
        
        testee.sync { success  in
            XCTAssertTrue(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testWhenServiceReturnsSuccessWithoutNewDataThenCompletionSucceeds() {
        let expect = expectation(description: "When service succeeds, response in completion is true")
        let testee = SyncRunner(trackerDataService: MockDataService(success: true, newData: false),
                                tempUnprotectedSitesDataService: MockDataService(success: true, newData: true),
                                trackerDataManager: MockTrackerDataManager(),
                                blockerListManager: MockBlockerListManager())
        
        testee.sync { success  in
            XCTAssertTrue(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testWhenReturnsFailureWithoutNewDataThenCompletionFails() {
        let expect = expectation(description: "When service fails, response in completion is false")
        let testee = SyncRunner(trackerDataService: MockDataService(success: false, newData: false),
                                tempUnprotectedSitesDataService: MockDataService(success: true, newData: true),
                                trackerDataManager: MockTrackerDataManager(),
                                blockerListManager: MockBlockerListManager())
        testee.sync { success  in
            XCTAssertFalse(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testWhenServiceReturnsFailureWithNewDataThenCompletionFails() {
        let expect = expectation(description: "When service fails, response in completion is false")
        let testee = SyncRunner(trackerDataService: MockDataService(success: false, newData: true),
                                tempUnprotectedSitesDataService: MockDataService(success: true, newData: true),
                                trackerDataManager: MockTrackerDataManager(),
                                blockerListManager: MockBlockerListManager())
        testee.sync { success  in
            XCTAssertFalse(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    class MockDataService: TrackerDataService, TempUnprotectedSitesDataService {
        
        let success: Bool
        let newData: Bool
        
        init(success: Bool, newData: Bool) {
            self.success = success
            self.newData = newData
        }
        
        func updateData(completion: @escaping DataCompletion) {
            completion(success, newData)
        }
    }
    
}
