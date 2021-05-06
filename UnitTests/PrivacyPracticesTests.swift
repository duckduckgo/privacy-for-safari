//
//  PrivacyPracticesTests.swift
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
@testable import TrackerBlocking

class PrivacyPracticesTests: XCTestCase {

    let mockTrackerDataManager = MockTrackerDataManager()

    func testLoadBundledData() {
        XCTAssertEqual(300, (practicesManager() as? DefaultPrivacyPracticesManager)?.terms.count)
    }

    func testWhenUrlWithNoPracticesThenReturnUnknownPrivacyPractice() {
        let url = URL(string: "https://example.com")!
        let practice = practicesManager().findPrivacyPractice(forUrl: url)
        XCTAssertEqual(practice.score, 2)
        XCTAssertEqual(practice.summary, .unknown)
        XCTAssertEqual(practice.badReasons, [])
        XCTAssertEqual(practice.goodReasons, [])
    }

    func testWhenKnownDomainThenReturnsCorrectPrivacyPractice() {
        let url = URL(string: "https://duckduckgo.com")!
        let practice = practicesManager().findPrivacyPractice(forUrl: url)
        XCTAssertEqual(practice.score, 0)
    }

    func testWhenKnownDomainWithSubdomainThenReturnsCorrectPrivacyPractice() {
        let url = URL(string: "https://help.duckduckgo.com")!
        let practice = practicesManager().findPrivacyPractice(forUrl: url)
        XCTAssertEqual(practice.score, 0)
    }

    func testWhenRelatedEntityHasWorstScoreThenUseIt() {
        class Mock: MockTrackerDataManager {
            override func entity(forUrl url: URL) -> Entity? {
                return Entity(displayName: "Facebook", domains: [], prevalence: 0)
            }
        }

        let url = URL(string: "https://whatsapp.com")!
        let practice = practicesManager(Mock()).findPrivacyPractice(forUrl: url)
        XCTAssertEqual(practice.score, 10)
    }

    private func practicesManager(_ trackerDataManager: TrackerDataManager = MockTrackerDataManager()) -> PrivacyPracticesManager {
        return DefaultPrivacyPracticesManager(trackerDataManager: { trackerDataManager })
    }

}
