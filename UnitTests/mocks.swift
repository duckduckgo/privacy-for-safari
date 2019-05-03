//
//  mocks.swift
//  UnitTests
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
@testable import TrackerBlocking

class MockEntityManager: EntityManager {
    
    typealias ReturnValue = ((URL) -> Entity?)
    
    var returnValue: ReturnValue?
    
    init(returnValue: ReturnValue? = nil) {
        self.returnValue = returnValue
    }
    
    func entity(forUrl url: URL) -> Entity? {
        return returnValue?(url)
    }
    
}

class MockTrackerDetection: TrackerDetection {
    
    typealias ReturnValue = ((String, String, URL) -> DetectedTracker?)
    
    var returnValue: ReturnValue?
    
    init(returnValue: ReturnValue? = nil) {
        self.returnValue = returnValue
    }

    func detectTracker(forResource resource: String, ofType type: String, onPageWithUrl pageUrl: URL) -> DetectedTracker? {
        return returnValue?(resource, type, pageUrl)
    }
    
}

class MockKnownTrackersManager: KnownTrackersManager {
    
    typealias ReturnValue = ((URL) -> KnownTracker?)
    
    var returnValue: ReturnValue?
    
    init(returnValue: ReturnValue? = nil) {
        self.returnValue = returnValue
    }
    
    func findTracker(forUrl url: URL) -> KnownTracker? {
        return returnValue?(url)
    }
    
}

struct MockPrivacyPracticesManager: PrivacyPracticesManager {
    
    func findPrivacyPractice(forUrl: URL) -> PrivacyPractice {
        return DefaultPrivacyPracticesManager.Constants.unknown
    }
    
}

struct MockDependencies: TrackerBlockerDependencies {
    
    let entityManager: EntityManager
    let trackerDetection: TrackerDetection
    let knownTrackersManager: KnownTrackersManager
    let privacyPracticesManager: PrivacyPracticesManager
    
    init(entityManager: EntityManager = MockEntityManager(),
         trackerDetection: TrackerDetection = MockTrackerDetection(),
         knownTrackersManager: KnownTrackersManager = MockKnownTrackersManager(),
         privacyPracticesManager: PrivacyPracticesManager = MockPrivacyPracticesManager()) {
        
        self.entityManager = entityManager
        self.trackerDetection = trackerDetection
        self.knownTrackersManager = knownTrackersManager
        self.privacyPracticesManager = privacyPracticesManager
    }

}
