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

    var blockerListUrl: URL { get }
    func update(completion: () -> Void)
    func reloadExtension()

}

public class DefaultBlockerListManager: BlockerListManager {

    private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.duckduckgo.BlockerList")!
    }

    public var blockerListUrl: URL {
        return containerUrl.appendingPathComponent("blockerList").appendingPathExtension("json")
    }
    
    public func update(completion: () -> Void) {
        let dataManager = Dependencies.shared.trackerDataManager
        try? dataManager.load()
        
        var rules = dataManager.contentBlockerRules().map { $0.rules }.flatMap { $0 }
        if let whitelistRule = dataManager.rule(forTrustedSites: Dependencies.shared.trustedSitesManager.allDomains()) {
            rules += [ whitelistRule ]
        }
        
        guard let encoded = try? JSONEncoder().encode(rules) else { return }
        
        writeBlockerList(data: encoded)
        
        completion()
    }

    public func reloadExtension() {
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
