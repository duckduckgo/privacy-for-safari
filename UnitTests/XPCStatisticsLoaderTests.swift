//
//  XPCStatisticsLoaderTests.swift
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
@testable import TrackerBlocking

class XPCStatisticsLoaderTests: XCTestCase {

    func testWhenRefreshSearchCalledThenRefreshSearchIsCalledOnSuppliedLoader() {
        let mockLoader = MockStatisticsLoader()
        let loader = XPCStatisticsLoader(loader: mockLoader)

        let search = expectation(description: "search")

        loader.refreshSearchRetentionAtb(atLocation: "search") {
            search.fulfill()
        }

        wait(for: [search], timeout: 5.0)

        XCTAssertTrue(mockLoader.refreshSearchRetentionAtbFired)
    }

    func testWhenRefreshAppCalledThenRefreshAppIsCalledOnSuppliedLoader() {
        let mockLoader = MockStatisticsLoader()
        let loader = XPCStatisticsLoader(loader: mockLoader)

        let app = expectation(description: "app")

        loader.refreshAppRetentionAtb(atLocation: "app") {
            app.fulfill()
        }

        wait(for: [app], timeout: 5.0)

        XCTAssertTrue(mockLoader.refreshAppRetentionAtbFired)
    }

}
