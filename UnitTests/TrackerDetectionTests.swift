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
@testable import TrackerRadarKit

// swiftlint:disable type_body_length
/// This is subject to change once known trackers are available to the app.
class TrackerDetectionTests: XCTestCase {

    struct TestCase: Codable {

        let action: String
        let urlToCheck: String?
        let siteUrl: String?
        let requestType: String?
        let expectedOwner: String?
        let expectedReason: String?
        let firstParty: Bool
        let expectedRule: String?
        let redirectUrl: String?
        let matchedRuleException: Bool

    }

    struct URLs {
        
        static let example = URL(string: "http://example.com")!
        static let resource = URL(string: "http://tracker.com/tracker.js")!
        
    }

    func testWhenDomainMatchesThenBlock() {
        let tracker = KnownTracker.build(domain: "facebook.com")
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .block:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenSubdomainMatchesThenBlock() {
        let tracker = KnownTracker.build(domain: "facebook.com", subdomains: ["a"])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://a.facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .block:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenRuleHasMismatchingDomainOptionsThenIgnores() {

        let rule = KnownTracker.Rule.build(rule: ".*", options: KnownTracker.Rule.Matching(domains: ["google.com"], types: nil))
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [ rule ])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenRuleHasMatchingDomainOptionsThenBlocks() {

        let rule = KnownTracker.Rule.build(rule: ".*", options: KnownTracker.Rule.Matching(domains: ["example.com"], types: nil))
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [ rule ])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .block:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenRuleHasMatchingDomainExceptionThenIgnore() {

        let rule = KnownTracker.Rule.build(rule: ".*", exceptions: KnownTracker.Rule.Matching(domains: ["example.com"], types: nil))
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [ rule ])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenRuleHasMismatchingResourceTypeOptionsThenIgnores() {

        let rule = KnownTracker.Rule.build(rule: ".*", options: KnownTracker.Rule.Matching(domains: nil, types: [ "image" ]))
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [ rule ])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: "stylesheet")

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenRuleHasMatchingResourceTypeOptionsThenBlocks() {

        let rule = KnownTracker.Rule.build(rule: ".*", options: KnownTracker.Rule.Matching(domains: nil, types: [ "image" ]))
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [ rule ])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: "image")

        XCTAssertNotNil(result)
        switch result?.action {
        case .block:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenIgnoreRuleMatchThenIgnoreAction() {
        let rule = KnownTracker.Rule.build(rule: ".*/benign.js", action: .ignore)
        let tracker = KnownTracker.build(domain: "facebook.com", rules: [rule])
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/some/path/benign.js",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }

    func testWhenFirstPartyMatchThenIgnoreAction() {
        let facebook = Entity(displayName: "Facebook", domains: ["whatsapp.com"], prevalence: 1.0)
        let tracker = KnownTracker.build(domain: "facebook.com", owner: .init(name: "Facebook, Inc.", displayName: "Facebook"))
        let trackerData = TrackerData(trackers: ["facebook.com": tracker], entities: ["Facebook, Inc.": facebook], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://facebook.com/path/to/tracker.js",
                                  pageUrl: "https://whatsapp.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }

    }
    
    func testWhenResourceContainsBlockedUrlThenDoesNotBlock() {
        let amazon = KnownTracker.build(domain: "amazonaws.com", defaultAction: .ignore)
        let facebook = KnownTracker.build(domain: "facebook.com")
        let trackerData = TrackerData(trackers: ["facebook.com": facebook, "amazonaws.com": amazon], entities: [:], domains: [:])

        let result = runDetection(trackerData: trackerData,
                                  resourceUrl: "https://amazonaws.com/imageproxy/https://facebook.com/person.png",
                                  pageUrl: "https://example.com/",
                                  resourceType: nil)

        XCTAssertNotNil(result)
        switch result?.action {
        case .ignore:
            break

        default:
            XCTFail("Unexpected result \(result?.action as Any)")
        }
    }

    func test() {
        guard let trackerTestCases = loadTrackerTestCases() else {
            return
        }

        let trackerData = createTestTrackerData()
        let trackerDataManager = DefaultTrackerDataManager()
        trackerDataManager.trackerData = trackerData

        let detection = DefaultTrackerDetection(trackerDataManager: { trackerDataManager  })

        trackerTestCases.enumerated().forEach {

            guard let pageUrl = URL(string: $0.element.siteUrl!) else {
                XCTFail("\($0.offset): Could not parse siteUrl")
                return
            }

            guard let resourceUrl = URL(string: $0.element.urlToCheck!, relativeTo: pageUrl) else {
                XCTFail("\($0.offset): Could not parse urlToCheck")
                return
            }

            guard let detected = detection.detectTrackerFor(resourceUrl: resourceUrl,
                                                            onPageWithUrl: pageUrl,
                                                            asResourceType: $0.element.requestType) else {
                XCTFail("\($0.offset): Could not find tracker")
                return
            }

            switch detected.action {

            case .block:
                XCTAssertTrue(["block", "redirect"].contains($0.element.action),
                               "\($0.offset): Expected \($0.element.action) was block")

            case .ignore:
                XCTAssertTrue(["ignore", "redirect"].contains($0.element.action),
                               "\($0.offset): Expected \($0.element.action) was ignore|redirect")

            }

        }

    }

    private func createTestTrackerData() -> TrackerData {
        let rule1 = KnownTracker.Rule(rule: "geo.yahoo.com",
                                      surrogate: nil,
                                      action: nil,
                                      // original rule had aol.com but that shares an owner with yahoo.com so doesn't make sense
                                      options: KnownTracker.Rule.Matching(domains: [ "example.com" ], types: nil),
                                      exceptions: nil)

        let rule2 = KnownTracker.Rule(rule: "a.yahoo.com/?",
                                      surrogate: "yahoo.com/a.js",
                                      action: nil,
                                      options: nil,
                                      exceptions: KnownTracker.Rule.Matching(domains: [ "example2.com" ], types: [ "image" ]))

        let rule3 = KnownTracker.Rule(rule: "b.yahoo.com/.*\\?ad=asdf",
                                      surrogate: nil,
                                      action: .ignore,
                                      options: nil,
                                      exceptions: nil)

        let oath = Entity(displayName: "Oath", domains: [ "yahoo.com", "aol.com", "advertising.com" ], prevalence: 1.0)
        let yahoo = KnownTracker(domain: "yahoo.com",
                                 defaultAction: .block,
                                 owner: KnownTracker.Owner(name: "Oath", displayName: "Oath"),
                                 prevalence: 1.0,
                                 subdomains: nil,
                                 rules: [ rule1, rule2, rule3 ])

        let example = KnownTracker(domain: "example.com", defaultAction: .ignore, owner: nil, prevalence: 1.0, subdomains: nil, rules: nil)

        let trackers = ["yahoo.com": yahoo, "example.com": example]

        return TrackerData(trackers: trackers, entities: ["Oath": oath], domains: [:])
    }

    private func loadTrackerTestCases() -> [TestCase]? {

        let testCasesUrl = Bundle(for: TrackerDataTests.self).url(forResource: "tracker-cases", withExtension: "json")!
        guard let testCaseData = try? Data(contentsOf: testCasesUrl) else {
            XCTFail("failed to read tracker-cases.json")
            return nil
        }

        do {
            return try JSONDecoder().decode([TestCase].self, from: testCaseData)
        } catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }

    /// Assumption that Safari will always send a trailing empty path (e.g. https://domain/ ) so tests should reflect that.
    private func runDetection(trackerData: TrackerData,
                              resourceUrl: String,
                              pageUrl: String,
                              resourceType: String?) -> DetectedTracker? {
        let detection = DefaultTrackerDetection { () -> TrackerDataManager in
            let manager = DefaultTrackerDataManager()
            manager.trackerData = trackerData
            return manager
        }
        return detection.detectTrackerFor(resourceUrl: URL(string: resourceUrl)!,
                                                onPageWithUrl: URL(string: pageUrl)!,
                                                asResourceType: resourceType)
    }

}
// swiftlint:enable type_body_length
