//
//  TrackerDataServiceStore.swift
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

public protocol TrackerDataServiceStore {
    var etag: String? { get set }
}

public class TrackerDataServiceUserDefaults: TrackerDataServiceStore {
    
    private struct Key {
        static var etag = "com.duckduckgo.trackerservice.etag"
    }
    
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults(suiteName: TrackerDataLocation.groupName)!) {
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
