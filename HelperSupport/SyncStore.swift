//
//  SyncStore.swift
//  HelperSupport
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

public protocol SyncStore {
    var lastSyncTimestamp: TimeInterval? { get set }
}

public class SyncUserDefaults: SyncStore {
    
    private struct Key {
        static var lastSyncTimestamp  = "com.duckduckgo.macos.privacyessentials.sync.lastsync"
    }
    
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    public var lastSyncTimestamp: TimeInterval? {
        get {
            return userDefaults.double(forKey: Key.lastSyncTimestamp)
        }
        set(syncTimestamp) {
            userDefaults.set(syncTimestamp, forKey: Key.lastSyncTimestamp)
        }
    }
}
