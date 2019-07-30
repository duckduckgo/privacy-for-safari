//
//  TrackerBlockingDependencies.swift
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

public protocol TrackerBlockingDependencies {

    var trustedSitesManager: TrustedSitesManager { get }
    var trackerDetection: TrackerDetection { get }
    var privacyPracticesManager: PrivacyPracticesManager { get }
    var trackerDataManager: TrackerDataManager { get }
    var blockerListManager: BlockerListManager { get }
    
}

public class Dependencies: TrackerBlockingDependencies {
    
    public static var shared: TrackerBlockingDependencies = Dependencies()

    public let trustedSitesManager: TrustedSitesManager
    public let trackerDetection: TrackerDetection
    public let privacyPracticesManager: PrivacyPracticesManager
    public let trackerDataManager: TrackerDataManager
    public let blockerListManager: BlockerListManager
    
    init() {
        var trustedSitesManager: TrustedSitesManager!
        var trackerDetection: TrackerDetection!
        var privacyPracticesManager: PrivacyPracticesManager!
        var trackerDataManager: TrackerDataManager!
        var blockerListManager: BlockerListManager!
        
        privacyPracticesManager = DefaultPrivacyPracticesManager()
        trackerDataManager = DefaultTrackerDataManager()
        trackerDetection = DefaultTrackerDetection(trackerDataManager: { trackerDataManager })
        blockerListManager = DefaultBlockerListManager(trackerDataManager: { trackerDataManager }, trustedSitesManager: { trustedSitesManager })
        trustedSitesManager = DefaultTrustedSitesManager(blockerListManager: { blockerListManager })

        self.trustedSitesManager = trustedSitesManager
        self.trackerDetection = trackerDetection
        self.privacyPracticesManager = privacyPracticesManager
        self.trackerDataManager = trackerDataManager
        self.blockerListManager = blockerListManager
    }
    
}
