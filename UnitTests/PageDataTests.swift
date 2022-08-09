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
@testable import TrackerRadarKit

class PageDataTests: XCTestCase {

    struct URLs {
        static let page = URL(string: "https://example.com")!
        static let resource = URL(string: "https://tracker.com/tracker.js")!
        static let resource2 = URL(string: "https://tracker2.com/tracker.js")!
        static let resource3 = URL(string: "https://tracker3.com/tracker.js")!
    }

    func testWhenTrackersAreUpdatedThenScoreIsRecalculated() {
        let pageData = PageData(trackerDataManager: MockTrackerDataManager(returnEntities: entities()))
        let defaultGrade = pageData.calculateGrade()
        
        pageData.blockedTrackers = [DetectedTracker(matchedTracker: nil,
                                                    resource: URLs.resource,
                                                    page: URLs.page,
                                                    owner: "None",
                                                    prevalence: 1.0,
                                                    isFirstParty: false,
                                                    action: .ignore)]
        let blockedTrackersGrade = pageData.calculateGrade()
        XCTAssertNotEqual(defaultGrade.site.score, blockedTrackersGrade.site.score)

        pageData.loadedTrackers = [DetectedTracker(matchedTracker: nil,
                                                   resource: URLs.resource,
                                                   page: URLs.page,
                                                   owner: "None",
                                                   prevalence: 10.0,
                                                   isFirstParty: false,
                                                   action: .ignore)]
        let loadedTrackersGrade = pageData.calculateGrade()
        XCTAssertNotEqual(blockedTrackersGrade.site.score, loadedTrackersGrade.site.score)
    }
    
    func testDefaultConstructor() {
        let pageData = PageData()
        XCTAssertNil(pageData.url)
        XCTAssertTrue(pageData.blockedTrackers.isEmpty)
        XCTAssertTrue(pageData.loadedTrackers.isEmpty)
    }
    
    private func entities() -> [Entity] {
        return [
            Entity(displayName: "Facebook", domains: [], prevalence: 0.3),
            Entity(displayName: "Google", domains: [], prevalence: 0.8)
        ]
    }

    private func detectedTracker(resource: URL, owner: String) -> DetectedTracker {
        return DetectedTracker(matchedTracker: KnownTracker.build(domain: resource.host ?? ""),
                               resource: resource,
                               page: URLs.page,
                               owner: owner,
                               prevalence: 10,
                               isFirstParty: false,
                               action: .ignore)
    }

}
