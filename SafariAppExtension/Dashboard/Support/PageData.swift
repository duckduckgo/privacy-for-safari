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
import TrackerBlocking
import TrackerRadarKit

typealias EntityName = String

public class PageData {

    struct DetectedRequest: Hashable {
        static func == (lhs: DetectedRequest, rhs: DetectedRequest) -> Bool {
            return lhs.domain == rhs.domain
        }

        let displayName: String
        let owner: String
        let domain: String
        let url: URL

        func hash(into hasher: inout Hasher) {
            hasher.combine(domain)
        }

    }

    let url: URL?
    let isTrusted: Bool
    let isBroken: Bool
    let trackerDataManager: TrackerDataManager
    
    var loadedTrackers = Set<DetectedTracker>()
    var blockedTrackers = Set<DetectedTracker>()
    var otherRequests = Set<DetectedRequest>()

    var hasBlockedTrackers: Bool {
        !blockedTrackers.isEmpty
    }

    var hasAnyThirdPartyRequests: Bool {
        !loadedTrackers.isEmpty || !otherRequests.isEmpty
    }

    var hasSpecialThirdPartyRequests: Bool {
        !loadedTrackers.isEmpty
    }

    var hasNonSpecialThirdPartyRequests: Bool {
        !otherRequests.isEmpty
    }

    var protectionsEnabled: Bool {
        !isTrusted
    }

    var isEncrypted: Bool {
        url?.isEncrypted == true
    }

    var entity: Entity? {
        if let url = url {
            return trackerDataManager.entity(forUrl: url)
        }
        return nil
    }

    private var grade: Grade?
    
    public init(url: URL? = nil, trackerDataManager: TrackerDataManager = TrackerBlocking.Dependencies.shared.trackerDataManager) {
        self.url = url
        self.trackerDataManager = trackerDataManager
        
        if let url = url {
            isTrusted = Dependencies.shared.trustedSitesManager.isTrusted(url: url)
            isBroken = Dependencies.shared.trustedSitesManager.unprotectedDomains().contains(url.host ?? "")
        } else {
            isTrusted = false
            isBroken = false
        }
    }

    public func calculateGrade() -> Grade.Scores {
        let privacyPractices = Dependencies.shared.privacyPracticesManager
        let trackerDataManager = Dependencies.shared.trackerDataManager
        
        let grade = Grade()
        
        blockedTrackers.forEach { tracker in
            let prevalence = trackerDataManager.entity(forName: tracker.owner ?? "")?.prevalence ?? tracker.prevalence
            grade.addEntityBlocked(named: tracker.owner ?? "", withPrevalence: prevalence)
        }

        loadedTrackers.forEach { tracker in
            let prevalence = trackerDataManager.entity(forName: tracker.owner ?? "")?.prevalence ?? tracker.prevalence
            grade.addEntityNotBlocked(named: tracker.owner ?? "", withPrevalence: prevalence)
        }

        if let url = url {
            // We don't perform manual https upgrades yet so all https sites are autoupgraded
            grade.httpsAutoUpgrade = url.scheme == "https"
            grade.privacyScore = privacyPractices.findPrivacyPractice(forUrl: url).score

            if let entity = trackerDataManager.entity(forUrl: url) {
                grade.setParentEntity(named: entity.displayName, withPrevalence: entity.prevalence)
            }
        }

        return grade.scores
    }
}
