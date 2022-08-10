//
//  DetectedTrackerTests.swift
//  DuckDuckGo
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

class DetectedTrackerTests: XCTestCase {

    func testWhenDuplicateAddedToSetThenSetNotChanged() {
        var set = Set<DetectedTracker>()
        let url = URL(string: "https://www.example.com")!

        set.insert(DetectedTracker(matchedTracker: nil, resource: url, page: url, owner: nil, prevalence: 1.0, isFirstParty: false, action: .block))
        set.insert(DetectedTracker(matchedTracker: nil, resource: url, page: url, owner: nil, prevalence: 1.0, isFirstParty: false, action: .block))
        XCTAssertEqual(1, set.count)

        set.insert(DetectedTracker(matchedTracker: KnownTracker.build(domain: "example.com"),
                                   resource: url, page: url, owner: nil, prevalence: 1.0, isFirstParty: false, action: .block))
        XCTAssertEqual(2, set.count)

        set.insert(DetectedTracker(matchedTracker: KnownTracker.build(domain: "example.com"),
                                   resource: url, page: url, owner: nil, prevalence: 1.0, isFirstParty: false, action: .block))
        XCTAssertEqual(2, set.count)

        set.insert(DetectedTracker(matchedTracker: KnownTracker.build(domain: "other.com"),
                                   resource: url, page: url, owner: nil, prevalence: 1.0, isFirstParty: false, action: .block))
        XCTAssertEqual(3, set.count)
    }

}
