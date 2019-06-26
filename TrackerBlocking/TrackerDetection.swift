//
//  ContentBlocker.swift
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

public protocol TrackerDetection {
    
    func detectTrackerFor(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker?
    
    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker
    
}

class DefaultTrackerDetection: TrackerDetection {
    
    func detectTrackerFor(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker? {
        let trackerDataManager = Dependencies.shared.trackerDataManager
        guard let knownTracker = trackerDataManager.knownTracker(forUrl: resourceUrl) else { return nil }
        return buildTracker(usingDataManager: trackerDataManager,
                            forResourceUrl: resourceUrl,
                            onPageWithUrl: pageUrl,
                            andKnownTracker: knownTracker)
    }
 
    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker {
        let trackerDataManager = Dependencies.shared.trackerDataManager
        let knownTracker = trackerDataManager.knownTracker(forUrl: resourceUrl)
        return buildTracker(usingDataManager: trackerDataManager,
                            forResourceUrl: resourceUrl,
                            onPageWithUrl: pageUrl,
                            andKnownTracker: knownTracker)
    }
    
    private func buildTracker(usingDataManager trackerDataManager: TrackerDataManager,
                              forResourceUrl resourceUrl: URL,
                              onPageWithUrl pageUrl: URL,
                              andKnownTracker knownTracker: KnownTracker?) -> DetectedTracker {
        
        let pageOwner = trackerDataManager.entity(forUrl: pageUrl)
        let resourceOwner = knownTracker?.owner
        return DetectedTracker(resource: resourceUrl,
                               page: pageUrl,
                               owner: resourceOwner?.name,
                               prevalence: knownTracker?.prevalence ?? 0,
                               isFirstParty: resourceOwner?.isEntity(named: pageOwner?.name) ?? false)

    }
    
}

extension URL {
    
    public init?(withResource resource: String, relativeTo relativeUrl: URL? = nil) {
        var url: String
        if resource.hasPrefix("//") {
            url = "http:" + resource
        } else if resource.hasPrefix("/") || resource.hasPrefix("http://") || resource.hasPrefix("https://") {
            url = resource
        } else {
            return nil
        }
        self.init(string: url, relativeTo: relativeUrl)
    }

}
