//
//  SyncRunnerTests.swift
//  DuckDuckGoSyncTests
//
//  Created by duckduckgo on 16/09/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

import XCTest
@testable import DuckDuckGoSync
@testable import TrackerBlocking

class SyncRunnerTests: XCTestCase {
    
    func testWhenServiceReturnsSuccessWithNewDataThenCompletionSucceeds() {
        let expect = expectation(description: "When service succeeds, response in completion is true")
        let testee = SyncRunner(trackerDataService: MockTrackerDataService(success: true, newData: true))
        
        testee.sync { success  in
            XCTAssertTrue(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testWhenServiceReturnsSuccessWithoutNewDataThenCompletionSucceeds() {
        let expect = expectation(description: "When service succeeds, response in completion is true")
        let testee = SyncRunner(trackerDataService: MockTrackerDataService(success: true, newData: false))
        
        testee.sync { success  in
            XCTAssertTrue(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testWhenReturnsFailureWithoutNewDataThenCompletionFails() {
        let expect = expectation(description: "When service fails, response in completion is false")
        let testee = SyncRunner(trackerDataService: MockTrackerDataService(success: false, newData: false))
        testee.sync { success  in
            XCTAssertFalse(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testWhenServiceReturnsFailureWithNewDataThenCompletionFails() {
        let expect = expectation(description: "When service fails, response in completion is false")
        let testee = SyncRunner(trackerDataService: MockTrackerDataService(success: false, newData: true))
        testee.sync { success  in
            XCTAssertFalse(success)
            expect.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    class MockTrackerDataService: TrackerDataService {
        
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
