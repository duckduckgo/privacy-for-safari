//
//  Dependencies.swift
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

public protocol TrackerBlockerDependencies {

    var trustedSitesManager: TrustedSitesManager { get }
    var trackerDetection: TrackerDetection { get }
    var privacyPracticesManager: PrivacyPracticesManager { get }
    var trackerDataManager: TrackerDataManager { get }
    var blockerListManager: BlockerListManager { get }
    
}

public class Dependencies: TrackerBlockerDependencies {
    
    public static var shared: TrackerBlockerDependencies = Dependencies()

    public let trustedSitesManager: TrustedSitesManager = DefaultTrustedSitesManager()
    public let trackerDetection: TrackerDetection = DefaultTrackerDetection()
    public let privacyPracticesManager: PrivacyPracticesManager = DefaultPrivacyPracticesManager()
    public let trackerDataManager: TrackerDataManager = DefaultTrackerDataManager()
    public let blockerListManager: BlockerListManager = DefaultBlockerListManager()
    
}
