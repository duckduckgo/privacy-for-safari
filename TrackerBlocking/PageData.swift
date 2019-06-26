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

    public let url: URL?
    public var loadedTrackers = [DetectedTracker]() {
        didSet {
            grade = nil
        }
    }
    public var blockedTrackers = [DetectedTracker]() {
        didSet {
            grade = nil
        }
    }

    private var grade: Grade?
    
    public init(url: URL? = nil) {
        self.url = url
    }

    public func calculateGrade() -> Grade.Scores {
        if let grade = grade {
            return grade.scores
        }
        
        let privacyPractices = Dependencies.shared.privacyPracticesManager
        let trackerDataManager = Dependencies.shared.trackerDataManager
        
        let grade = Grade()
        
        blockedTrackers.forEach { tracker in
            grade.addEntityBlocked(named: tracker.owner ?? "", withPrevalence: tracker.prevalence)
        }

        loadedTrackers.forEach { tracker in
            grade.addEntityBlocked(named: tracker.owner ?? "", withPrevalence: tracker.prevalence)
        }

        if let url = url {
            grade.https = url.scheme == "https"
            grade.privacyScore = privacyPractices.findPrivacyPractice(forUrl: url).score
            
            let entity = trackerDataManager.entity(forUrl: url)
            grade.setParentEntity(named: entity?.name, withPrevalence: entity?.prevalence)
        }

        self.grade = grade
        return grade.scores
    }

}
