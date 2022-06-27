//
//  SettingUserDefaultsTests.swift
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

import XCTest
@testable import DuckDuckGo_Privacy_for_Safari

class SettingsTests: XCTestCase {
    
    let testGroupName = "test"
    
    override func setUp() {
        UserDefaults(suiteName: testGroupName)?.removePersistentDomain(forName: testGroupName)
    }
    
    func testWhenInitializedThenFirstRunTIsTrue() {
        let userDefaults = Settings(userDefaults: UserDefaults(suiteName: testGroupName)!)
        XCTAssertTrue(userDefaults.firstRun)
    }
    
    func testWhenFirstRunSetThenItIsPersisted() {
        let userDefaults = Settings(userDefaults: UserDefaults(suiteName: testGroupName)!)
        userDefaults.firstRun = false
        XCTAssertFalse(userDefaults.firstRun)
    }
    
    func testWhenInitializedThenOnboardingShownIsFalse() {
        let userDefaults = Settings(userDefaults: UserDefaults(suiteName: testGroupName)!)
        XCTAssertFalse(userDefaults.onboardingShown)
    }
    
    func testWhenOnboardingShownIsSetThenItIsPersisted() {
        let userDefaults = Settings(userDefaults: UserDefaults(suiteName: testGroupName)!)
        userDefaults.onboardingShown = true
        XCTAssertTrue(userDefaults.onboardingShown)
    }
}
