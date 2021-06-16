//
//  TempUnprotectedSitesDataService.swift
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

public protocol TempUnprotectedSitesDataService {

    func updateData(completion: @escaping TempUnprotectedSitesDataCompletion)
}

public typealias TempUnprotectedSitesDataCompletion = (_ success: Bool, _ newData: Bool) -> Void

public class DefaultTempUnprotectedSitesDataService: TempUnprotectedSitesDataService {
    
    struct Paths {
        static let unprotectedSites = "/contentblocking/trackers-unprotected-temporary.txt"
    }
    
    private let apiRequest: APIRequest.Factory
    private var tempUnprotectedSitesDataServiceStore: TempUnprotectedSitesDataServiceStore
    
    public init(apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest(baseUrl: .standard) },
                tempUnprotectedSitesDataServiceStore: TempUnprotectedSitesDataServiceStore = TempUnprotectedSitesDataServiceUserDefaults()) {

        self.apiRequest = apiRequest
        self.tempUnprotectedSitesDataServiceStore = tempUnprotectedSitesDataServiceStore
    }
    
    public func updateData(completion: @escaping TempUnprotectedSitesDataCompletion) {
        os_log("Temp unprotected sites update starting", log: generalLog)
        
        apiRequest().get(Paths.unprotectedSites, withParams: nil) { data, response, error in
            
            if let error = error {
                os_log("Temp unprotected sites request failed with error %{private}s", log: generalLog, type: .error, error.localizedDescription)
                completion(false, false)
                return
            }
            
            guard let data = data else {
                os_log("Temp unprotected sites request returned with no data", log: generalLog, type: .error)
                completion(false, false)
                return
            }
            
            let newData = self.tempUnprotectedSitesDataServiceStore.etag != response?.strongEtag()
            guard newData else {
                os_log("Temp unprotected sites request returned with cached data, etag: %{public}s", log: generalLog, type: .default,
                       self.tempUnprotectedSitesDataServiceStore.etag ?? "unknown")
                completion(true, false)
                return
            }
            
            guard self.persist(data: data) else {
                completion(false, true)
                return
            }

            self.tempUnprotectedSitesDataServiceStore.etag = response?.strongEtag()
            os_log("Temp unprotected sites new data with etag: %{public}s", log: generalLog, type: .default,
                   self.tempUnprotectedSitesDataServiceStore.etag ?? "unknown")
            completion(true, true)
        }
    }
    
    private func persist(data: Data) -> Bool {
        let url = TempUnprotectedSitesDataLocation.dataUrl
        do {
            try data.write(to: url, options: .atomic)
            os_log("Temp unprotected sites update persisted to %{public}s", log: generalLog, type: .default, url.absoluteString)
            return true
        } catch {
            os_log("Temp unprotected sites data failed to persist to %{public}s %{public}s", log: generalLog, type: .error,
                   url.absoluteString,
                   error.localizedDescription)
            return false
        }
    }
}

public protocol TempUnprotectedSitesDataServiceStore {
    var etag: String? { get set }
}

public class TempUnprotectedSitesDataServiceUserDefaults: TempUnprotectedSitesDataServiceStore {
    
    private struct Key {
        static var etag = "com.duckduckgo.tempunprotectedsitesservice.etag"
    }
    
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults(suiteName: TempUnprotectedSitesDataLocation.groupName)!) {
        self.userDefaults = userDefaults
    }
    
    public var etag: String? {
        get {
            return userDefaults.string(forKey: Key.etag)
        }
        set(etag) {
            userDefaults.set(etag, forKey: Key.etag)
        }
    }
}
