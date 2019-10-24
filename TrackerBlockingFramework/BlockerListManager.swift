//
//  BlockerList.swift
//  TrackerBlocking
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
import SafariServices
import os
import WebKit

public protocol BlockerListManager {
    
    typealias Factory = (() -> BlockerListManager)
    
    var needsReload: Bool { get }
    func setNeedsReload(_ needsReload: Bool)
    func update()
    
}

public class DefaultBlockerListManager: BlockerListManager {
    
    struct Keys {
        static let needsReload = "needsReload"
    }
        
    private let trackerDataManager: TrackerDataManager.Factory
    private let trustedSitesManager: TrustedSitesManager.Factory
    private let blockerListUrl: URL
    private let userDefaults: UserDefaults?
    
    public var needsReload: Bool {
        get {
            return userDefaults?.bool(forKey: Keys.needsReload) ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: Keys.needsReload)
        }
    }
    
    init(trackerDataManager: @escaping TrackerDataManager.Factory,
         trustedSitesManager: @escaping TrustedSitesManager.Factory,
         blockerListUrl: URL = BlockerListLocation.blockerListUrl,
         userDefaults: UserDefaults? = UserDefaults(suiteName: BlockerListLocation.groupName)) {
        self.trackerDataManager = trackerDataManager
        self.trustedSitesManager = trustedSitesManager
        self.blockerListUrl = blockerListUrl
        self.userDefaults = userDefaults
    }
    
    public func setNeedsReload(_ needsReload: Bool) {
        self.needsReload = needsReload
    }
    
    public func update() {
        trustedSitesManager().load()
        guard let blockerListData = buildBlockerListData() else { return }
        writeBlockerList(data: blockerListData)
    }
    
    private func buildBlockerListData() -> Data? {
        guard let trackerData = trackerDataManager().trackerData else {
            os_log("No trackers found", log: generalLog, type: .error)
            return nil
        }
        
        let trustedDomains = trustedSitesManager().allDomains()
        os_log("trustedDomains %s", log: generalLog, type: .debug, String(describing: trustedDomains))

        let tempWhitelistDomains = trustedSitesManager().whitelistedDomains()
        os_log("tempWhitelistDomains %s", log: generalLog, type: .debug, String(describing: tempWhitelistDomains))
        
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules(withExceptions: trustedDomains,
                                                                                    andTemporaryWhitelist: tempWhitelistDomains)
        
        guard let data = try? JSONEncoder().encode(rules) else {
            os_log("Failed to encode rules", log: generalLog, type: .error)
            return nil
        }
        
        if let store = WKContentRuleListStore.default() {
            store.compileContentRuleList(forIdentifier: "XXX", encodedContentRuleList: String(data: data, encoding: .utf8)!) { _, error in
                if let error = error {
                    os_log("Failed to to compile rules %{public}s", log: generalLog, type: .error, error.localizedDescription)
                }
            }
        } else {
            os_log("Failed to access the default WKContentRuleListStore for rules compiliation checking", log: generalLog, type: .error)
        }
        return data
    }
        
    private func writeBlockerList(data: Data) {
        do {
            try data.write(to: blockerListUrl, options: .atomicWrite)
        } catch {
            os_log("Failed to create blocker list %{public}s", log: generalLog, type: .error, error.localizedDescription)
        }
    }
    
}

public struct BlockerListLocation {
    
    public static let groupName = "group.com.duckduckgo.BlockerList"
    
    public static let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
    
    public static let blockerListUrl = containerUrl.appendingPathComponent("blockerList").appendingPathExtension("json")

}
