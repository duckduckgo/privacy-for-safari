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
    
    typealias Factory = (() -> TrackerDataManager)

    var trackerData: TrackerData? { get }

    func load()
    func forEachEntity(_ result: (Entity) -> Void)
    func forEachTracker(_ result: (KnownTracker) -> Void)
    func entity(forUrl url: URL) -> Entity?
    func entity(forName name: String) -> Entity?
    func knownTracker(forUrl url: URL) -> KnownTracker?
    
}

public struct TrackerDataLocation {
    
    public static var groupName = "group.com.duckduckgo.TrackerData"
    
    static var trackerDataUrl: URL {
        return containerUrl.appendingPathComponent("trackerData").appendingPathExtension("json")
    }
    
    static private var containerUrl: URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName)!
    }
}

public class DefaultTrackerDataManager: TrackerDataManager {

    public var trackerData: TrackerData?

    init() {
        load()
    }
    
    public func forEachEntity(_ result: (Entity) -> Void) {
        trackerData?.entities.values.forEach(result)
    }
    
    public func forEachTracker(_ result: (KnownTracker) -> Void) {
        trackerData?.trackers.values.forEach(result)
    }

    public func entity(forUrl url: URL) -> Entity? {
        guard let variations = url.hostVariations else { return nil }
        for host in variations {
            if let entity = trackerData?.entities[host] {
                return entity
            }
        }
        return nil
    }
    
    public func entity(forName name: String) -> Entity? {
        return trackerData?.entities[name]
   }

    public func knownTracker(forUrl url: URL) -> KnownTracker? {
        for domain in url.hostVariations ?? [] {
            if let tracker = trackerData?.trackers[domain] {
                return tracker
            }
        }
        return nil
    }
    
    public func load() {
        if !FileManager.default.fileExists(atPath: TrackerDataLocation.trackerDataUrl.path) {
            os_log("Tracker data does not exist, loading default", log: generalLog, type: .default)
            installDefaultTrackerData()
        }
        self.trackerData = TrackerData.decode(contentsOf: TrackerDataLocation.trackerDataUrl)
        os_log("loaded %d trackers and %d entities", log: generalLog, trackerData?.trackers.count ?? -1, trackerData?.entities.count ?? -1)
    }

    private func installDefaultTrackerData() {
        guard let defaultTrackerDataUrl = Bundle(for: type(of: self)).url(forResource: "trackerData", withExtension: "json") else {
            os_log("Failed to determine url for writing trackerData.json", log: generalLog, type: .error)
            return
        }
        
        do {
            try Data(contentsOf: defaultTrackerDataUrl).write(to: TrackerDataLocation.trackerDataUrl, options: .atomicWrite)
        } catch {
            os_log("Failed to write trackerData.json to %{public}s", log: generalLog, type: .error, TrackerDataLocation.trackerDataUrl.absoluteString)
        }
    }
}
