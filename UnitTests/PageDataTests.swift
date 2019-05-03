//
//  PageDataTests.swift
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
@testable import TrackerBlocking

class PageDataTests: XCTestCase {

    struct URLs {
        static let example = URL(string: "https://example.com")!
    }

    func testWhenEntitiesUpdatedThenTrackerCountsAreUpdated() {
        var pageData = PageData()
        pageData = pageData.updateEntities(blocked: ["Entity": ["Resource": 1]],
                                           notBlocked: ["Entity": ["Resource": 1]])
        XCTAssertEqual(1, pageData.notBlockedTrackerCount)
        XCTAssertEqual(1, pageData.blockedTrackerCount)

        pageData = pageData.updateEntities(blocked: ["Entity": ["Resource": 1]],
                                           notBlocked: [:])
        XCTAssertEqual(1, pageData.notBlockedTrackerCount)
        XCTAssertEqual(2, pageData.blockedTrackerCount)

        pageData = pageData.updateEntities(blocked: [:],
                                           notBlocked: ["Entity": ["Resource": 1]])
        XCTAssertEqual(2, pageData.notBlockedTrackerCount)
        XCTAssertEqual(2, pageData.blockedTrackerCount)
    }

    func testWhenEntitiesUpdatedThenURLIsRetained() {
        var pageData = PageData(url: URLs.example)
        pageData = pageData.updateEntities(blocked: ["Entity": ["Resource": 1]], notBlocked: [:])
        XCTAssertEqual(pageData.url, pageData.url)

        pageData = pageData.updateEntities(blocked: [:], notBlocked: ["Entity": ["Resource": 1]])
        XCTAssertEqual(pageData.url, pageData.url)
    }

    func testDefaultConstructor() {
        let pageData = PageData()
        XCTAssertNil(pageData.url)
        XCTAssertTrue(pageData.blockedEntities.isEmpty)
        XCTAssertTrue(pageData.notBlockedEntities.isEmpty)
    }

}
