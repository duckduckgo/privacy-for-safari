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
import TrackerRadarKit

public protocol BlockerListManager {
    
    typealias Factory = (() -> BlockerListManager)

    func update() async

}

public class DefaultBlockerListManager: BlockerListManager {
            
    private let trackerDataManager: TrackerDataManager.Factory
    private let trustedSitesManager: TrustedSitesManager.Factory
    private let blockerListUrl: URL
        
    init(trackerDataManager: @escaping TrackerDataManager.Factory,
         trustedSitesManager: @escaping TrustedSitesManager.Factory,
         blockerListUrl: URL = BlockerListLocation.blockerListUrl) {
        self.trackerDataManager = trackerDataManager
        self.trustedSitesManager = trustedSitesManager
        self.blockerListUrl = blockerListUrl
    }

    public func update() async {
        let allowList = AdClickAttributionExemptions.shared.allowList
        let domains = AdClickAttributionExemptions.shared.vendorDomains

        guard let blockerListData = buildBlockerListData(applyingAllowList: allowList, toDomains: domains) else { return }
        writeBlockerList(data: blockerListData)
    }
    
    private func buildBlockerListData(applyingAllowList allowList: [AdClickAttributionFeature.AllowlistEntry], toDomains domains: [String]) -> Data? {
        os_log("buildBlockerListData %s", log: generalLog, type: .debug, "\(allowList) \(domains)")

        guard let trackerData = trackerDataManager().trackerData else {
            os_log("No trackers found", log: generalLog, type: .error)
            return nil
        }

        let trustedDomains = trustedSitesManager().allDomains()
        os_log("trustedDomains %s", log: generalLog, type: .debug, String(describing: trustedDomains))

        let tempUnprotectedDomains = trustedSitesManager().unprotectedDomains()
        os_log("tempUnprotectedDomains %s", log: generalLog, type: .debug, String(describing: tempUnprotectedDomains))

        let trackerAllowList = createTrackerAllowList(using: allowList, forDomains: domains)
        let builder = ContentBlockerRulesBuilder(trackerData: trackerData)
        let blockingRules = builder.buildRules(withExceptions: trustedDomains,
                                               andTemporaryUnprotectedDomains: tempUnprotectedDomains,
                                               andTrackerAllowlist: trackerAllowList)
        let installbuttonRules = buildInstallButtonHider()
        let rules = blockingRules + installbuttonRules

        guard let data = try? JSONEncoder().encode(rules) else {
            os_log("Failed to encode rules", log: generalLog, type: .error)
            return nil
        }

        return data
    }

    private func buildInstallButtonHider() -> [ContentBlockerRule] {
        let trigger = ContentBlockerRule.Trigger.trigger(onDomain: "duckduckgo.com")
        let rule = ContentBlockerRulesBuilder.buildRule(trigger: trigger,
                                                        withAction: .cssDisplayNone(selector: ".ddg-extension-hide"))
        return [ rule ]
    }

    private func createTrackerAllowList(using adClickAllowList: [AdClickAttributionFeature.AllowlistEntry],
                                        forDomains domains: [String]) -> [TrackerException] {
        if domains.isEmpty { return [] }
        let cleanDomains = domains.map { $0.dropPrefix("www.") }
        return adClickAllowList.map {
            TrackerException(rule: $0.host, matching: .domains(cleanDomains))
        }
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
