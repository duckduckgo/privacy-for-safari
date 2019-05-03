//
//  PageData.swift
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

import Foundation

public struct PageData {

    public typealias Resources = [String: Int]
    public typealias Entities = [String: Resources]

    public let url: URL?
    public let blockedEntities: Entities
    public let notBlockedEntities: Entities

    public var notBlockedTrackerCount: Int {
        return notBlockedEntities.reduce(0, countTrackers)
    }

    public var blockedTrackerCount: Int {
        return blockedEntities.reduce(0, countTrackers)
    }

    public init(url: URL? = nil, blockedEntities: Entities = [:], notBlockedEntities: Entities = [:]) {
        self.url = url
        self.blockedEntities = blockedEntities
        self.notBlockedEntities = notBlockedEntities
    }

    public func updateEntities(blocked: Entities, notBlocked: Entities) -> PageData {
        let blockedEntities = update(self.blockedEntities, withEntities: blocked)
        let notBlockedEntities = update(self.notBlockedEntities, withEntities: notBlocked)
        return PageData(url: self.url, blockedEntities: blockedEntities, notBlockedEntities: notBlockedEntities)
    }

    public func calculateGrade() -> Grade.Scores {
        let privacyPractices = Dependencies.shared.privacyPracticesManager
        let entityManager = Dependencies.shared.entityManager
        
        let grade = Grade()
        
        blockedEntities.forEach {
            grade.addEntityBlocked(named: $0.key, withPrevalence: 1)
        }

        notBlockedEntities.forEach {
            grade.addEntityNotBlocked(named: $0.key, withPrevalence: 1)
        }

        if let url = url {
            grade.https = url.scheme == "https"
            grade.privacyScore = privacyPractices.findPrivacyPractice(forUrl: url).score
            
            let entity = entityManager.entity(forUrl: url)
            grade.setParentEntity(named: entity?.name, withPrevalence: entity?.prevalence)
        }
        
        return grade.scores
    }

    private func merge(resources: Resources, intoExisting existing: Resources) -> Resources {
        var updated = existing
        resources.forEach {
            updated[$0.key, default: 0] += $0.value
        }
        return updated
    }

    private func countTrackers(initialValue: Int, next: (key: String, value: Resources)) -> Int {
        return initialValue + next.value.reduce(0, { $0 + $1.value })
    }

    private func update(_ entities: Entities, withEntities newEntities: Entities) -> Entities {
        var updated = entities
        newEntities.forEach {
            let entity = $0
            $1.forEach {
                updated[entity, default: [:]][$0, default: 0] += $1
            }
        }
        return updated
    }

}
