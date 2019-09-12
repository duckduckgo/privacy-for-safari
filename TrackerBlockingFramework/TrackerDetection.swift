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

    func detectTrackerFor(resourceUrl: URL,
                          onPageWithUrl pageUrl: URL,
                          asResourceType resourceType: String?) -> DetectedTracker?
    
    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker
    
}

class DefaultTrackerDetection: TrackerDetection {
    
    private let trackerDataManager: TrackerDataManager.Factory
    
    init(trackerDataManager: @escaping TrackerDataManager.Factory) {
        self.trackerDataManager = trackerDataManager
    }
    
    func detectTrackerFor(resourceUrl: URL,
                          onPageWithUrl pageUrl: URL,
                          asResourceType resourceType: String?) -> DetectedTracker? {

        guard let tracker = trackerDataManager().knownTracker(forUrl: resourceUrl) else { return nil }
        guard let action = actionFor(tracker, withResourceUrl: resourceUrl, onPageWithUrl: pageUrl, asResourceType: resourceType) else { return nil }
        return buildTracker(forResourceUrl: resourceUrl, onPageWithUrl: pageUrl, andKnownTracker: tracker, withAction: action)
    }
 
    func detectedTrackerFrom(resourceUrl: URL, onPageWithUrl pageUrl: URL) -> DetectedTracker {
        let tracker = trackerDataManager().knownTracker(forUrl: resourceUrl)
        return buildTracker(forResourceUrl: resourceUrl,
                            onPageWithUrl: pageUrl,
                            andKnownTracker: tracker,
                            withAction: .block)
    }
    
    private func buildTracker(forResourceUrl resourceUrl: URL,
                              onPageWithUrl pageUrl: URL,
                              andKnownTracker tracker: KnownTracker?,
                              withAction action: DetectedTracker.Action) -> DetectedTracker {
        
        let pageOwner = trackerDataManager().entity(forUrl: pageUrl)
        let resourceOwner = tracker?.owner
        return DetectedTracker(matchedTracker: tracker,
                               resource: resourceUrl,
                               page: pageUrl,
                               owner: resourceOwner?.name,
                               prevalence: tracker?.prevalence ?? 0,
                               isFirstParty: resourceOwner?.isEntity(named: pageOwner?.displayName) ?? false,
                               action: action)

    }

    private func actionFor(_ tracker: KnownTracker,
                           withResourceUrl resourceUrl: URL,
                           onPageWithUrl pageUrl: URL,
                           asResourceType resourceType: String?) -> DetectedTracker.Action? {
        guard let trackerData = trackerDataManager().trackerData else { return nil }
        let rules = ContentBlockerRulesBuilder(trackerData: trackerData).buildRules(from: tracker)

        var action: DetectedTracker.Action = .ignore
        rules.enumerated().forEach { rule in
            let triggerResourceType = ContentBlockerRulesBuilder.resourceMapping[resourceType ?? ""]
            if rule.element.matches(resourceUrl: resourceUrl, onPageWithUrl: pageUrl, ofType: triggerResourceType) {
                action = rule.element.action.type == .block ? .block : .ignore
            }
        }

        return action
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
