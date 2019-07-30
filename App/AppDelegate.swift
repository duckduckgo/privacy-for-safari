//
//  AppDelegate.swift
//  DuckDuckGo
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

import Cocoa
import TrackerBlocking
import Statistics
import SafariServices

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard !ProcessInfo().arguments.contains("testing") else { return }
        
        let trackerBlocking = TrackerBlocking.Dependencies.shared
        
        StatisticsLoader().refreshAppRetentionAtb(atLocation: "ad") {
            print(#function, "atb refreshed")
        }
        
        trackerBlocking.trackerDataManager.update {
            trackerBlocking.blockerListManager.updateAndReload()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        print(#function, urls)
    }

}
