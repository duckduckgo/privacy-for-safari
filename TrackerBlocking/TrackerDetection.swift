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
    
    func detectTracker(forResource resource: String, ofType type: String, onPageWithUrl pageUrl: URL) -> DetectedTracker?
    
}

class DefaultTrackerDetection: TrackerDetection {
    
    func detectTracker(forResource resource: String, ofType type: String, onPageWithUrl pageUrl: URL) -> DetectedTracker? {
        let trackerDataManager = Dependencies.shared.trackerDataManager
        
        guard let resourceUrl = URL(withResource: resource) else { return nil }
        guard let knownTracker = trackerDataManager.knownTracker(forUrl: resourceUrl) else { return nil }

        let pageOwner = trackerDataManager.entity(forUrl: pageUrl)
        let resourceOwner = knownTracker.owner
        return DetectedTracker(resource: resource,
                               type: type,
                               page: pageUrl,
                               owner: resourceOwner?.name,
                               prevalence: knownTracker.prevalence,
                               isFirstParty: resourceOwner?.name == pageOwner?.name)
    }
    
}

fileprivate extension URL {
    
    init?(withResource resource: String) {
        var url: String
        if resource.hasPrefix("//") {
            url = "http" + resource
        } else if resource.hasPrefix("http://") || resource.hasPrefix("https://") {
            url = resource
        } else {
            return nil
        }
        self.init(string: url)
    }

}
