//
//  TrackerBlockingTests.swift
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

/// This is subject to change once known trackers are available to the app.
class TrackerDetectionTests: XCTestCase {

    struct URLs {
        
        static let example = URL(string: "http://example.com")!
        static let resource = URL(string: "http://tracker.com/tracker.js")!
        
    }
    
    func testWhenResourceWithImpliedProtocolAndDifferentEntitiesPresentedThen3rdPartyTrackerReturned() {

        let entity = Entity(name: "Example", properties: [], prevalence: nil)
        let tracker = KnownTracker(domain: "other.com", owner: nil, rules: nil, prevalence: 1.0, defaultAction: nil, subdomains: nil)
        let mockTrackerDataManager = MockTrackerDataManager(returnEntity: entity, returnTracker: tracker)

        let pageUrl = URLs.example
        let resourceUrl = URLs.resource
        
        let detection = DefaultTrackerDetection(trackerDataManager: { mockTrackerDataManager })
        let actual = detection.detectTrackerFor(resourceUrl: resourceUrl, onPageWithUrl: pageUrl)
        let expected = DetectedTracker(resource: resourceUrl, page: pageUrl, owner: nil, prevalence: 1.0, isFirstParty: false)
        XCTAssertEqual(actual, expected)
    }

}
