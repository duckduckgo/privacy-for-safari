//
//  EntityDetailsModel.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import TrackerBlocking
import os

struct EntityDetailsModel {

    let name: String
    let image: String
    let prevalence: Double
    let requests: [RequestDetailsModel]

    func addingRequest(_ request: RequestDetailsModel, withPrevalence prevalence: Double) -> EntityDetailsModel {
        var requests = self.requests
        requests.append(request)
        return EntityDetailsModel(name: name, image: image, prevalence: max(self.prevalence, prevalence), requests: requests)
    }

    static func entityDetailsFromTrackers(_ trackers: Set<DetectedTracker>,
                                          andRequests requests: Set<PageData.DetectedRequest>? = nil,
                                          trackerDataManager: TrackerDataManager = Dependencies.shared.trackerDataManager) -> [EntityDetailsModel] {
        var entities = [String: EntityDetailsModel]()

        trackers.forEach { tracker in
            let entity = trackerDataManager.entity(forUrl: tracker.resource)
            guard let displayName = entity?.displayName ?? tracker.resource.eTLDPlus1Host else { return }

            let owner = tracker.owner ?? displayName

            let entityDetails = entities[owner, default: EntityDetailsModel(
                name: displayName, image: "PP Network Icon \(owner)", prevalence: tracker.prevalence, requests: []
            )]

            if let requestDomain = tracker.resource.host {
                let request = RequestDetailsModel(domain: requestDomain,
                                                  category: tracker.matchedTracker?.category ?? "")
                entities[owner] = entityDetails.addingRequest(request, withPrevalence: tracker.prevalence)
            }
        }

        requests?.forEach { request in

            let owner = request.owner

            os_log("SEH handleResourceLoadedMessage owner: %{public}s", log: generalLog, type: .debug, owner)

            let entityDetails = entities[owner, default: EntityDetailsModel(
                name: request.displayName,
                image: "PP Network Icon \(request.owner)",
                prevalence: 0,
                requests: []
            )]

            let request = RequestDetailsModel(domain: request.domain, category: "")
            entities[owner] = entityDetails.addingRequest(request, withPrevalence: 0)
        }

        return [EntityDetailsModel](entities.values)
            .sorted(by: {
                $0.prevalence > $1.prevalence
            })
            .map { model in
                EntityDetailsModel(name: model.name,
                                   image: model.image,
                                   prevalence: model.prevalence,
                                   requests: model.requests.sorted(by: { $0.domain < $1.domain }))
            }
    }

}

struct RequestDetailsModel {

    var domain: String
    var category: String

}
