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

public struct TrustedSitesNotification {
    public static let sitesUpdatedNotificationName = NSNotification.Name("com.duckduckgo.macos.TrustedSites.updated")
}

public protocol TrustedSitesManager {
    
    typealias Factory = (() -> TrustedSitesManager)

    var count: Int { get }
    func addDomain(_ domain: String)
    func addDomain(forUrl url: URL)
    func allDomains() -> [String]
    func whitelistedDomains() -> [String]
    func clear()
    func removeDomain(at index: Int)
    func removeDomain(forUrl url: URL)
    func load()
    func save()
    func isTrusted(url: URL) -> Bool

}

public class DefaultTrustedSitesManager: TrustedSitesManager {

    struct Keys {
        static let domains = "domains"
    }
    
    private var domains = [String]()
    private var tempWhitelist = [String]()
    
    public var count: Int {
        return domains.count
    }
    
    private let blockerListManager: BlockerListManager.Factory
    private let userDefaults: UserDefaults?
    private let tempWhitelistUrl: URL

    public init(blockerListManager: @escaping BlockerListManager.Factory,
                userDefaults: UserDefaults? = UserDefaults(suiteName: TempWhitelistDataLocation.groupName),
                tempWhitelistUrl: URL = TempWhitelistDataLocation.dataUrl) {
        
        self.blockerListManager = blockerListManager
        self.userDefaults = userDefaults
        self.tempWhitelistUrl = tempWhitelistUrl
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
    
    public func whitelistedDomains() -> [String] {
        return tempWhitelist
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
    
    public func removeDomain(forUrl url: URL) {
        guard let host = url.host else { return }
        domains.removeAll { host == $0 }
    }
    
    public func addDomain(forUrl url: URL) {
        guard let host = url.host else { return }
        addDomain(host)
    }
    
    public func load() {
        if let domains = userDefaults?.array(forKey: Keys.domains) as? [String] {
            self.domains = domains
        }
        
        loadTemporaryWhitelist()
    }
    
    private func loadTemporaryWhitelist() {
        
        tempWhitelist = [String]()
        guard let whitelist = try? String(contentsOf: tempWhitelistUrl) else {
            return
        }

        tempWhitelist = whitelist.components(separatedBy: "\n").compactMap({
            let trimmed = $0.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        })
    }
    
    public func save() {
        userDefaults?.set(domains, forKey: Keys.domains)
        
        blockerListManager().updateAndReload()
        
        DistributedNotificationCenter.default().postNotificationName(TrustedSitesNotification.sitesUpdatedNotificationName,
                                                                     object: nil,
                                                                     userInfo: nil,
                                                                     deliverImmediately: true)

    }
 
}

public struct TempWhitelistDataLocation {
    
    public static var groupName = "group.com.duckduckgo.TrustedSites"
    
    public static var dataUrl: URL {
        return containerUrl.appendingPathComponent("temporary-whitelist").appendingPathExtension("txt")
    }
    
    static private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
    }
    
}
