//
//  Extensions.swift
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

import Foundation
import TrackerRadarKit

extension TrackerData {

    init(trackers: [String: KnownTracker],
         entities: [String: Entity],
         domains: [String: String]) {
        self.init(trackers: trackers, entities: entities, domains: domains, cnames: nil)
    }

}

extension KnownTracker {

    static func build(domain: String,
                      defaultAction: ActionType = .block,
                      owner: Owner? = nil,
                      prevalence: Double = 1.0,
                      subdomains: [String]? = nil,
                      rules: [Rule]? = nil) -> Self {

        return Self.init(domain: domain, defaultAction: defaultAction, owner: owner, prevalence: prevalence, subdomains: subdomains, rules: rules)
    }

    static func build(domain: String? = nil,
                      defaultAction: ActionType? = nil,
                      owner: Owner? = nil,
                      prevalence: Double? = nil,
                      subdomains: [String]? = nil,
                      categories: [String]? = nil,
                      rules: [Rule]? = nil) -> KnownTracker {

        return KnownTracker(domain: domain,
                            defaultAction: defaultAction,
                            owner: owner,
                            prevalence: prevalence,
                            subdomains: subdomains,
                            categories: categories,
                            rules: rules)

    }

    init(domain: String?,
         defaultAction: KnownTracker.ActionType?,
         owner: KnownTracker.Owner?,
         prevalence: Double?,
         subdomains: [String]?,
         rules: [KnownTracker.Rule]?) {

        self.init(domain: domain,
                  defaultAction: defaultAction,
                  owner: owner,
                  prevalence: prevalence,
                  subdomains: subdomains,
                  categories: nil,
                  rules: rules)
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
