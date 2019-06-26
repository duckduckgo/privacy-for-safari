//
//  TrackerDataManager.swift
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
import os

public protocol TrackerDataManager {
    
    func load() throws
    func update(completion: () -> Void)
    func forEachEntity(_ result: (Entity) -> Void)
    func forEachTracker(_ result: (KnownTracker) -> Void)
    func contentBlockerRules() -> [TrackerData.TrackerRules]
    func rule(forTrustedSites trustedSites: [String]) -> ContentBlockerRule?
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
    var trackersByRegex = [NSRegularExpression: KnownTracker]()
    var entities = [String: Entity]()

    init() {
        do {
            try load()
        } catch {
            os_log("Failed to load tracker data %{public}s", type: .error, error.localizedDescription)
        }
    }
    
    public func load() throws {
        let data = try Data(contentsOf: trackerDataUrl)
        let trackerData = try JSONDecoder().decode(TrackerData.self, from: data)

        self.trackerData = trackerData
        self.trackersByRegex = trackerData.trackersByRegex()
        self.entities = trackerData.entitiesByDomain()

        os_log("loaded %d rules for %d entities", trackersByRegex.count, entities.count)
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
    
    public func contentBlockerRules() -> [TrackerData.TrackerRules] {
        return trackerData?.contentBlockerRules() ?? []
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
        let url = url.absoluteString
        return trackersByRegex.first(where: {
            return !$0.key.matches(in: url, options: [ .anchored ], range: NSRange(url.startIndex..., in: url)).isEmpty
        }).map { $0.value }
    }
    
    public func rule(forTrustedSites trustedSites: [String]) -> ContentBlockerRule? {
        guard !trustedSites.isEmpty else { return nil }
        return ContentBlockerRule(trigger: ContentBlockerRule.Trigger.trigger(urlFilter: ".*", ifDomain: trustedSites.map { "*" + $0 }),
                                  action: ContentBlockerRule.Action.ignorePreviousRules())
    }
    
    private func installDefaultTrackerData() {
        guard let defaultTrackerDataUrl = Bundle(for: type(of: self)).url(forResource: "trackerData", withExtension: "json") else {
            os_log("Failed to determine url for writing trackerData.json", type: .error)
            return
        }
        
        do {
            try Data(contentsOf: defaultTrackerDataUrl).write(to: trackerDataUrl, options: .atomicWrite)
        } catch {
            os_log("Failed to write trackerData.json to %{public}s", type: .error, trackerDataUrl.absoluteString)
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
