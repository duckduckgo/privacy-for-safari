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

    var matchedTracker: KnownTracker?

    func detectTrackerFor(resourceUrl: URL,
                          onPageWithUrl pageUrl: URL,
                          asResourceType resourceType: String?) -> DetectedTracker? {
        return nil
    }

    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker {
        return DetectedTracker(matchedTracker: matchedTracker,
                               resource: resourceUrl,
                               page: pageUrl,
                               owner: nil,
                               prevalence: 1.0,
                               isFirstParty: false,
                               action: .block)
    }
}

struct MockPrivacyPracticesManager: PrivacyPracticesManager {
    
    func findPrivacyPractice(forUrl: URL) -> PrivacyPractice {
        return DefaultPrivacyPracticesManager.Constants.unknown
    }
    
}

struct MockTrustedSitesManager: TrustedSitesManager {

    var count: Int = 0

    var lastChangedDomain: String?

    // swiftlint:disable identifier_name
    var _unprotectedDomains = [String]()
    // swiftlint:enable identifier_name

    func addDomain(_ domain: String) {
     
    }
    
    func addDomain(forUrl url: URL) {
     
    }
    
    func allDomains() -> [String] {
        return []
    }
    
    func unprotectedDomains() -> [String] {
        return _unprotectedDomains
    }
    
    func clear() {
     
    }
    
    func removeDomain(at index: Int) {
     
    }
    
    func removeDomain(forUrl url: URL) {
     
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

    var trackerData: TrackerData?

    private var returnEntities: [Entity]
    private var returnTracker: KnownTracker?
    
    init(returnEntities entities: [Entity] = [Entity](), returnTracker tracker: KnownTracker? = nil) {
        returnEntities = entities
        returnTracker = tracker
    }
    
    func load() {
    }

    func forEachEntity(_ result: (Entity) -> Void) {
    }

    func forEachTracker(_ result: (KnownTracker) -> Void) {
    }

    func entity(forUrl url: URL) -> Entity? {
        return returnEntities.first
    }
    
    func entity(forName name: String) -> Entity? {
        return returnEntities.first { $0.displayName == name }
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
    
    func update() { }
    func needsReload() { }
    
}

class MockAPIRequest: APIRequest {
    
    struct Response {
        
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
        
    }
    
    struct Request {
        let method: HttpMethod
        let path: String
        let params: [String: String]?
    }
    
    let dummyUrl = URL(string: "http://www.example.com")!
    
    private var responses = [Response]()
    var requests = [Request]()
    
    func get(_ path: String, withParams params: [String: String]?, completion: @escaping ((Data?, HTTPURLResponse?, Error?) -> Void)) {
        requests.append(Request(method: .get, path: path, params: params))
        guard responses.count > 0 else { return }
        let response = responses.remove(at: 0)
        completion(response.data, response.response, response.error)
    }
    
    func post(_ path: String, withParams params: [String: String]?, completion: @escaping ((Data?, HTTPURLResponse?, Error?) -> Void)) {
        requests.append(Request(method: .post, path: path, params: params))
        guard responses.count > 0 else { return }
        let response = responses.remove(at: 0)
        completion(response.data, response.response, response.error)
    }
    
    func addResponse(_ statusCode: Int, body: String? = nil, error: Error? = nil) {
        let httpResponse = HTTPURLResponse(url: dummyUrl, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        let data: Data? = body?.data(using: .utf8)
        responses.append(Response(data: data, response: httpResponse, error: error))
    }
    
}

class MockStatisticsStore: StatisticsStore {
    
    var installDate: Date?
    
    var installAtb: String?
    
    var searchRetentionAtb: String?
    
    var appRetentionAtb: String?
    
    var browserVersion: String?
    
}

class MockPixel: Pixel {
    
    var pixels = [(name: PixelName, params: [String: String]?)]()
    
    func fire(_ pixel: PixelName, withParams params: [String: String], onComplete: @escaping PixelCompletion) {
        pixels.append((name: pixel, params: params))
        onComplete(nil)
    }
}

class MockStatisticsDependencies: StatisticsDependencies {
    
    var pixel: Pixel
    
    var statisticsStore: StatisticsStore
    
    init(statisticsStore: StatisticsStore = DefaultStatisticsStore()) {
        self.statisticsStore = statisticsStore
        self.pixel = DefaultPixel(statisticsStore: statisticsStore, apiRequest: { MockAPIRequest() })
    }
}

struct MockTrackerDataServiceStore: TrackerDataServiceStore {
    
    var etag: String?

}

class MockBundle: InfoBundle {
    
    private var mockEntries = [String: Any]()
    
    func object(forInfoDictionaryKey key: String) -> Any? {
        return mockEntries[key]
    }
    
    func add(name: String, value: Any) {
        mockEntries[name] = value
    }
}

struct MockAppVersion: AppVersion {
    var name: String = ""
    var identifier: String = ""
    var versionNumber: String = ""
    var buildNumber: String = ""
}

struct MockError: Error {}

class MockStatisticsLoader: StatisticsLoader {
    
    var refreshSearchRetentionAtbFired = false
    var refreshAppRetentionAtbFired = false
    
    func refreshSearchRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        refreshSearchRetentionAtbFired = true
        completion?()
    }
    
    func refreshAppRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        refreshAppRetentionAtbFired = true
        completion?()
    }
}
