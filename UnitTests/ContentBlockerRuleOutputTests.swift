//
//  ContentBlockerRuleOutputTests.swift
//  UnitTests
//
//  Created by Christopher Brind on 22/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import XCTest
@testable import TrackerBlocking
import WebKit

class ContentBlockerRuleOutputTests: XCTestCase {

    func testContentBlockerRule() {
     
        guard let json = encode(ContentBlockerRule(trigger: .trigger(urlFilter: ".*"), action: .block())) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
        {
            "trigger": { "url-filter": ".*", "load-type": ["third-party"] },
            "action": { "type": "block" }
        }
        """
        )
    
    }
        
    func testIgnorePreviousRulesAction() {
        guard let json = encode(ContentBlockerRule.Action.ignorePreviousRules()) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
            { "type": "ignore-previous-rules" }
        """
        )
    }

    func testBlockAction() {
        guard let json = encode(ContentBlockerRule.Action.block()) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
            { "type": "block" }
        """
        )
    }

    func testUrlFilterAndUnlessTopUrlTrigger() {
        guard let json = encode(ContentBlockerRule.Trigger.trigger(urlFilter: ".*",
                                                                   unlessDomain: [ "domain1", "domain2" ])) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
            { "url-filter": ".*", "unless-domain": ["domain1", "domain2"], "load-type": ["third-party"] }
        """
        )
    }

    func testUrlFilterAndResourceTypeTrigger() {
        guard let json = encode(ContentBlockerRule.Trigger.trigger(urlFilter: ".*",
                                                                     ifDomain: nil,
                                                                     resourceType: [ .image, .stylesheet ])) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
            { "url-filter": ".*", "load-type": ["third-party"], "resource-type": ["image", "style-sheet"] }
        """
        )
    }

    func testUrlFilterAndIfDomainTrigger() {
        guard let json = encode(ContentBlockerRule.Trigger.trigger(urlFilter: ".*",
                                                                     ifDomain: ["example.com", "facebook.com"],
                                                                     resourceType: nil)) else {
            XCTFail("failed to encode rule")
            return
        }

        assert(json, equals:
        """
            { "url-filter": ".*", "load-type": ["third-party"], "if-domain": ["example.com", "facebook.com"] }
        """
        )
    }
    
    func testUrlFilterTrigger() {
        
        guard let json = encode(ContentBlockerRule.Trigger.trigger(urlFilter: ".*")) else {
            XCTFail("failed to encode rule")
            return
        }
        
        assert(json, equals:
        """
           { "url-filter": ".*", "load-type": ["third-party"] }
        """
        )
    }
    
    func testWhenGivenASingleBlockingRuleThenItCompiles() {
        let rule = ContentBlockerRule(trigger: .trigger(urlFilter: ".*"), action: .block())
        assertCompiles(rules: [rule])
    }
    
    func testWhenGivenBlockingRuleWithUnlessTopUrlItCompiles() {
        let rule = ContentBlockerRule(trigger: .trigger(urlFilter: ".*",
                                                        unlessDomain: [ "domain1", "domain2" ]),
                                      action: .block())
        assertCompiles(rules: [rule])
    }

    func testWhenGivenBlockingRuleWithIfDomainAndResourcesItCompiles() {
        let resources = ContentBlockerRule.Trigger.ResourceType.allCases
        let rule = ContentBlockerRule(trigger: .trigger(urlFilter: ".*",
                                                        ifDomain: [ "domain1", "domain2" ],
                                                        resourceType: resources),
                                      action: .block())
        assertCompiles(rules: [rule])
    }
    
    func testWhenGivenASingleIgnorePreviousRuleThenItCompiles() {
        let rule = ContentBlockerRule(trigger: .trigger(urlFilter: ".*"), action: .ignorePreviousRules())
        assertCompiles(rules: [rule])
    }
    
    func testWhenGivenMultipleDifferentRulesThenItCompiles() {

        let rule1 = ContentBlockerRule(trigger: .trigger(urlFilter: ".*"), action: .ignorePreviousRules())
        let resources = ContentBlockerRule.Trigger.ResourceType.allCases
        let rule2 = ContentBlockerRule(trigger: .trigger(urlFilter: ".*",
                                                        ifDomain: [ "domain1", "domain2" ],
                                                        resourceType: resources),
                                      action: .block())
        let rule3 = ContentBlockerRule(trigger: .trigger(urlFilter: ".*",
                                                        unlessDomain: [ "domain1", "domain2" ]),
                                      action: .block())

        assertCompiles(rules: [rule1, rule2, rule3])
    }
    
    func testSampleDataCompiles() {
        let url = Bundle(for: TrackerDataTests.self).url(forResource: "sample-tracker-data", withExtension: "json")!
        let trackerData = TrackerData.decode(contentsOf: url)
        let builder = ContentBlockerRulesBuilder(trackerData: trackerData!)

        // Check each individually to isolate problems faster
        trackerData?.trackers.values.forEach {
            let rules = builder.buildRules(from: $0)
            assertCompiles(rules: rules)
        }
    }

    func assertCompiles(rules: [ContentBlockerRule], file: StaticString = #file, line: UInt = #line) {

        guard let store = WKContentRuleListStore.default() else {
            XCTFail("Failed to find store")
            return
        }
        
        guard let json = try? JSONEncoder().encode(rules) else {
            XCTFail("failed to encode rule")
            return
        }
        
        let ruleList = String(data: json, encoding: .utf8)!

        let ex = expectation(description: "rule compilation")
        store.compileContentRuleList(forIdentifier: "test", encodedContentRuleList: ruleList) { _, error in
            XCTAssertNil(error, file: file, line: line)
            ex.fulfill()
        }
        
        wait(for: [ex], timeout: 5.0)
    }
    
    func encode<T>(_ value: T) -> Any? where T: Encodable {
        
        guard let data = try? JSONEncoder().encode(value) else {
            XCTFail("failed to encode as json data")
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            XCTFail("failed to create json object")
            return nil
        }

        return json
    }
    
    func assert(_ json: Any, equals expected: String, file: StaticString = #file, line: UInt = #line) {
       
        guard let expectedJson = try? JSONSerialization.jsonObject(with: expected.data(using: .utf8)!, options: []) else {
            XCTFail("failed to create json object", file: file, line: line)
            return
        }

        guard let normalisedExpected = try? JSONSerialization.data(withJSONObject: expectedJson, options: []) else {
            XCTFail("Expected could not be normalised", file: file, line: line)
            return
        }

        guard let normalisedActual = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            XCTFail("actual could not be normalised", file: file, line: line)
            return
        }
        XCTAssertEqual(String(data: normalisedExpected, encoding: .utf8)!, String(data: normalisedActual, encoding: .utf8)!, file: file, line: line)
    }
    
}
