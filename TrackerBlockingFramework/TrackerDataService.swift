//
//  TrackerDataService.swift
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
import Core
import os

public protocol TrackerDataService {

    func updateData(completion: @escaping DataCompletion)
}

public class DefaultTrackerDataService: TrackerDataService {
    
    struct Paths {
        static let tds = "/trackerblocking/tds.json"
    }
    
    private let apiRequest: APIRequest.Factory
    private var trackerDataServiceStore: TrackerDataServiceStore
    
    public init(apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest(baseUrl: .cdn) },
                trackerDataServiceStore: TrackerDataServiceStore = TrackerDataServiceUserDefaults()) {

        self.apiRequest = apiRequest
        self.trackerDataServiceStore = trackerDataServiceStore
    }
    
    public func updateData(completion: @escaping DataCompletion) {
        os_log("TDS update starting")
        
        apiRequest().get(Paths.tds, withParams: nil) { data, response, error in
            
            if let error = error {
                os_log("TDS request failed with error %{private}s", type: .error, error.localizedDescription)
                completion(false, false)
                return
            }
            
            guard let data = data else {
                os_log("TDS request returned with no data", type: .error)
                completion(false, false)
                return
            }
            
            let newData = self.trackerDataServiceStore.etag != response?.strongEtag()
            guard newData else {
                os_log("TDS request returned with cached data", type: .error)
                completion(true, false)
                return
            }
            
            guard self.persist(data: data) else {
                completion(false, true)
                return
            }

            self.trackerDataServiceStore.etag = response?.strongEtag()
            completion(true, true)
        }
    }
    
    private func persist(data: Data) -> Bool {
        let url = TrackerDataLocation.trackerDataUrl
        do {
            try data.write(to: url, options: .atomic)
            os_log("TDS update persisted to %{public}s", type: .info, url.absoluteString)
            return true
        } catch {
            os_log("TDS data failed to persist to %{public}s %{public}s", type: .error, url.absoluteString, error.localizedDescription)
            return false
        }
    }
}
