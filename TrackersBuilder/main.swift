//
//  main.swift
//  TrackersBuilder
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

guard CommandLine.arguments.count == 5 else {
    print("USAGE: macos <trackers directory> <entities directory> <trackers json output> <content blocker rules json output>")
    exit(1)
}

let trackersDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let entitiesDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let trackersOutputFile = URL(fileURLWithPath: CommandLine.arguments[3])
let blockerRulesOutputFile = URL(fileURLWithPath: CommandLine.arguments[4])

let fm = FileManager.default

print("Scanning \(trackersDirectory.absoluteString) for trackers")

let decoder = JSONDecoder()
var entities = Set<Entity>()

guard let enumerator = fm.enumerator(at: trackersDirectory, includingPropertiesForKeys: nil) else {
    print("ERROR: failed to enumerate \(trackersDirectory.absoluteString)")
    exit(2)
}

let trackers = enumerator.compactMap { foundUrl -> KnownTracker? in

    guard let tracker = KnownTracker.load(fromUrl: foundUrl as? URL) else {
        print("Failed to load tracker from \(foundUrl)")
        return nil
    }

    guard let owner = tracker.owner?.name else { return tracker }

    if let entity = Entity.load(entityNamed: owner, fromDirectory: entitiesDirectory) {
        entities.insert(entity)
    }

    return tracker
}

print("\(trackers.count) trackers loaded with \(entities.count) unique entities")
print("Loading entities from \(entitiesDirectory.absoluteString)")

print("Writing \(trackers.count) trackers and \(entities.count) entities to \(trackersOutputFile.absoluteString)")

let trackerData = TrackerData(trackers: trackers, entities: [Entity](entities))
do {
    let trackerDataEncoded = try JSONEncoder().encode(trackerData)
    try trackerDataEncoded.write(to: trackersOutputFile)
} catch {
    print("Failed to write tracker data", error)
}

let contentBlockingRules = trackerData.contentBlockerRules().flatMap { $0.rules }
print("Writing \(contentBlockingRules.count) rules to \(blockerRulesOutputFile.absoluteString)")
do {
    let contentBlockingRulesEncoded = try JSONEncoder().encode(contentBlockingRules)
    try contentBlockingRulesEncoded.write(to: blockerRulesOutputFile)
} catch {
    print("Failed to write blocker rules", error)
}
