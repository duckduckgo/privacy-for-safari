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
import os

public struct TrackerData: Codable {
    
    public struct TrackerRules {
        
        let tracker: KnownTracker
        let rules: [ContentBlockerRule]
        
    }
    
    public let trackers: [KnownTracker]
    public let entities: [Entity]
    
    public init(trackers: [KnownTracker], entities: [Entity]) {
        self.trackers = trackers
        self.entities = entities
    }

    public func contentBlockerRules() -> [TrackerRules] {
        let entities = entitiesByName()
        return trackers.compactMap { tracker -> TrackerRules? in
            guard let rules = tracker.contentBlockerRules(entitiesByName: entities) else { return nil }
            return TrackerRules(tracker: tracker, rules: rules)
        }
    }

    public func trackersByRegex() -> [NSRegularExpression: KnownTracker] {
        var trackers = [NSRegularExpression: KnownTracker]()
        contentBlockerRules().forEach { trackerRules in
            trackerRules.rules.forEach { rule in
                do {
                    trackers[try NSRegularExpression(pattern: rule.trigger.urlFilter, options: [])] = trackerRules.tracker
                } catch {
                    os_log("Failed to compile regex %{public}s %{public}s", type: .error, rule.trigger.urlFilter, error.localizedDescription)
                }
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
            let normalizedRule = normalizeRule(rule: "\(domain)/")
            return ContentBlockerRule(
                trigger: .trigger(urlFilter: normalizedRule, unlessDomain: trackerExceptions),
                action: .block())
        }
    }
    
    private func contentBlockerRules(forTrackerRule rule: KnownTracker.Rule,
                                     withTrackerDomainExceptions trackerExceptions: [String]) -> [ContentBlockerRule] {
        
        var rules = [ContentBlockerRule]()
        
        let ruleDomainExceptions = rule.exceptions?.domains ?? []
        
        let normalizedRule = normalizeRule(rule: rule.rule)
        
        rules.append(ContentBlockerRule(
            trigger: .trigger(urlFilter: normalizedRule, unlessDomain: trackerExceptions + ruleDomainExceptions),
            action: .block()))
        
        if let types = rule.exceptions?.types?.map({ $0 }) {

            let resourceTypes = types.compactMap { KnownTracker.resourceTypeMapping[$0] }
            
            if resourceTypes.count != types.count {
                os_log("Unable to map all resource types in %{public}s", type: .error, String(describing: types))
            }
            
            rules.append(ContentBlockerRule(
                trigger: .trigger(urlFilter: normalizedRule, resourceType: resourceTypes),
                action: .ignorePreviousRules()))

        }
        
        return rules
    }
    
    private func normalizeRule(rule: String) -> String {
        return "^https?://(.*[.])*" + rule
    }
    
}
