//
//  WelcomeViewController.swift
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
import SafariServices

class WelcomeViewController: NSViewController {

    let contentBlocker = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlocker"
    let appExtension = (Bundle.main.bundleIdentifier ?? "") + ".Safari"

    @IBOutlet weak var dashboardProgress: NSProgressIndicator!
    @IBOutlet weak var protectionProgress: NSProgressIndicator!
    @IBOutlet weak var dashboardEnabled: NSImageView!
    @IBOutlet weak var protectionEnabled: NSImageView!
    @IBOutlet weak var dashboardWarning: NSButton!
    @IBOutlet weak var protectionWarning: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dashboardWarning.isHidden = true
        dashboardEnabled.isHidden = true

        protectionWarning.isHidden = true
        protectionEnabled.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        refreshExtensionStates()
    }

    func refreshExtensionStates() {
        updateContentBlockerState()
        updateAppExtensionState()
    }
    
    func updateAppExtensionState() {
        dashboardProgress.startAnimation(self)
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: appExtension) { state, _ in
            DispatchQueue.main.async {
                let enabled = state?.isEnabled ?? false
                self.dashboardEnabled.isHidden = !enabled
                self.dashboardWarning.isHidden = enabled
                self.dashboardProgress.stopAnimation(self)
            }
        }
    }
    
    func updateContentBlockerState() {
        protectionProgress.startAnimation(self)
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: contentBlocker) { state, _ in
            DispatchQueue.main.async {
                let enabled = state?.isEnabled ?? false
                self.protectionEnabled.isHidden = !enabled
                self.protectionWarning.isHidden = enabled
                self.protectionProgress.stopAnimation(self)
            }
        }
    }
    
    @IBAction func showContentBlockerPreferences(sender: Any) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: contentBlocker)
    }

    @IBAction func showAppExtensionPreferences(sender: Any) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: appExtension)
    }

}
