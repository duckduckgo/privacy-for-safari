//
//  BlockerListManagerTests.swift
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

import XCTest
@testable import TrackerBlocking

class BlockerListManagerTests: XCTestCase {
    
    struct Constants {
        static let suiteName = "test"
    }
    
    var trackerDataManager = MockTrackerDataManager()
    var trustedSitesManager = MockTrustedSitesManager()
    
    override func setUp() {
        super.setUp()
        
        UserDefaults(suiteName: Constants.suiteName)?.removePersistentDomain(forName: Constants.suiteName)
    }
    
    func testWhenSetNeedsReloadCalledThenStatePersisted() {
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        var manager = DefaultBlockerListManager(trackerDataManager: trackerDataManagerFactory,
                                  trustedSitesManager: trustedSitesManagerFactory,
                                  blockerListUrl: url,
                                  userDefaults: UserDefaults(suiteName: Constants.suiteName))

        XCTAssertFalse(manager.needsReload)
        manager.setNeedsReload(true)
        
        manager = DefaultBlockerListManager(trackerDataManager: trackerDataManagerFactory,
                                  trustedSitesManager: trustedSitesManagerFactory,
                                  blockerListUrl: url,
                                  userDefaults: UserDefaults(suiteName: Constants.suiteName))
        XCTAssertTrue(manager.needsReload)
    }
    
    func testWhenWhitelistedDomainsArePresentThenGeneratedRulesContainThem() {
        
        let trackers = [
            "Google": KnownTracker(domain: "google.com", defaultAction: .block, owner: nil, prevalence: nil, subdomains: nil, rules: nil)
        ]
        
        trustedSitesManager._whitelistedDomains = ["domain1", "domain2"]
        trackerDataManager.trackerData = TrackerData(trackers: trackers, entities: [:], domains: [:])
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")

        let manager = DefaultBlockerListManager(trackerDataManager: trackerDataManagerFactory,
                                  trustedSitesManager: trustedSitesManagerFactory,
                                  blockerListUrl: url,
                                  userDefaults: UserDefaults(suiteName: Constants.suiteName))
        
        manager.update()
        
        guard let data = try? Data(contentsOf: url) else {
            XCTFail("Failed to load \(url.path)")
            return
        }
        
        guard let rules = try? JSONDecoder().decode([ContentBlockerRule].self, from: data) else {
            XCTFail("Failed to decode \(url.path)")
            return
        }
        
        XCTAssertEqual(3, rules.count)
        XCTAssertEqual(rules[0].action.type, .block)
        XCTAssertEqual(rules[1].action.type, .ignorePreviousRules)
        XCTAssertEqual(rules[1].trigger.ifDomain, ["*domain1", "*domain2"])
        XCTAssertEqual(rules[2].action.type, .cssDisplayNone)
    }
    
    func trackerDataManagerFactory() -> TrackerDataManager {
        return trackerDataManager
    }
    
    func trustedSitesManagerFactory() -> TrustedSitesManager {
        return trustedSitesManager
    }
    
}
