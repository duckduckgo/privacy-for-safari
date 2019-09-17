//
//  Settings.swift
//  DuckDuckGo Privacy Essentials
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

class Settings {
    
    struct Keys {
        static let firstRun  = "com.duckduckgo.macos.privacyessentials.firstRun"
        static let onboardingShown = "com.duckduckgo.macos.privacyessentials.onboardingShown"
    }
    
    private let userDefaults: UserDefaults
    
    public var firstRun: Bool {
        get {
            return (userDefaults.object(forKey: Keys.firstRun) as? Bool) ?? true
        }
        set(firtRun) {
            userDefaults.set(firtRun, forKey: Keys.firstRun)
        }
    }
    
    var onboardingShown: Bool {
        get {
            return userDefaults.bool(forKey: Keys.onboardingShown)
        }
        
        set {
            userDefaults.set(newValue, forKey: Keys.onboardingShown)
        }
    }
    
    init(userDefaults: UserDefaults = UserDefaults(suiteName: "com.duckduckgo.macos.app.Settings")!) {
        self.userDefaults = userDefaults
    }
    
}
