//
//  BlockerList.swift
//  TrackerBlocking
//
//  Created by Christopher Brind on 05/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation
import SafariServices

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
        NSLog("BlockerList update")

        let dataManager = Dependencies.shared.trackerDataManager
        try? dataManager.load()
        
        let rules = dataManager.contentBlockerRules(withTrustedSites: Dependencies.shared.trustedSitesManager.allDomains())
        guard let encoded = try? JSONEncoder().encode(rules) else {
            NSLog("failed to encode content blocker rules")
            return
        }
        
        writeBlockerList(data: encoded)
        
        completion()
    }

    public func reloadExtension() {
        NSLog("reload content blocker")
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.duckduckgo.macos.ContentBlocker") { error in
            if let error = error {
                NSLog("Failed to reload content blocker \(error)")
            }
        }
    }
    
    private func writeBlockerList(data: Data) {
        do {
            try data.write(to: blockerListUrl, options: .atomicWrite)
        } catch {
            NSLog("Failed to write blocker list")
        }
    }

}
