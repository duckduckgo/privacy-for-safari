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
        static let page = URL(string: "https://example.com")!
        static let resource = URL(string: "https://tracker.com/tracker.js")!
    }

    func testWhenTrackersAreUpdatedThenScoreIsRecalculated() {
        let pageData = PageData()
        let defaultGrade = pageData.calculateGrade()
        
        pageData.blockedTrackers = [DetectedTracker(resource: URLs.resource, page: URLs.page, owner: "None", prevalence: 1.0, isFirstParty: false)]
        let blockedTrackersGrade = pageData.calculateGrade()
        XCTAssertNotEqual(defaultGrade.site.score, blockedTrackersGrade.site.score)

        pageData.loadedTrackers = [DetectedTracker(resource: URLs.resource, page: URLs.page, owner: "None", prevalence: 10.0, isFirstParty: false)]
        let loadedTrackersGrade = pageData.calculateGrade()
        XCTAssertNotEqual(blockedTrackersGrade.site.score, loadedTrackersGrade.site.score)
    }
    
    func testDefaultConstructor() {
        let pageData = PageData()
        XCTAssertNil(pageData.url)
        XCTAssertTrue(pageData.blockedTrackers.isEmpty)
        XCTAssertTrue(pageData.loadedTrackers.isEmpty)
    }

}
