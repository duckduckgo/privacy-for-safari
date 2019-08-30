//
//  Settings.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Chris Brind on 05/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

class Settings {
    
    struct Keys {
        static let onboardingShown = "onboardingShown"
    }
    
    private let userDefaults: UserDefaults
    
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
