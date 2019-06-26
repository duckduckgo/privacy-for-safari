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
@testable import Core
@testable import TrackerBlocking
@testable import Statistics

class MockTrackerDetection: TrackerDetection {
    func detectTrackerFor(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker? {
        return nil
    }
    
    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker {
        return DetectedTracker(resource: resourceUrl, page: pageUrl, owner: nil, prevalence: 1.0, isFirstParty: false)
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

    func entity(forUrl url: URL) -> Entity? {
        return returnEntity
    }

    func knownTracker(forUrl url: URL) -> KnownTracker? {
        return returnTracker
    }

    func update(completion: () -> Void) {
        completion()
    }
    
    func contentBlockerRules() -> [TrackerData.TrackerRules] {
        return []
    }
    
    func rule(forTrustedSites trustedSites: [String]) -> ContentBlockerRule? {
        return nil
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

struct MockTrackerBlockingDependencies: TrackerBlockingDependencies {

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

class MockAPIRequest: APIRequest {
    
    struct Response {
        
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
        
    }
    
    struct Get {
        
        let path: String
        let params: [String: String]?
        
    }
    
    let dummyUrl = URL(string: "http://www.example.com")!
    
    private var responses = [Response]()
    var requests = [Get]()
    
    func get(_ path: String, withParams params: [String: String]?, completion: @escaping ((Data?, HTTPURLResponse?, Error?) -> Void)) {
        requests.append(Get(path: path, params: params))
        guard responses.count > 0 else { return }
        let response = responses.remove(at: 0)
        completion(response.data, response.response, response.error)
    }
    
    func addResponse(_ statusCode: Int, body: String? = nil) {
        let httpResponse = HTTPURLResponse(url: dummyUrl, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        let data: Data? = body?.data(using: .utf8)
        responses.append(Response(data: data, response: httpResponse, error: nil))
    }
    
}

class MockStatisticsStore: StatisticsStore {
    
    var installDate: Date?
    
    var installAtb: String?
    
    var searchRetentionAtb: String?
    
    var appRetentionAtb: String?
    
}

class MockStatisticsDependencies: StatisticsDependencies {
    
    var statisticsLoader: StatisticsLoader
    
    var statisticsStore: StatisticsStore
    
    init(statisticsStore: StatisticsStore = DefaultStatisticsStore(), statisticsLoader: StatisticsLoader = DefaultStatisticsLoader()) {
        self.statisticsStore = statisticsStore
        self.statisticsLoader = statisticsLoader
    }
    
}
