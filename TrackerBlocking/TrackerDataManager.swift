//
//  TrackerDataManager.swift
//  TrackerBlocking
//
//  Created by Chris Brind on 06/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

public protocol TrackerDataManager {
    
    func load() throws
    func update(completion: () -> Void)
    func forEachEntity(_ result: (Entity) -> Void)
    func forEachTracker(_ result: (KnownTracker) -> Void)
    func contentBlockerRules(withTrustedSites: [String]) -> [ContentBlockerRule]
    func entity(forUrl url: URL) -> Entity?
    func knownTracker(forUrl url: URL) -> KnownTracker?
    
}

public class DefaultTrackerDataManager: TrackerDataManager {

    private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.duckduckgo.TrackerData")!
    }
    
    private var trackerDataUrl: URL {
        return containerUrl.appendingPathComponent("trackerData").appendingPathExtension("json")
    }
    
    var trackerData: TrackerData?
    var rules = [NSRegularExpression: KnownTracker]()
    var entities = [String: Entity]()

    init() {
        do {
            try load()
        } catch {
            NSLog("failed to load trackerData \(error)")
        }
    }
    
    public func load() throws {
        let data = try Data(contentsOf: trackerDataUrl)
        let trackerData = try JSONDecoder().decode(TrackerData.self, from: data)

        self.trackerData = trackerData
        self.rules = trackerData.trackersByRegex()
        self.entities = trackerData.entitiesByDomain()

        NSLog("loaded \(rules.count) rules for \(entities.count) entities")
    }
    
    public func update(completion: () -> Void) {
        installDefaultTrackerData()
        completion()
        
        // later, download latest and install it
    }
    
    public func forEachEntity(_ result: (Entity) -> Void) {
        trackerData?.entities.forEach(result)
    }
    
    public func forEachTracker(_ result: (KnownTracker) -> Void) {
        trackerData?.trackers.forEach(result)
    }
    
    public func contentBlockerRules(withTrustedSites sites: [String]) -> [ContentBlockerRule] {
        return trackerData?.contentBlockerRules(withTrustedSites: sites) ?? []
    }

    public func entity(forUrl url: URL) -> Entity? {
        guard let variations = url.hostVariations else { return nil }
        for host in variations {
            if let entity = entities[host] {
                return entity
            }
        }
        return nil
    }

    public func knownTracker(forUrl url: URL) -> KnownTracker? {
        var pattern: String?
        let url = url.absoluteString
        let tracker = rules.first(where: {
            pattern = $0.key.pattern
            return !$0.key.matches(in: url, options: [], range: NSRange(url.startIndex..., in: url)).isEmpty
        }).map { $0.value }

        if tracker != nil {
            NSLog("Found tracker \(url) with rule \(pattern ?? "<unknown pattern>")")
        }

        return tracker
    }
    
    private func installDefaultTrackerData() {
        guard let defaultTrackerDataUrl = Bundle(for: type(of: self)).url(forResource: "trackerData", withExtension: "json") else {
            NSLog("Failed to find url for trackerData.json")
            return
        }
        
        do {
            try Data(contentsOf: defaultTrackerDataUrl).write(to: trackerDataUrl, options: .atomicWrite)
        } catch {
            NSLog("\(error)")
        }
    }

}

extension URL {

    var hostVariations: [String]? {
        guard let host = self.host else { return nil }
        var parts = host.split(separator: ".")
        var variations = [String]()

        while parts.count > 1 {
            variations.append(parts.joined(separator: "."))
            parts = [String.SubSequence](parts.dropFirst())
        }

        return variations
    }

}
