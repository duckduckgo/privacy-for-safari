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

// swiftlint:disable identifier_name
public let TrustedSitesManagerUpdatedNotificationName = NSNotification.Name("com.duckduckgo.macos.TrustedSites.updated")
// swiftlint:enable identifier_name

public protocol TrustedSitesManager {

    var count: Int { get }
    func addDomain(_ domain: String)
    func allDomains() -> [String]
    func clear()
    func removeDomain(at index: Int)
    func load()
    func save()
    func isTrusted(url: URL) -> Bool

}

public class DefaultTrustedSitesManager: TrustedSitesManager {
 
    struct Keys {
        static let domains = "domains"
    }
    
    private var domains = [String]()
    
    private let userDefaults: UserDefaults?
    
    public var count: Int {
        return domains.count
    }
    
    public init(userDefaults: UserDefaults? = UserDefaults(suiteName: "group.com.duckduckgo.TrustedSites")) {
        self.userDefaults = userDefaults
        load()
    }
    
    public func addDomain(_ domain: String) {
        domains.append(domain)
        save()
    }
    
    public func isTrusted(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return domains.contains(host)
    }
    
    public func allDomains() -> [String] {
        return domains
    }
     
    public func clear() {
        domains = []
        save()
    }
    
    public func removeDomain(at index: Int) {
        guard index >= 0 else { return }
        domains.remove(at: index)
        save()
    }
    
    public func load() {
        if let domains = userDefaults?.array(forKey: Keys.domains) as? [String] {
            self.domains = domains
        }
    }
    
    public func save() {
        userDefaults?.set(domains, forKey: Keys.domains)
        
        Dependencies.shared.blockerListManager.update {
            Dependencies.shared.blockerListManager.reloadExtension()
        }

        DistributedNotificationCenter.default().postNotificationName(TrustedSitesManagerUpdatedNotificationName,
                                                                     object: nil,
                                                                     userInfo: nil,
                                                                     deliverImmediately: true)
    }
 
}
