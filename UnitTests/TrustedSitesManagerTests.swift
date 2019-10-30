//
//  TrackerBlockingTests.swift
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

class TrackerBlockingTests: XCTestCase {

    let testGroupName = "test"
    
    let blockerListManager = MockBlockerListManager()

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testGroupName)?.removePersistentDomain(forName: testGroupName)
    }
        
    func testDomainsReturnedFromUserDefaults() {
        let userDefaults = UserDefaults(suiteName: testGroupName)
        userDefaults?.set(["domain1", "domain2"], forKey: DefaultTrustedSitesManager.Keys.domains)
        
        let manager = DefaultTrustedSitesManager(blockerListManager: blockerListManagerFactory,
                                                 userDefaults: userDefaults)

        XCTAssertEqual(["domain1", "domain2"], manager.allDomains())
    }
    
    func testWhenDomainAddedThenSavedToUserDefaults() {
        let userDefaults = UserDefaults(suiteName: testGroupName)
        let manager = DefaultTrustedSitesManager(blockerListManager: blockerListManagerFactory,
                                                 userDefaults: userDefaults)
        manager.addDomain("test1")
        
        XCTAssertEqual(["test1"], manager.allDomains())
        XCTAssertEqual(["test1"], userDefaults?.value(forKey: DefaultTrustedSitesManager.Keys.domains) as? [String])
    }
    
    func testWhitelistReadFromUrl() throws {
        
        let tempWhitelistLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        let domains = ["domain1", "domain2"].joined(separator: "\n")
        guard FileManager.default.createFile(atPath: tempWhitelistLocation.path, contents: domains.data(using: .utf8), attributes: nil) else {
            XCTFail("Failed to write to \(tempWhitelistLocation.path)")
            return
        }
        
        let manager = DefaultTrustedSitesManager(blockerListManager: blockerListManagerFactory,
                                                 tempWhitelistUrl: tempWhitelistLocation)

        XCTAssertEqual(["domain1", "domain2"], manager.whitelistedDomains())
        
    }
    
    func blockerListManagerFactory() -> BlockerListManager {
        return blockerListManager
    }
    
}
