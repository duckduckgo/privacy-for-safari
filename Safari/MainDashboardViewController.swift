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

class MainDashboardViewController: NSViewController {
 
    weak var navigationDelegate: DashboardNavigationDelegate?

    let trustedSites = TrustedSitesManager.shared

    @IBOutlet weak var trustedSitesLabel: NSTextField!
    @IBOutlet weak var urlLabel: NSTextField!
    
    weak var pageProperties: SFSafariPageProperties? {
        didSet {
            let url = pageProperties?.url?.absoluteString ?? "<unknown url>"
            DispatchQueue.main.async {
                self.urlLabel.stringValue = url
            }
        }
    }
    
    weak var activePage: SFSafariPage? {
        didSet {
            activePage?.getPropertiesWithCompletionHandler({ properties in
                self.pageProperties = properties
            })
        }
    }
    
    weak var activeTab: SFSafariTab? {
        didSet {
            activeTab?.getActivePage(completionHandler: { page in
                self.activePage = page
            })
        }
    }
    
    weak var safariWindow: SFSafariWindow? {
        didSet {
            safariWindow?.getToolbarItem(completionHandler: { toolbarItem in
                toolbarItem?.setImage(NSImage(named: NSImage.Name("ToolbarGradeA")))
            })
            safariWindow?.getActiveTab(completionHandler: { tab in
                self.activeTab = tab
            })
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        trustedSites.readFromUserDefaults()
        updateTrustedSitesLabel()
        safariWindow = navigationDelegate?.safariWindow
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
    
}
