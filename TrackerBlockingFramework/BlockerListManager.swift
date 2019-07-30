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

public protocol BlockerListManager {

    typealias Factory = (() -> BlockerListManager)
    
    var blockerListUrl: URL { get }
    func updateAndReload()

}

public class DefaultBlockerListManager: BlockerListManager {

    private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.duckduckgo.BlockerList")!
    }

    public var blockerListUrl: URL {
        return containerUrl.appendingPathComponent("blockerList").appendingPathExtension("json")
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
        let dataManager = trackerDataManager()
        var rules = dataManager.contentBlockerRules().map { $0.rules }.flatMap { $0 }
        if let whitelistRule = dataManager.rule(forTrustedSites: trustedSitesManager().allDomains()) {
            rules += [ whitelistRule ]
        }        
        return try? JSONEncoder().encode(rules)
    }

    private func reloadExtension() {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlockingExtension"
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: id)
    }
    
    private func writeBlockerList(data: Data) {
        do {
            try data.write(to: blockerListUrl, options: .atomicWrite)
        } catch {
            os_log("Failed to create blocker list %{public}s", type: .error, error.localizedDescription)
        }
    }

}
