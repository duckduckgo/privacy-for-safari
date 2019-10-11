//
//  PageData.swift
//  TrackerBlocking
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

typealias EntityName = String

public class PageData {
        
    public struct EntityTrackers {

        public let entityName: String
        public let prevalence: Double
        public let trackers: [String]

    }

    public let url: URL?
    public let isTrusted: Bool
    public let trackerDataManager: TrackerDataManager
    
    public var loadedTrackers = [DetectedTracker]()
    public var blockedTrackers = [DetectedTracker]()

    private var grade: Grade?
    
    public init(url: URL? = nil, trackerDataManager: TrackerDataManager = TrackerBlocking.Dependencies.shared.trackerDataManager) {
        self.url = url
        self.trackerDataManager = trackerDataManager
        
        if let url = url {
            isTrusted = Dependencies.shared.trustedSitesManager.isTrusted(url: url)
        } else {
            isTrusted = false
        }
    }
    
    public func blockedTrackersByEntity() -> [PageData.EntityTrackers] {
        return trackersByEntity(trackers: blockedTrackers)
    }

    public func loadedTrackersByEntity() -> [PageData.EntityTrackers] {
        return trackersByEntity(trackers: loadedTrackers)
    }

    public func calculateGrade() -> Grade.Scores {
        let privacyPractices = Dependencies.shared.privacyPracticesManager
        let trackerDataManager = Dependencies.shared.trackerDataManager
        
        let grade = Grade()
        
        blockedTrackers.forEach { tracker in
            let prevalence = trackerDataManager.entity(forName: tracker.owner ?? "")?.prevalence ?? 0
            grade.addEntityBlocked(named: tracker.owner ?? "", withPrevalence: prevalence)
        }

        loadedTrackers.forEach { tracker in
            let prevalence = trackerDataManager.entity(forName: tracker.owner ?? "")?.prevalence ?? 0
            grade.addEntityNotBlocked(named: tracker.owner ?? "", withPrevalence: prevalence)
        }

        if let url = url {
            // We don't perform manual https upgrades yet so all https sites are autoupgraded
            grade.httpsAutoUpgrade = url.scheme == "https"
            grade.privacyScore = privacyPractices.findPrivacyPractice(forUrl: url).score
            
            let entity = trackerDataManager.entity(forUrl: url)
            grade.setParentEntity(named: entity?.displayName, withPrevalence: entity?.prevalence)
        }

        return grade.scores
    }

    private func trackersByEntity(trackers: [DetectedTracker]) -> [EntityTrackers] {
        return trackers.reduce([:]) { result, tracker -> [EntityName: Set<String>] in
            let owner = tracker.owner ?? "Unknown"
            let domain = tracker.resource.host?.dropPrefix("www.") ?? "Unknown"
            
            var trackers = result[owner, default: Set<String>()]
            trackers.insert(domain)
            
            var newResult = result
            newResult[owner] = trackers
            return newResult
            
        }.mapValues { $0.sorted() }.map {
            let entity = trackerDataManager.entity(forName: $0.key)
            return EntityTrackers(entityName: $0.key, prevalence: entity?.prevalence ?? 0.0, trackers: $0.value)
        }.sorted {
            $0.prevalence > $1.prevalence
        }
    }
}
