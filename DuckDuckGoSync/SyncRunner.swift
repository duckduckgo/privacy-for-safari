//
//  SyncRunner.swift
//  DuckDuckGoSync
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

public struct SyncNotification {
    public static var newDataNotificationName = NSNotification.Name("com.duckduckgo.macos.privacyessentials.sync.notification.newdata")
}

class SyncRunner {

    typealias SyncCompletion = (_ success: Bool) -> Void
    
    private let trackerDataService: TrackerDataService
    private let tempWhitelistDataService: TempWhitelistDataService
    private let trackerDataManager: TrackerDataManager
    private let blockerListManager: BlockerListManager
    
    init(trackerDataService: TrackerDataService = DefaultTrackerDataService(),
         tempWhitelistDataService: TempWhitelistDataService = DefaultTempWhitelistDataService(),
         trackerDataManager: TrackerDataManager = TrackerBlocking.Dependencies.shared.trackerDataManager,
         blockerListManager: BlockerListManager = TrackerBlocking.Dependencies.shared.blockerListManager) {
        
        self.trackerDataService = trackerDataService
        self.tempWhitelistDataService = tempWhitelistDataService
        self.trackerDataManager = trackerDataManager
        self.blockerListManager = blockerListManager
    }
    
    public func sync(completion: @escaping SyncCompletion) {
        os_log("Sync is starting")
        
        let group = DispatchGroup()
        
        let trackerData = ServiceWrapper(group: group)
        let tempWhitelistData = ServiceWrapper(group: group)
        
        trackerDataService.updateData(completion: trackerData.start())
        tempWhitelistDataService.updateData(completion: tempWhitelistData.start())
        
        group.wait()
                        
        if trackerData.newData || tempWhitelistData.newData {
            self.trackerDataManager.load()
            self.blockerListManager.updateAndReload()
            self.sendNewDataNotification()
        }
        
        // if either fail, don't store the sync time - we need that data!
        completion(trackerData.success && tempWhitelistData.success)
    }
    
    private func sendNewDataNotification() {
        DistributedNotificationCenter.default().postNotificationName(SyncNotification.newDataNotificationName,
                                                                     object: nil,
                                                                     userInfo: nil,
                                                                     deliverImmediately: true)
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
