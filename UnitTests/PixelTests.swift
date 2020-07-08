//
//  PixelTests.swift
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
@testable import Statistics
@testable import Core

class PixelTests: XCTestCase {
    
    let store = MockStatisticsStore()
    var appVersion = MockAppVersion()
    let apiRequest = MockAPIRequest()
    
    override func setUp() {
        store.installAtb = "v173-2"
        appVersion.versionNumber = "1.2"
        appVersion.buildNumber = "3"
    }

    func testWhenPixelSentPathIsCorrectAndContainsProduct() {
        
        let expectation = XCTestExpectation()
        apiRequest.addResponse(200)
        
        let pixel = DefaultPixel(statisticsStore: store, appVersion: appVersion, apiRequest: { self.apiRequest })
        pixel.fire(.onboardingGetStartedShown) { _ in
            XCTAssertEqual("/t/eon_gs_s_safari", self.apiRequest.requests.first?.path)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWhenPixelIsNotFiredWithAdditionalParametersThenDefaultParamsAdded() {
        
        let expectation = XCTestExpectation()
        apiRequest.addResponse(200)

        let pixel = DefaultPixel(statisticsStore: store, appVersion: appVersion, apiRequest: { self.apiRequest })
        let expectedParams = ["atb": "v173-2",
                              "extensionVersion": "1.2.3",
                              "test": "1"] // test=1 will be added to debug builds - which tests run under
        
        pixel.fire(.onboardingGetStartedShown) { _ in
            XCTAssertEqual(expectedParams, self.apiRequest.requests.first?.params)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWhenPixelIsFiredWithAdditionalParametersThenDefaultAndAdditionalParametersAdded() {
        
        let expectation = XCTestExpectation()
        apiRequest.addResponse(200)
        
        let pixel = DefaultPixel(statisticsStore: store, appVersion: appVersion, apiRequest: { self.apiRequest })
        let additionalParams = ["param1": "value1", "param2": "value2"]
        
        // test=1 will be added to debug builds - which tests run under
        let expectedParams = ["atb": "v173-2",
                              "extensionVersion": "1.2.3",
                              "param1": "value1",
                              "param2": "value2",
                              "test": "1"]

        pixel.fire(.onboardingGetStartedShown, withParams: additionalParams) { _ in
            XCTAssertEqual(expectedParams, self.apiRequest.requests.first?.params)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWhenPixelFiresSuccessfullyThenCompletesWithNoError() {
        
        let expectation = XCTestExpectation()
        apiRequest.addResponse(200)
        
        let pixel = DefaultPixel(statisticsStore: store, appVersion: appVersion, apiRequest: { self.apiRequest })
        pixel.fire(.onboardingGetStartedShown) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWhenPixelFiresUnsuccessfullyThenCompletesWithError() {
        
        let expectation = XCTestExpectation()
        apiRequest.addResponse(404, error: MockError())
        
        let pixel = DefaultPixel(statisticsStore: store, appVersion: appVersion, apiRequest: { self.apiRequest })
        pixel.fire(.onboardingGetStartedShown) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
