//
//  AdClickAttributionConfigTests.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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

class AdClickAttributionConfigTests: XCTestCase {

    let subject = DefaultAdClickAttributionConfig()

    func testResourceOnAllowlistDetection() {
        XCTAssertTrue(subject.resourceIsOnAllowlist(URL(string: "https://bat.bing.com/y.js")!))
    }

    // swiftlint:disable line_length
    func testAttributionTypeDetection() {

        let tests: [String: AttributionType] = [
            "https://example.com/y.js?ad_domain=test.com": .none, // does not match host + path part
            "https://duckduckgo.com/y.js?u3=x": .heuristic, // no ad_domain
            "https://duckduckgo.com/y.js?u3=x&ad_domain=test.com": .vendor(name: "test.com"), // ad_domain present
            "https://www.search-company.site/y.js?u3=x": .heuristic, // no ad_domain

            // From https://www.search-company.site/shared/testCases.json
            // Ad 1
            "https://www.search-company.site/y.js?eddgt=nothing&rut=else&u3=foo&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D1": .heuristic,

            // Ad 2
            "https://www.search-company.site/m.js?iurl=foo&ivu=foo&sfexp=0&shopping=1&spld=foo&styp=entitydetails&dsl=1&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D2": .heuristic,

            // Ad 3
            "https://www.search-company.site/y.js?eddgt=nothing&rut=else&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D3": .none,

            // Ad 4
            "https://www.search-company.site/m.js?iurl=foo&ivu=foo&sfexp=0&shopping=1&spld=foo&styp=entitydetails&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D4": .none,

            // Ad 5
            "https://www.search-company.site/y.js?ad_domain=&eddgt=nothing&rut=else&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D5": .heuristic,

            // Ad 6
            "https://www.search-company.site/m.js?ad_domain=&iurl=foo&ivu=foo&sfexp=0&shopping=1&spld=foo&styp=entitydetails&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D6": .heuristic,

            // Ad 7
            "https://www.search-company.site/y.js?ad_domain=www.publisher-company.site&eddgt=nothing&rut=else&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D7": .vendor(name: "publisher-company.site"),

            // Ad 8
            "https://www.search-company.site/m.js?ad_domain=www.publisher-company.site&iurl=foo&ivu=foo&sfexp=0&shopping=1&spld=foo&styp=entitydetails&u=https%253A%252F%252Fwww.ad-company.site%252Faclick%253Fld%253DldValue%2526u%253DuValue%2526rlid%253DrlidValue%2526vqd%253DvqdValue%2526iurl%253DiurlValue%2526CID%253DCIDValue%2526ID%253D8": .vendor(name: "publisher-company.site")
        ]

        tests.forEach { test in
            XCTAssertEqual(subject.attributionTypeForURL(URL(string: test.key)!), test.value, "AttributionType detection failed for \(test.key)")
        }

    }
    // swiftlint:enable line_length

    func testETLDPlus1() {
        let tests = [
            "www.facebook.com": "facebook.com",
            "test.facebook.com": "facebook.com",
            "clicks.test.facebook.com": "facebook.com"
        ]

        for test in tests {
            let given = test.key
            let expected = test.value
            XCTAssertEqual(TLD.shared.eTLDplus1(given), expected)
        }
    }

    func testExemptionExpiry() {

        let expectedExpiryInterval: TimeInterval = 72 * 60 * 60

        XCTAssertFalse(subject.hasExemptionExpired(Date()))
        XCTAssertFalse(subject.hasExemptionExpired(Date.init(timeIntervalSinceNow: -(expectedExpiryInterval - 1))))
        XCTAssertTrue(subject.hasExemptionExpired(Date.init(timeIntervalSinceNow: -expectedExpiryInterval)))

    }

}

extension AttributionType: Equatable {

    public static func == (lhs: AttributionType, rhs: AttributionType) -> Bool {
        if case .vendor(let lhsName) = lhs, case .vendor(let rhsName) = rhs { return lhsName == rhsName }
        if case .heuristic = lhs, case .heuristic = rhs { return true }
        if case .none = lhs, case .none = rhs { return true }
        return false
    }

}
