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
import os

public struct TrustedSitesNotification {
    public static let sitesUpdatedNotificationName = NSNotification.Name("com.duckduckgo.macos.TrustedSites.updated")
}

public protocol TrustedSitesManager {
    
    typealias Factory = (() -> TrustedSitesManager)

    var count: Int { get }
    var lastChangedDomain: String? { get }
    func addDomain(_ domain: String)
    func addDomain(forUrl url: URL)
    func allDomains() -> [String]
    func unprotectedDomains() -> [String]
    func removeDomain(at index: Int)
    func removeDomain(forUrl url: URL)
    func isTrusted(url: URL) -> Bool

}

public class DefaultTrustedSitesManager: TrustedSitesManager {

    struct Keys {
        static let domains = "domains"
        static let lastChangedDomain = "lastChangedDomain"
    }

    private let lock = NSLock()

    private var domains: [String] {
        get {
            return userDefaults?.array(forKey: Keys.domains) as? [String] ?? []
        }
        set {
            userDefaults?.set(newValue, forKey: Keys.domains)
        }
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return domains.count
    }

    private(set) public var lastChangedDomain: String? {
        get {
            return userDefaults?.string(forKey: Keys.lastChangedDomain)
        }
        set {
            userDefaults?.set(newValue, forKey: Keys.lastChangedDomain)
        }
    }
    
    private let blockerListManager: BlockerListManager.Factory
    private let userDefaults: UserDefaults?
    private let tempUnprotectedSitesUrl: URL

    public init(blockerListManager: @escaping BlockerListManager.Factory,
                userDefaults: UserDefaults? = UserDefaults(suiteName: TempUnprotectedSitesDataLocation.groupName),
                tempUnprotectedSitesUrl: URL = TempUnprotectedSitesDataLocation.dataUrl) {
        
        self.blockerListManager = blockerListManager
        self.userDefaults = userDefaults
        self.tempUnprotectedSitesUrl = tempUnprotectedSitesUrl
    }
    
    public func addDomain(_ domain: String) {
        lock.lock()
        domains.append(domain)
        lastChangedDomain = domain
        lock.unlock()

        postSitesUpdatedNotification()
    }
    
    public func isTrusted(url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let host = url.host else { return false }
        return domains.contains(host)
    }
    
    public func allDomains() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return domains
    }
    
    public func unprotectedDomains() -> [String] {
        guard let unprotectedDomains = try? String(contentsOf: tempUnprotectedSitesUrl) else {
            os_log("Failed to load temporary unprotected domains from %{public}s", log: generalLog, tempUnprotectedSitesUrl.absoluteString)
            return []
        }

        return unprotectedDomains.components(separatedBy: "\n").compactMap {
            let trimmed = $0.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        }
    }
    
    public func removeDomain(at index: Int) {
        guard index >= 0 else { return }
        lock.lock()
        let removedDomain = domains.remove(at: index)
        lastChangedDomain = removedDomain
        lock.unlock()

        postSitesUpdatedNotification()
    }
    
    public func removeDomain(forUrl url: URL) {
        guard let host = url.host else { return }
        lock.lock()
        domains.removeAll { host == $0 }
        lastChangedDomain = host
        lock.unlock()

        postSitesUpdatedNotification()
    }
    
    public func addDomain(forUrl url: URL) {
        guard let host = url.host else { return }
        addDomain(host)
    }

    private func postSitesUpdatedNotification() {

        Task {
            await blockerListManager().update()
            try await ContentBlockerExtension.reload()
            DistributedNotificationCenter.default().postNotificationName(TrustedSitesNotification.sitesUpdatedNotificationName,
                                                                         object: nil,
                                                                         userInfo: nil,
                                                                         deliverImmediately: true)
        }
        
    }
 
}

public struct TempUnprotectedSitesDataLocation {
    
    public static var groupName = "group.com.duckduckgo.TrustedSites"
    
    public static var dataUrl: URL {
        return containerUrl.appendingPathComponent("temporary-unprotected-sites").appendingPathExtension("txt")
    }
    
    static private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
    }
    
}
