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
import os
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var debugMenu: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard !ProcessInfo().arguments.contains("testing") else { return }

        if Settings().firstRun {
            // No reload needed because this is the first time run
            TrackerBlocking.Dependencies.shared.blockerListManager.update()
        }
 
        removeOldSyncApp()
        
        #if DEBUG
        debugMenu.isHidden = false  
        #endif        
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        
        guard urls.count > 0 else { return }
        guard let controller = application.keyWindow?.windowController?.contentViewController as? MainViewController else { return }

        switch urls[0].absoluteString {
            
        case AppLinks.manageWhitelist:
            controller.selectTrustedSites(self)
            
        default:
            controller.selectHome(self)
            
        }
        
    }
    
    @IBAction func resetOnboarding(_ sender: Any) {
        Settings().onboardingShown = false
    }

    /// Probably not essential, but will remove the entry from the launchctl list as well, hopefully.
    private func removeOldSyncApp() {
        SMLoginItemSetEnabled(BundleIds.oldSyncApp as CFString, false)
    }

}
