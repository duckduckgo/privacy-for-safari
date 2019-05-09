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

class MockTrackerDetection: TrackerDetection {

    func detectTracker(forResource resource: String, ofType type: String, onPageWithUrl pageUrl: URL) -> DetectedTracker? {
        return nil
    }
    
}

struct MockPrivacyPracticesManager: PrivacyPracticesManager {
    
    func findPrivacyPractice(forUrl: URL) -> PrivacyPractice {
        return DefaultPrivacyPracticesManager.Constants.unknown
    }
    
}

struct MockTrustedSitesManager: TrustedSitesManager {

    var count: Int {
        return 0
    }

    func addDomain(_ domain: String) {
    }

    func allDomains() -> [String] {
        return []
    }

    func clear() {
    }

    func removeDomain(at index: Int) {
    }

    func load() {
    }

    func save() {
    }
    
    func isTrusted(url: URL) -> Bool {
        return false
    }

}

class MockTrackerDataManager: TrackerDataManager {

    private var returnEntity: Entity?
    private var returnTracker: KnownTracker?

    init(returnEntity entity: Entity? = nil, returnTracker tracker: KnownTracker? = nil) {
        returnEntity = entity
        returnTracker = tracker
    }

    func load() {
    }

    func forEachEntity(_ result: (Entity) -> Void) {
    }

    func forEachTracker(_ result: (KnownTracker) -> Void) {
    }

    func contentBlockerRules(withTrustedSites: [String]) -> [ContentBlockerRule] {
        return []
    }

    func entity(forUrl url: URL) -> Entity? {
        return returnEntity
    }

    func knownTracker(forUrl url: URL) -> KnownTracker? {
        return returnTracker
    }

    func update(completion: () -> Void) {
        completion()
    }
    
}

class MockBlockerListManager: BlockerListManager {
    
    var blockerListUrl: URL { return URL(fileURLWithPath: "blockerList.json") }
    
    func update(completion: () -> Void) {
        completion()
    }
    
    func reloadExtension() {
    }
    
}

struct MockDependencies: TrackerBlockerDependencies {

    let trustedSitesManager: TrustedSitesManager
    let trackerDetection: TrackerDetection
    let privacyPracticesManager: PrivacyPracticesManager
    let trackerDataManager: TrackerDataManager
    let blockerListManager: BlockerListManager
    
    init(trustedSitesManager: TrustedSitesManager = MockTrustedSitesManager(),
         trackerDetection: TrackerDetection = MockTrackerDetection(),
         privacyPracticesManager: PrivacyPracticesManager = MockPrivacyPracticesManager(),
         trackerDataManager: TrackerDataManager = MockTrackerDataManager(),
         blockerListManager: BlockerListManager = MockBlockerListManager()) {

        self.trustedSitesManager = trustedSitesManager
        self.trackerDetection = trackerDetection
        self.privacyPracticesManager = privacyPracticesManager
        self.trackerDataManager = trackerDataManager
        self.blockerListManager = blockerListManager
    }

}
