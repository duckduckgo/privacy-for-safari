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

    func testAttributionTypeDetection() {

        let tests: [String: AttributionType] = [

            "https://duckduckgo.com/y.js?ad_domain=&foo=&bar=": .heuristic,
            "https://duckduckgo.com/y.js?ad_domain=example.com&foo=&bar=": .vendor(name: "example.com"),
            "https://duckduckgo.com/y.js?ad_domain=&foo=&bar=&u3=xyz": .heuristic,
            "https://duckduckgo.com/y.js?foo=&bar=&u3=xyz": .none,
            "https://duckduckgo.com/y.js?foo=&bar=": .none,

            "https://links.duckduckgo.com/m.js?ad_domain=&foo=&bar=": .heuristic,
            "https://links.duckduckgo.com/m.js?ad_domain=example.com&foo=&bar=": .vendor(name: "example.com"),
            "https://links.duckduckgo.com/m.js?ad_domain=&foo=&bar=&u3=xyz": .heuristic,
            "https://links.duckduckgo.com/m.js?foo=&bar=&u3=xyz": .none,
            "https://links.duckduckgo.com/m.js?foo=&bar=": .none

        ]

        tests.forEach { test in
            XCTAssertEqual(subject.attributionTypeForURL(URL(string: test.key)!), test.value, "AttributionType detection failed for \(test.key)")
        }

    }

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
