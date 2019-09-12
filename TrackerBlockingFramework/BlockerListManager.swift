//
//  BlockerList.swift
//  TrackerBlocking
//
//  Created by Christopher Brind on 05/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation
import SafariServices
import os
import WebKit

public protocol BlockerListManager {
    
    typealias Factory = (() -> BlockerListManager)
    
    var blockerListUrl: URL { get }
    func updateAndReload()
    
}

public class DefaultBlockerListManager: BlockerListManager {
    
    public static var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.duckduckgo.BlockerList")!
    }
    
    public var blockerListUrl: URL {
        return DefaultBlockerListManager.containerUrl.appendingPathComponent("blockerList").appendingPathExtension("json")
    }
    
    private let trackerDataManager: TrackerDataManager.Factory
    private let trustedSitesManager: TrustedSitesManager.Factory
    
    init(trackerDataManager: @escaping TrackerDataManager.Factory, trustedSitesManager: @escaping TrustedSitesManager.Factory) {
        self.trackerDataManager = trackerDataManager
        self.trustedSitesManager = trustedSitesManager
    }
    
    public func updateAndReload() {
        guard let blockerListData = buildBlockerListData() else { return }
        writeBlockerList(data: blockerListData)
        reloadExtension()
    }
    
    private func buildBlockerListData() -> Data? {
        guard let trackerData = trackerDataManager().trackerData else {
            NSLog("No tracker data!")
            return nil
        }
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules(withExceptions: trustedSitesManager().allDomains())
        
        guard let data = try? JSONEncoder().encode(rules) else {
            NSLog("Failed to encode content blocker rules")
            return nil
        }
        
        if let store = WKContentRuleListStore.default() {
            store.compileContentRuleList(forIdentifier: "XXX", encodedContentRuleList: String(data: data, encoding: .utf8)!) {
                NSLog("compileContentRuleList \($0 as Any) \($1 as Any)")
            }
        } else {
            NSLog("compileContentRuleList NO STORE")
        }
        return data
    }
    
    private func reloadExtension() {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlockerExtension"
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: id) { error in
            guard let error = error else { return }
            os_log("Failed to reload extension %{public}s", type: .error, error.localizedDescription)
        }
    }
    
    private func writeBlockerList(data: Data) {
        do {
            try data.write(to: blockerListUrl, options: .atomicWrite)
        } catch {
            os_log("Failed to create blocker list %{public}s", type: .error, error.localizedDescription)
        }
    }
    
}
