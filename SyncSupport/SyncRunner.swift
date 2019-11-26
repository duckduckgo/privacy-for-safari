//
//  SyncRunner.swift
//  SyncSupport
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
import os
import TrackerBlocking
import Statistics

public class SyncRunner {

    public typealias SyncCompletion = (_ success: Bool) -> Void
    
    private let trackerDataService: TrackerDataService
    private let tempWhitelistDataService: TempWhitelistDataService
    private let trackerDataManager: TrackerDataManager
    private let blockerListManager: BlockerListManager
    
    public init(trackerDataService: TrackerDataService = DefaultTrackerDataService(),
                tempWhitelistDataService: TempWhitelistDataService = DefaultTempWhitelistDataService(),
                trackerDataManager: TrackerDataManager = TrackerBlocking.Dependencies.shared.trackerDataManager,
                blockerListManager: BlockerListManager = TrackerBlocking.Dependencies.shared.blockerListManager) {
        
        self.trackerDataService = trackerDataService
        self.tempWhitelistDataService = tempWhitelistDataService
        self.trackerDataManager = trackerDataManager
        self.blockerListManager = blockerListManager
    }
    
    public func sync(completion: @escaping SyncCompletion) {
        os_log("Sync is starting", log: generalLog)
        
        let group = DispatchGroup()
        
        let trackerData = ServiceWrapper(group: group)
        let tempWhitelistData = ServiceWrapper(group: group)
        
        trackerDataService.updateData(completion: trackerData.start())
        tempWhitelistDataService.updateData(completion: tempWhitelistData.start())
        
        if group.wait(timeout: .now() + 30) == .timedOut {
            Statistics.Dependencies.shared.pixel.fire(.debugSyncTimeout)
        }
        
        if trackerData.newData || tempWhitelistData.newData {
            os_log("Sync has new data %{public}s %{public}s", log: generalLog,
                   trackerData.newData ? "tracker data" : "",
                   tempWhitelistData.newData ? "whitelist data" : "")
            
            self.trackerDataManager.load()
            self.blockerListManager.update()
            ContentBlockerExtension.reloadSync()
        }
        
        // if either fail, don't store the sync time - we need that data!
        completion(trackerData.success && tempWhitelistData.success)
    }
    
}

class ServiceWrapper {
    
    let group: DispatchGroup
    
    var newData: Bool = false
    var success: Bool = false
    
    init(group: DispatchGroup) {
        self.group = group
    }
    
    func start() -> DataCompletion {
        group.enter()
        return completion
    }
    
    private func completion(success: Bool, newData: Bool) {
        self.newData = newData
        self.success = success
        group.leave()
    }
    
}
