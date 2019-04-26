//
//  SafariExtensionViewController.swift
//  Safari
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

import SafariServices
import os

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 300, height: 600)
        return shared
    }()
    
    @IBOutlet weak var tabs: NSTabView!
    @IBOutlet weak var searchField: NSTextField!
    
    weak var safariWindow: SFSafariWindow? {
        didSet {
            tabs.selectedTabViewItem?.viewController?.viewDidAppear()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMainDashboard()
    }
    
    @IBAction func performSearch(sender: Any) {
        guard !searchField.stringValue.isEmpty else {
            os_log("searchField stringValue is empty")
            return
        }

        guard let url = URL(withSearch: searchField.stringValue) else {
            os_log("unable to create search url")
            return
        }
        
        NSWorkspace.shared.open(url)
        dismissPopover()
    }
    
    private func installMainDashboard() {
        let dashboard: MainDashboardViewController = NSViewController.loadController(named: "MainDashboard", fromStoryboardNamed: "Dashboard")
        dashboard.navigationDelegate = self
        tabs.addTabViewItem(NSTabViewItem(viewController: dashboard))
    }
    
}

extension SafariExtensionViewController: DashboardNavigationDelegate {
    
    // To animate the tabs, clue here: https://stackoverflow.com/a/41415722/73479
    
    func push(controller: DashboardControllers) {
        let controller: DashboardNavigationController = NSViewController.loadController(named: controller.rawValue, fromStoryboardNamed: "Dashboard")
        controller.navigationDelegate = self
        tabs.addTabViewItem(NSTabViewItem(viewController: controller))
        tabs.selectTabViewItem(at: tabs.numberOfTabViewItems - 1)
        tabs.selectedTabViewItem?.viewController?.viewDidAppear()
    }
    
    func popController() {
        guard tabs.numberOfTabViewItems > 1,
            let item = tabs.selectedTabViewItem else {
            return
        }
        
        tabs.selectTabViewItem(at: tabs.numberOfTabViewItems - 2)
        tabs.removeTabViewItem(item)
        tabs.selectedTabViewItem?.viewController?.viewDidAppear()
    }
    
}
