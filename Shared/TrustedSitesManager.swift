//
//  TrustedSitesManager.swift
//  DuckDuckGo
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

class TrustedSitesManager {
    
    static let shared = TrustedSitesManager()
    
    static let updatedNotificationName = NSNotification.Name("com.duckduckgo.macos.TrustedSites.updated")
    
    struct Keys {
        static let domains = "domains"
    }
    
    private var domains = [String]()
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.duckduckgo.TrustedSites")
    }
    
    var count: Int {
        return domains.count
    }
    
    private init() {
        readFromUserDefaults()
    }
    
    func addDomain(_ domain: String) {
        domains.append(domain)
        saveToUserDefaults()
    }
    
    func allDomains() -> [String] {
        return domains
    }
     
    func clear() {
        domains = []
        saveToUserDefaults()
    }
    
    func removeSite(at index: Int) {
        guard index >= 0 else { return }
        domains.remove(at: index)
        saveToUserDefaults()
    }
    
    func readFromUserDefaults() {
        if let domains = userDefaults?.array(forKey: Keys.domains) as? [String] {
            self.domains = domains
        }
    }
    
    func saveToUserDefaults() {
        userDefaults?.set(domains, forKey: Keys.domains)
        DistributedNotificationCenter.default().postNotificationName(TrustedSitesManager.updatedNotificationName,
                                                                     object: nil,
                                                                     userInfo: nil,
                                                                     deliverImmediately: true)
    }
 
}
