//
//  TrackerData.swift
//  TrackersBuilder
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

import Foundation

public struct TrackerData: Codable {
    
    public let trackers: [KnownTracker]
    public let entities: [Entity]
    
    public init(trackers: [KnownTracker], entities: [Entity]) {
        self.trackers = trackers
        self.entities = entities
    }

    public func contentBlockerRules(withTrustedSites trustedSites: [String]) -> [ContentBlockerRule] {
        
        var rules = trackers.compactMap { $0.contentBlockerRules(entitiesByName: entitiesByName() ) }.flatMap { $0 }
        
        if !trustedSites.isEmpty {
            rules.append(ContentBlockerRule(trigger: .trigger(urlFilter: ".*", ifDomain: trustedSites), action: .ignorePreviousRules()))
        }
        
        return rules
    }

    func trackersByRegex() -> [NSRegularExpression: KnownTracker] {

        var trackers = [NSRegularExpression: KnownTracker]()

        func addRegexRule(pattern: String, tracker: KnownTracker) {
            do {
                trackers[try NSRegularExpression(pattern: pattern, options: [])] = tracker
            } catch {
                NSLog("Failed to compile regex \(pattern) \(error)")
            }
        }

        self.trackers.forEach { tracker in
            if let trackerRules = tracker.rules {
                trackerRules.forEach { rule in
                    addRegexRule(pattern: rule.rule, tracker: tracker)
                }
            } else {
                let domain = tracker.domain.replacingOccurrences(of: ".", with: "\\.")
                addRegexRule(pattern: domain, tracker: tracker)
            }
        }

        return trackers
    }
    
    func entitiesByName() -> [String: Entity] {
        var entitiesByName = [String: Entity]()
        entities.forEach { entity in
            entitiesByName[entity.name] = entity
        }
        return entitiesByName
    }
    
    func entitiesByDomain() -> [String: Entity] {
        var entitiesByDomain = [String: Entity]()
        self.entities.forEach { entity in
            entity.properties.forEach { domain in
                entitiesByDomain[domain] = entity
            }
        }
        return entitiesByDomain
    }
    
}

fileprivate extension KnownTracker {
    
    static let resourceTypeMapping: [String: ContentBlockerRule.ResourceType] = [
        "script": .script,
        "xmlhttprequest": .raw,
        "subdocument": .document,
        "image": .image,
        "stylesheet": .styleSheet
    ]
    
    func contentBlockerRules(entitiesByName: [String: Entity]) -> [ContentBlockerRule]? {
        guard defaultAction != "ignore" else { return nil }
        
        let trackerExceptions = (entitiesByName[owner?.name ?? ""]?.properties ?? [domain]).map { "*" + $0 }
        
        if let trackerRules = rules {
            return trackerRules.map { contentBlockerRules(forTrackerRule: $0, withTrackerDomainExceptions: trackerExceptions) }.flatMap { $0 }
        } else {
            return contentBlockerRulesFromDomains(withTrackerDomainExceptions: trackerExceptions)
        }
    }
    
    private func contentBlockerRulesFromDomains(withTrackerDomainExceptions trackerExceptions: [String]) -> [ContentBlockerRule] {
        let domains = [domain] + (subdomains?.map { "\($0).\(domain)" } ?? [])
        
        return domains.map {
            let domain = $0.replacingOccurrences(of: ".", with: "\\.")
            let normalizedRule = "^https?://\(domain)/"
            return ContentBlockerRule(
                trigger: .trigger(urlFilter: normalizedRule, unlessDomain: trackerExceptions),
                action: .block())
        }
    }
    
    private func contentBlockerRules(forTrackerRule rule: KnownTracker.Rule,
                                     withTrackerDomainExceptions trackerExceptions: [String]) -> [ContentBlockerRule] {
        
        var rules = [ContentBlockerRule]()
        
        let ruleDomainExceptions = rule.exceptions?.domains ?? []
        
        let normalizedRule = "^https?://\(rule.rule)"
        
        rules.append(ContentBlockerRule(
            trigger: .trigger(urlFilter: normalizedRule, unlessDomain: trackerExceptions + ruleDomainExceptions),
            action: .block()))
        
        if let types = rule.exceptions?.types?.map({ $0 }) {

            let resourceTypes = types.compactMap { KnownTracker.resourceTypeMapping[$0] }
            
            if resourceTypes.count != types.count {
                NSLog("Unable to map all resource types in \(types)")
            }
            
            rules.append(ContentBlockerRule(
                trigger: .trigger(urlFilter: normalizedRule, resourceType: resourceTypes),
                action: .ignorePreviousRules()))

        }
        
        return rules
    }
    
}
