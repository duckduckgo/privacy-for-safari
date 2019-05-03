//
//  MainDashboardViewController.swift
//  Safari App Extension
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

import os
import Cocoa
import SafariServices
import TrackerBlocking

class MainDashboardViewController: NSViewController {
 
    weak var navigationDelegate: DashboardNavigationDelegate?

    let trustedSites = TrustedSitesManager.shared

    @IBOutlet weak var trustedSitesLabel: NSTextField!
    @IBOutlet weak var urlLabel: NSTextField!
    @IBOutlet weak var entities: NSTextView!

    var pageData: PageData! {
        didSet {
            updateUI()
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        trustedSites.readFromUserDefaults()
        updateTrustedSitesLabel()
    }
    
    @IBAction func clearTrustedSites(sender: Any) {
        trustedSites.clear()
        updateTrustedSitesLabel()
    }
    
    @IBAction func next(sender: Any) {
        navigationDelegate?.push(controller: .privacyScoreCard)
    }

    private func updateTrustedSitesLabel() {
        trustedSitesLabel.stringValue = "\(trustedSites.count) trusted sites"
    }

    private func updateUI() {
        urlLabel.stringValue = pageData.url?.host ?? "No URL"
        entities.string = String(describing: pageData.notBlockedEntities)
    }

}
