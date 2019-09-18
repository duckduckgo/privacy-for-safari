//
//  PrivacyPracticesTests.swift
//  UnitTests
//
//  Created by Christopher Brind on 12/09/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import XCTest
@testable import TrackerBlocking

class PrivacyPracticesTests: XCTestCase {

    let mockTrackerDataManager = MockTrackerDataManager()

    func testLoadBundledData() {
        XCTAssertEqual(299, (practicesManager() as? DefaultPrivacyPracticesManager)?.terms.count)
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
        // swiftlint:disable nesting
        class Mock: MockTrackerDataManager {
            override func entity(forUrl url: URL) -> Entity? {
                return Entity(displayName: "Facebook", domains: [], prevalence: 0)
            }
        }
        // swiftlint:enable nesting

        let url = URL(string: "https://whatsapp.com")!
        let practice = practicesManager(Mock()).findPrivacyPractice(forUrl: url)
        XCTAssertEqual(practice.score, 10)
    }

    private func practicesManager(_ trackerDataManager: TrackerDataManager = MockTrackerDataManager()) -> PrivacyPracticesManager {
        return DefaultPrivacyPracticesManager(trackerDataManager: { trackerDataManager })
    }

}
