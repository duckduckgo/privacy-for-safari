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

public class PageData {

    public struct EntityTrackers {

        public let entityName: String
        public let trackers: [String]

    }

    public let url: URL?
    public let isTrusted: Bool
    
    public var loadedTrackers = [DetectedTracker]()
    public var blockedTrackers = [DetectedTracker]()

    private var grade: Grade?
    
    public init(url: URL? = nil) {
        NSLog("PageData.init \(url?.absoluteString ?? "<no url>")")
        self.url = url
        
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
            grade.addEntityBlocked(named: tracker.owner ?? "", withPrevalence: tracker.prevalence)
        }

        loadedTrackers.forEach { tracker in
            grade.addEntityNotBlocked(named: tracker.owner ?? "", withPrevalence: tracker.prevalence)
        }

        if let url = url {
            grade.https = url.scheme == "https"
            grade.privacyScore = privacyPractices.findPrivacyPractice(forUrl: url).score
            
            let entity = trackerDataManager.entity(forUrl: url)
            grade.setParentEntity(named: entity?.displayName, withPrevalence: entity?.prevalence)
        }

        NSLog("Setting grade to \(grade.scores.site) vs \(grade.scores.site)")
        return grade.scores
    }

    private func trackersByEntity(trackers: [DetectedTracker]) -> [EntityTrackers] {
        return trackers.reduce([:]) { result, tracker -> [String: Set<String>] in
            let owner = tracker.owner ?? "Unknown"
            let domain = tracker.resource.host?.dropPrefix("www.") ?? "Unknown"
            
            var trackers = result[owner, default: Set<String>()]
            trackers.insert(domain)
            
            var newResult = result
            newResult[owner] = trackers
            return newResult
        }.mapValues { $0.sorted() }.map {
            EntityTrackers(entityName: $0.key, trackers: $0.value)
        }.sorted {
            $0.entityName < $1.entityName
        }
    }
    
}
