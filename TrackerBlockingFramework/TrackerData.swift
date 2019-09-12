//
//  TrackerData.swift
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
import os

public struct TrackerData: Codable {

    public typealias EntityName = String
    public typealias TrackerDomain = String

    public struct TrackerRules {
        
        let tracker: KnownTracker
        
    }
    
    public let trackers: [TrackerDomain: KnownTracker]
    public let entities: [EntityName: Entity]
    public let domains: [TrackerDomain: EntityName]
    
    public init(trackers: [String: KnownTracker], entities: [String: Entity], domains: [String: String]) {
        self.trackers = trackers
        self.entities = entities
        self.domains = domains
    }

    func relatedDomains(for owner: KnownTracker.Owner?) -> [String]? {
        return entities[owner?.name ?? ""]?.domains
    }

    static func decode(contentsOf url: URL) -> TrackerData? {
        guard let data = try? Data(contentsOf: url) else {
            os_log("Failed to load tracker data: %{public}s", type: .error, url.path)
            return nil
        }
        
        do {
            return try JSONDecoder().decode(TrackerData.self, from: data)
        } catch {
            os_log("Failed to decode tracker data: %{public}s", type: .error, error.localizedDescription)
        }
        return nil
    }
    
}
