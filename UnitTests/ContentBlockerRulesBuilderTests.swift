//
//  ContentBlockerRulesBuilderTests.swift
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

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class ContentBlockerRulesBuilderTests: XCTestCase {
    
    var subdomainPrefix: String {
        ContentBlockerRulesBuilder.Constants.subDomainPrefix
    }
    
    var domainSuffix: String {
        ContentBlockerRulesBuilder.Constants.domainMatchSuffix
    }
    
    func testWhenNoTrackersThenGeneratesSingleBlockingRuleForInstallButton() {
        let trackerData = TrackerData(trackers: [:], entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(1, rules.count)
        assert(rules,
               containsTrackerWithUrlFilter: subdomainPrefix + "duckduckgo\\.com" + domainSuffix,
               action: .cssDisplayNone(selector: ".ddg-extension-hide"))
    }
    
    // MARK: profiles

    /// Profile A
    func testWhenTrackerWithNoRulesThenGenerateSimpleBlockingRule() {
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .block) ]
        
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)
        assert(rules, containsTrackerWithUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
    }

    /// Profile B
    func testWhenBlockingTrackerHasRuleThenGeneratesDomainAndRuleBlockingRules() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [ .build(rule: "facebook\\.com/.*/trackit.js") ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)
        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .block())
    }

    /// Profile C
    func testWhenBlockingTrackerWithOptionsThenGeneratesRulesToBlockMatchingOptions() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js",
                       options: .init(domains: [ "example.com" ], types: [ "image" ] ))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(4, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules())
        assert(rules[2], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .block(),
               ifDomain: [ "*example.com" ], resourceType: [ .image ])
    }

    /// Profile D1
    func testWhenBlockingTrackerWithIgnoreRuleThenGeneratesRulesToIgnorePreviousRules() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js", action: .ignore)
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules())
    }

    /// Profile D2
    func testWhenBlockingTrackerWithIgnoreRuleAndOptionsThenGeneratesRulesToIgnorePreviousRules() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js", action: .ignore,
                       options: .init(domains: ["example.com"], types: [ "image" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules(),
               ifDomain: ["*example.com"], resourceType: [ .image ])
    }

    /// Profile E
    func testWhenBlockingTrackerWithExceptionsThenGeneratesRulesToIgnorePreviousRules() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js", exceptions: .init(domains: ["example.com"], types: nil))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules(),
               ifDomain: ["*example.com"])
    }

    /// Profile F
    func testWhenBlockingTrackerWithOptionsAndExceptionsThenGeneratesRulesToIgnorePreviousRules() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js",
                       options: .init(domains: ["example.com"], types: [ "stylesheet" ]),
                       exceptions: .init(domains: ["other.com"], types: [ "image" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(5, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules())
        assert(rules[2], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .block(),
               ifDomain: ["*example.com"], resourceType: [ .stylesheet ])
        assert(rules[3], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules(),
           ifDomain: ["*other.com"], resourceType: [ .image ])

    }

    /// Profile Z
    func testWhenIgnoreTrackerThenNoRulesGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore)
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(1, rules.count)

    }

    /// Profile Y
    func testWhenIgnoreTrackerWithRuleThenBlockingRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js")
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block())

    }

    /// Profile X
    func testWhenIgnoreTrackerWithOptionsRuleThenBlockingRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js",
                       options: .init(domains: [ "example.com" ], types: [ "image" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block(),
               ifDomain: [ "*example.com" ], resourceType: [ .image ])

    }

    /// Profile W
    func testWhenIgnoreTrackerWithExceptionThenBlockingRuleAndIgnoreMatchingExceptionsRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js",
                       exceptions: .init(domains: [ "example.com" ], types: [ "image" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .ignorePreviousRules(),
               ifDomain: [ "*example.com" ], resourceType: [ .image ])

    }

    /// Profile V
    func testWhenIgnoreTrackerWithOptionsAndExceptionThenBlockingRuleAndIgnoreMatchingExceptionsRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js",
                       options: .init(domains: [ "example.com" ], types: [ "image" ]),
                       exceptions: .init(domains: [ "other.com" ], types: [ "stylesheet" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block(),
               ifDomain: [ "*example.com" ], resourceType: [ .image ])
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .ignorePreviousRules(),
               ifDomain: [ "*other.com" ], resourceType: [ .stylesheet ])

    }

    /// Profile U1
    func testWhenIgnoreTrackerWithOptionsIgnoreRuleThenBlockingRuleAndIgnoreOptionsRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js", action: .ignore, options: .init(domains: [ "example.com" ], types: [ "image" ]))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .ignorePreviousRules(),
               ifDomain: [ "*example.com" ], resourceType: [ .image ])

    }

    /// Profile U2
    func testWhenIgnoreTrackerWithIgnoreRuleThenBlockingRuleAndIgnoreOptionsRuleGenerated() {

        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .ignore, rules: [
                .build(rule: "facebook\\.com/.*/ad.js", action: .ignore)
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/ad.js", action: .ignorePreviousRules())

    }

    // MARK: other rules

    // swiftlint:disable line_length
    func testWhenMultiRuleTrackerThenCBRsNotRepeated() {
                
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com", rules: [
                .build(rule: "facebook\\.com/.*/trackit.js", options: .init(domains: [ "example.com" ], types: [ "image" ] )),
                .build(rule: "facebook\\.com/.*/trackit.js", options: .init(domains: [ "other.com" ], types: [ "stylesheet" ] )),
                .build(rule: "facebook\\.com/.*/login.png", options: .init(domains: ["wordpress.com"], types: nil),
                       exceptions: .init(domains: ["login.wordpress.com"], types: nil))
            ])
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        print(#function, rules)
        XCTAssertEqual(8, rules.count)

        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/login.png", action: .ignorePreviousRules())
        assert(rules[2], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/login.png", action: .block(), ifDomain: ["*wordpress.com"])
        assert(rules[3], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/login.png", action: .ignorePreviousRules(), ifDomain: ["*login.wordpress.com"])
        assert(rules[4], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .ignorePreviousRules())
        assert(rules[5], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .block(), ifDomain: ["*example.com"], resourceType: [.image])
        assert(rules[6], matchesUrlFilter: subdomainPrefix + "facebook\\.com/.*/trackit.js", action: .block(), ifDomain: ["*other.com"], resourceType: [.stylesheet])

    }
    // swiftlint:enable line_length
    
    func testWhenTrackerHasWhitelistAdditionalIgnorePreviousRuleCreatedForSpecifiedDomainsOnly() {
        
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .block) ]
        
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules(withExceptions: ["brokensite.com", "othersite.com"])
        XCTAssertEqual(3, rules.count)
        assert(rules[0], matchesUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
        assert(rules[1], matchesUrlFilter: ".*", action: .ignorePreviousRules(), ifDomain: ["brokensite.com", "othersite.com"])
    }
    
    func testWhenTrackerHasOwnerThenRelatedDomainsAreExcluded() {
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", owner: .init(name: "Facebook, Inc.", displayName: "Facebook"))]
        let entities = ["Facebook, Inc.": Entity(displayName: "Facebook", domains: ["instagram.com", "whatsapp.com"], prevalence: 1.0)]
        let trackerData = TrackerData(trackers: facebook, entities: entities, domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)
        assert(rules,
               containsTrackerWithUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix,
               action: .block(),
               unlessDomain: [ "*instagram.com", "*whatsapp.com" ])
    }
    
    func testWhenTrackerWithNoRulesAndMultipleSubdomainsThenGenerateSimpleBlockingRuleForEachDomain() {
        
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", subdomains: [ "img", "tracker", "cdn" ])]
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)
        assert(rules, containsTrackerWithUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
    }
    
    func testWhenMultipleTrackersWithNoRulesThenGenerateSimpleBlockingRules() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com"),
            "Google": KnownTracker.build(domain: "google.com")
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(3, rules.count)
        assert(rules, containsTrackerWithUrlFilter: subdomainPrefix + "google\\.com" + domainSuffix, action: .block())
        assert(rules, containsTrackerWithUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
    }

    func testWhenMultipleTrackersWithNoRulesAndDifferentActionsThenGenerateOnlyBlockingRules() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com"),
            "Google": KnownTracker.build(domain: "google.com", defaultAction: .ignore)
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        XCTAssertEqual(2, rules.count)
        assert(rules, containsTrackerWithUrlFilter: subdomainPrefix + "facebook\\.com" + domainSuffix, action: .block())
    }

    func testWhenExceptionsAreEmptyThenNoRuleCreated() {
        
        let trackers = [
            "Facebook": KnownTracker.build(domain: "facebook.com"),
            "Google": KnownTracker.build(domain: "google.com", defaultAction: .ignore)
        ]

        let trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules(withExceptions: [])
        XCTAssertEqual(2, rules.count)
    }
    
    func testWhenResourceContainsMatchingTrackerInUrlThenDoesNotMatch() {
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .block) ]
        
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        
        let resourceUrl = URL(string: "http://dodgyads.com/proxy/for/https://facebook.com/hello.com")!
        let pageUrl = URL(string: "http://exaple.com")!
        XCTAssertFalse(rules[0].matches(resourceUrl: resourceUrl, onPageWithUrl: pageUrl, ofType: .script))        
    }

    func testWhenResourceContainsPortInUrlThenMatches() {
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .block) ]
        
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        
        let resourceUrl = URL(string: "http://facebook.com:8484/hello.com")!
        let pageUrl = URL(string: "http://exaple.com")!
        XCTAssertTrue(rules[0].matches(resourceUrl: resourceUrl, onPageWithUrl: pageUrl, ofType: .script))
    }

    func testWhenResourceContainsWebSocketSchemeInUrlThenMatches() {
        let facebook = ["Facebook": KnownTracker.build(domain: "facebook.com", defaultAction: .block) ]
        
        let trackerData = TrackerData(trackers: facebook, entities: [:], domains: [:])
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules()
        
        let resourceUrl = URL(string: "wss://facebook.com:8484/hello.com")!
        let pageUrl = URL(string: "http://exaple.com")!
        XCTAssertTrue(rules[0].matches(resourceUrl: resourceUrl, onPageWithUrl: pageUrl, ofType: .script))
    }

    // MARK: helper functions

    private func assert(_ rules: [ContentBlockerRule],
                        containsTrackerWithUrlFilter urlFilter: String,
                        action: ContentBlockerRule.Action,
                        ifDomain: [String]? = nil,
                        unlessDomain: [String]? = nil,
                        file: StaticString = #file, line: UInt = #line) {
        
        for r in rules {
            if nil == rule(r, matchesUrlFilter: urlFilter, action: action, ifDomain: ifDomain, unlessDomain: unlessDomain) {
                return
            }
        }
        
        XCTFail("Tracker not found", file: file, line: line)
    }
    
    private func assert(_ rule: ContentBlockerRule,
                        matchesUrlFilter urlFilter: String,
                        action: ContentBlockerRule.Action,
                        ifDomain: [String]? = nil,
                        unlessDomain: [String]? = nil,
                        resourceType: [ContentBlockerRule.Trigger.ResourceType]? = nil,
                        file: StaticString = #file, line: UInt = #line) {
        
        guard let match = self.rule(rule,
                              matchesUrlFilter: urlFilter,
                              action: action,
                              ifDomain: ifDomain,
                              unlessDomain: unlessDomain,
                              resourceType: resourceType) else { return }
        
        XCTFail(match, file: file, line: line)
    }

    private func rule(_ rule: ContentBlockerRule,
                      matchesUrlFilter urlFilter: String,
                      action: ContentBlockerRule.Action,
                      ifDomain: [String]? = nil,
                      unlessDomain: [String]? = nil,
                      resourceType: [ContentBlockerRule.Trigger.ResourceType]? = nil) -> String? {
        
        if rule.trigger.urlFilter != urlFilter { return "urlFilter expected \(urlFilter) was \(rule.trigger.urlFilter)" }
        if rule.trigger.ifDomain != ifDomain { return "ifDomain expected \(ifDomain as Any) was \(rule.trigger.ifDomain as Any)" }
        if rule.trigger.unlessDomain != unlessDomain { return "unlessTopUrl expected \(unlessDomain as Any) was \(rule.trigger.unlessDomain as Any)" }
        if rule.trigger.resourceType != resourceType { return "resourceType expected \(resourceType as Any) was \(rule.trigger.resourceType as Any)" }
        if rule.action != action { return "action expected \(action) was \(rule.action)" }
        
        return nil
    }
    
}

// MARK: helpful extensions

extension KnownTracker {
    
    static func build(domain: String,
                      defaultAction: ActionType = .block,
                      owner: Owner? = nil,
                      prevalence: Double = 1.0,
                      subdomains: [String]? = nil,
                      rules: [Rule]? = nil) -> Self {
        
        return Self.init(domain: domain, defaultAction: defaultAction, owner: owner, prevalence: prevalence, subdomains: subdomains, rules: rules)
    }
    
}

extension KnownTracker.Rule {

    static func build(rule: String,
                      surrogate: String? = nil,
                      action: KnownTracker.ActionType? = nil,
                      options: Self.Matching? = nil,
                      exceptions: Self.Matching? = nil) -> Self {

        return Self.init(rule: rule, surrogate: surrogate, action: action, options: options, exceptions: exceptions)
    }

}

// swiftlint:enable type_body_length
// swiftlint:enable file_length
