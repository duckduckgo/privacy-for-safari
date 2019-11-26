//
//  SyncScheduler.swift
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
import Statistics
import os

public class SyncScheduler {
    
    struct SyncInterval {
        #if DEBUG
        static let `default`: TimeInterval = 2 * 60 // 2 minutes
        #else
        static let `default`: TimeInterval = 30 * 60 // 30 minutes
        #endif
    }
    
    public static let shared = SyncScheduler()

    private let queue = DispatchQueue(label: "DuckDuckGo Sync")
    private var syncStore: SyncStore
    private let syncRunner: SyncRunner
    
    init(syncStore: SyncStore = SyncUserDefaults(), syncRunner: SyncRunner = SyncRunner()) {
        os_log("SyncScheduler init", log: lifecycleLog)
        self.syncStore = syncStore
        self.syncRunner = syncRunner
    }
    
    deinit {
        os_log("SyncScheduler deinit", log: lifecycleLog)
    }
    
    public func schedule() {
        queue.async {
            guard Self.isTimeToSync(lastSyncDateTime: self.syncStore.lastSyncTimestamp ?? 0) else { return }
            os_log("Scheduling sync", log: generalLog, type: .default)
            let group = DispatchGroup()
            group.enter()
            self.syncRunner.sync { success in
                os_log("Sync was %{public}s", log: generalLog, type: .default, success ? "successful" : "unsuccessful")
                if success {
                    self.syncStore.lastSyncTimestamp = Date().timeIntervalSince1970
                }
                group.leave()
            }
            
            if group.wait(timeout: .now() + 30) == .timedOut {
                Dependencies.shared.pixel.fire(.debugSyncTimeout)
            }
        }
    }

    static func isTimeToSync(currentDate: Date = Date(), lastSyncDateTime: TimeInterval) -> Bool {
        let diff = currentDate.timeIntervalSince1970 - lastSyncDateTime
        return diff > SyncInterval.default
    }
    
}
