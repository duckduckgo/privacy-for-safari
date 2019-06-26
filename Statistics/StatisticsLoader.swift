//
//  StatisticsLoader.swift
//  Statistics
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

public protocol StatisticsLoader {

    typealias Completion = (() -> Void)
    
    func refreshSearchRetentionAtb(atLocation: String, completion: Completion?)
    
    func refreshAppRetentionAtb(atLocation: String, completion: Completion?)
    
}

public class DefaultStatisticsLoader: StatisticsLoader {
    
    struct Paths {
        
        static let atb = "/atb.js"
        static let exti = "/exti/"
        
    }
    
    let apiRequest: APIRequest
    
    init(apiRequest: APIRequest = DefaultAPIRequest()) {
        self.apiRequest = apiRequest
    }
    
    public func refreshSearchRetentionAtb(atLocation location: String, completion: Completion?) {
        print(#function)
        var store = Dependencies.shared.statisticsStore
        refreshRetention(forType: .search, withSetAtb: store.searchRetentionAtb, atLocation: location, storeResult: { atb in
            store.searchRetentionAtb = atb.version
        }, completion: completion)
    }
    
    public func refreshAppRetentionAtb(atLocation location: String, completion: Completion?) {
        print(#function)
        var store = Dependencies.shared.statisticsStore
        refreshRetention(forType: .app, withSetAtb: store.appRetentionAtb, atLocation: location, storeResult: { atb in
            store.appRetentionAtb = atb.version
        }, completion: completion)
    }
    
    private func refreshRetention(forType type: Atb.Types,
                                  withSetAtb setAtb: String?,
                                  atLocation location: String,
                                  storeResult: @escaping (Atb) -> Void,
                                  completion: Completion?) {
        
        let store = Dependencies.shared.statisticsStore
        
        guard let initialAtb = store.installAtb else {
            requestInstallStatistics(atLocation: location, completion: completion)
            return
        }
        
        var params = [
            "at": type.rawValue,
            "atb": initialAtb
        ]
        
        if let setAtb = setAtb {
            params["set_atb"] = setAtb
            params["l"] = location
        }
        
        apiRequest.get(Paths.atb, withParams: params) { data, _, error in
            if let error = error {
                os_log("App atb request failed with error %{public}s", type: .error, error.localizedDescription)
                completion?()
                return
            }
            if let data = data, let atb = try? JSONDecoder().decode(Atb.self, from: data) {
                storeResult(atb)
            }
            completion?()
        }
        
    }
    
    private func requestInstallStatistics(atLocation location: String, completion: Completion?) {
        print(#function)

        apiRequest.get(Paths.atb, withParams: nil) { data, _, error in
            
            if let error = error {
                os_log("Failed to request ATB %{public}s", type: .error, error.localizedDescription)
                completion?()
                return
            }
            
            if let data = data, let atb = try? JSONDecoder().decode(Atb.self, from: data) {
                self.requestExti(atb: atb, atLocation: location, completion: completion)
            } else {
                completion?()
            }
        }
    }
    
    private func requestExti(atb: Atb, atLocation location: String, completion: Completion?) {
        print(#function)
        
        let params = [
            "atb": atb.version,
            "l": location
        ]

        apiRequest.get(Paths.exti, withParams: params) { _, _, error in
            if let error = error {
                os_log("Failed to request ATB install %{public}s", type: .error, error.localizedDescription)
                completion?()
                return
            }
            var store = Dependencies.shared.statisticsStore
            store.installDate = Date()
            store.installAtb = atb.version
            completion?()
        }
    }
    
}
