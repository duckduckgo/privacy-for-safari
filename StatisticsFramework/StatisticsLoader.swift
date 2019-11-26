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

public typealias StatisticsLoaderCompletion = () -> Void

@objc(StatisticsLoader)
public protocol StatisticsLoader {
 
    func refreshSearchRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?)
    func refreshAppRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?)
    
}

public class DefaultStatisticsLoader: StatisticsLoader {

    public static let shared = DefaultStatisticsLoader()
    
    public typealias Completion = (() -> Void)

    struct Constants {
        static let waitTimeout: TimeInterval = 30 // 30 second timeout
    }

    struct Paths {
        static let atb = "/atb.js"
        static let exti = "/exti/"
    }
    
    private let queue = DispatchQueue(label: "StatisticsLoader")
    private let statisticsStore: StatisticsStore.Factory
    private let apiRequest: APIRequest.Factory
    private let pixel: Pixel
    
    init(statisticsStore: @escaping StatisticsStore.Factory = { Dependencies.shared.statisticsStore },
         apiRequest: @escaping APIRequest.Factory = { DefaultAPIRequest() },
         pixel: Pixel = Dependencies.shared.pixel) {
        self.statisticsStore = statisticsStore
        self.apiRequest = apiRequest
        self.pixel = pixel
    }
    
    public func refreshSearchRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        queue.async {
            let group = DispatchGroup()
            group.enter()
            
            var store = self.statisticsStore()
            self.refreshRetention(forType: .search, withSetAtb: store.searchRetentionAtb, atLocation: location, storeResult: { atb in
                store.searchRetentionAtb = atb.version
            }, completion: {
                group.leave()
                completion?()
            })
            if group.wait(timeout: .now() + Constants.waitTimeout) == .timedOut {
                self.pixel.fire(.debugStatisticsTimeout)
            }
        }
    }
    
    public func refreshAppRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        queue.async {
            let group = DispatchGroup()
            group.enter()
            
            var store = self.statisticsStore()
            self.refreshRetention(forType: .app, withSetAtb: store.appRetentionAtb, atLocation: location, storeResult: { atb in
                store.appRetentionAtb = atb.version
            }, completion: {
                group.leave()
                completion?()
            })
            if group.wait(timeout: .now() + Constants.waitTimeout) == .timedOut {
                self.pixel.fire(.debugStatisticsTimeout)
            }
        }
    }
    
    private func refreshRetention(forType type: Atb.Types,
                                  withSetAtb setAtb: String?,
                                  atLocation location: String,
                                  storeResult: @escaping (Atb) -> Void,
                                  completion: Completion?) {
        
        var store = statisticsStore()
        
        guard let initialAtb = store.installAtb else {
            requestInstallStatistics(atLocation: location, completion: completion)
            return
        }
        
        var params = [
            "at": type.rawValue,
            "atb": initialAtb
        ]
        
        if let setAtb = setAtb ?? store.installAtb {
            params["set_atb"] = setAtb
            params["l"] = location
        }
        
        apiRequest().get(Paths.atb, withParams: params) { data, _, error in
            if let error = error {
                os_log("App atb request failed with error %{public}s", log: generalLog, type: .error, error.localizedDescription)
                completion?()
                return
            }
            if let data = data, let atb = try? JSONDecoder().decode(Atb.self, from: data) {
                storeResult(atb)
                if let updateVersion = atb.updateVersion {
                    store.installAtb = updateVersion
                }
            }
            completion?()
        }
        
    }
    
    private func requestInstallStatistics(atLocation location: String, completion: Completion?) {

        apiRequest().get(Paths.atb, withParams: nil) { data, _, error in
            
            if let error = error {
                os_log("Failed to request ATB %{public}s", log: generalLog, type: .error, error.localizedDescription)
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
        
        let params = [
            "atb": atb.version,
            "l": location
        ]

        apiRequest().get(Paths.exti, withParams: params) { _, _, error in
            if let error = error {
                os_log("Failed to request ATB install %{public}s", log: generalLog, type: .error, error.localizedDescription)
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
