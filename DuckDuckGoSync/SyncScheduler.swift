//
//  SyncScheduler.swift
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

public class SyncScheduler {
    
    private struct Constants {
        static let backgroundActivityId = "com.duckduckgo.macos.privacyessentials.sync.scheduler"
    }
    
    private struct SyncInterval {
        static let minimum: TimeInterval = 2 // 2 seconds is lowest we can use as we need to exceed minimum tolerance of 1
        static let defaultInterval: TimeInterval = 12 * 60 * 60 // 12 hours
    }
    
    private let activity = NSBackgroundActivityScheduler(identifier: Constants.backgroundActivityId)
    private var syncStore: SyncStore
    private let syncRunner: SyncRunner
    
    init(syncStore: SyncStore = SyncUserDefaults(), syncRunner: SyncRunner = SyncRunner()) {
        self.syncStore = syncStore
        self.syncRunner = syncRunner
        activity.invalidate()
    }
    
    public func schedule() {
        
        activity.repeats = true
        activity.qualityOfService = .background
        activity.interval = nextSync()
        os_log("Scheduling sync in %{public}gs", type: .info, activity.interval)

        activity.schedule { result in
            
            os_log("Sync scheduled", type: .debug)
            self.syncRunner.sync { success in
                os_log("Sync was %{public}s", type: .info, success ? "successful" : "unsuccessful")
                if success {
                    self.syncStore.lastSyncTimestamp = Date().timeIntervalSince1970
                }
                self.activity.interval = SyncInterval.defaultInterval
                result(.finished)
            }
        }
    }
    
    private func nextSync() -> TimeInterval {
        guard let lastSync = syncStore.lastSyncTimestamp, lastSync != 0 else {
            return SyncInterval.minimum
        }
        
        let elapsedTime = Date().timeIntervalSince1970 - lastSync
        let nextSync = SyncInterval.defaultInterval - elapsedTime
        guard nextSync >= SyncInterval.minimum else {
            return SyncInterval.minimum
        }
        
        return nextSync
    }
}
