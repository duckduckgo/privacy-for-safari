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

    func update(completion: () -> Void)
    func forEachEntity(_ result: (Entity) -> Void)
    func forEachTracker(_ result: (KnownTracker) -> Void)
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
    
    public var trackerData: TrackerData?

    init() {
        load()
    }
        
    /// Install default tracker data if there currently is none, or download the latest from the endpoint.
    public func update(completion: () -> Void) {
        installDefaultTrackerData()
        // TODO download latest and install it
        load()
        completion()
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

    public func knownTracker(forUrl url: URL) -> KnownTracker? {
        for domain in url.hostVariations ?? [] {
            if let tracker = trackerData?.trackers[domain] {
                return tracker
            }
        }
        return nil
    }

    func installDefaultTrackerData() {
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

    func load() {
        self.trackerData = TrackerData.decode(contentsOf: trackerDataUrl)
        os_log("loaded %d trackers and %d entities", trackerData?.trackers.count ?? -1, trackerData?.entities.count ?? -1)
    }

}
