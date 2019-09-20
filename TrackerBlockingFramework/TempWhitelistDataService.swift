//
//  TempWhitelistDataService.swift
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

public protocol TempWhitelistDataService {

    func updateData(completion: @escaping TempWhitelistDataCompletion)
}

public typealias TempWhitelistDataCompletion = (_ success: Bool, _ newData: Bool) -> Void

public class DefaultTempWhitelistDataService: TempWhitelistDataService {
    
    struct Paths {
        static let whitelist = "/contentblocking/trackers-whitelist-temporary.txt"
    }
    
    private let apiRequest: APIRequest.Factory
    private var tempWhitelistDataServiceStore: TempWhitelistDataServiceStore
    
    public init(apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest(baseUrl: .standard) },
                tempWhitelistDataServiceStore: TempWhitelistDataServiceStore = TempWhitelistDataServiceUserDefaults()) {

        self.apiRequest = apiRequest
        self.tempWhitelistDataServiceStore = tempWhitelistDataServiceStore
    }
    
    public func updateData(completion: @escaping TempWhitelistDataCompletion) {
        os_log("Temp whitelist update starting")
        
        apiRequest().get(Paths.whitelist, withParams: nil) { data, response, error in
            
            if let error = error {
                os_log("Temp whitelist request failed with error %{private}s", type: .error, error.localizedDescription)
                completion(false, false)
                return
            }
            
            guard let data = data else {
                os_log("Temp whitelist request returned with no data", type: .error)
                completion(false, false)
                return
            }
            
            let newData = self.tempWhitelistDataServiceStore.etag != response?.strongEtag()
            guard newData else {
                os_log("Temp whitelist request returned with cached data", type: .error)
                completion(true, false)
                return
            }
            
            guard self.persist(data: data) else {
                completion(false, true)
                return
            }

            self.tempWhitelistDataServiceStore.etag = response?.strongEtag()
            completion(true, true)
        }
    }
    
    private func persist(data: Data) -> Bool {
        let url = TempWhitelistDataLocation.dataUrl
        do {
            try data.write(to: url, options: .atomic)
            os_log("Temp whitelist update persisted to %{public}s", type: .info, url.absoluteString)
            return true
        } catch {
            os_log("Temp whitelist data failed to persist to %{public}s %{public}s", type: .error, url.absoluteString, error.localizedDescription)
            return false
        }
    }
}

public protocol TempWhitelistDataServiceStore {
    var etag: String? { get set }
}

public class TempWhitelistDataServiceUserDefaults: TempWhitelistDataServiceStore {
    
    private struct Key {
        static var etag = "com.duckduckgo.tempwhitelistservice.etag"
    }
    
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults(suiteName: TempWhitelistDataLocation.groupName)!) {
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
