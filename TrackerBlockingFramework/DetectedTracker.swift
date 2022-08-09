//
//  Tracker.swift
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
import TrackerRadarKit

public struct DetectedTracker {

    public enum Action {
        case block
        case ignore
    }

    public let matchedTracker: KnownTracker?
    public let resource: URL
    public let page: URL
    public let owner: String?
    public let prevalence: Double
    public let isFirstParty: Bool
    public let action: Action

}

extension DetectedTracker: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(matchedTracker?.domain)
    }

}

extension DetectedTracker: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.matchedTracker?.domain == rhs.matchedTracker?.domain
    }

}
