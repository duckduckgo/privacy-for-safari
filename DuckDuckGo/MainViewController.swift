//
//  ViewController.swift
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
import os

class MainViewController: NSViewController {

    struct Constants {
        
        static let selectedImage = NSImage(named: NSImage.Name("NSStatusNone"))
        static let unselectedImage: NSImage? = nil
        
    }
    
    @IBOutlet weak var homeSelectionImage: NSImageView!
    @IBOutlet weak var settingsSelectionImage: NSImageView!
    @IBOutlet weak var tabs: NSTabView!
    @IBOutlet weak var searchField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tabs.tabViewBorderType = .line
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "Welcome", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "Settings", fromStoryboardNamed: "Main")))

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
    }
    
    @IBAction func selectHome(_ sender: Any) {
        guard homeSelectionImage.image != Constants.selectedImage else {
            return
        }
        
        homeSelectionImage.image = Constants.selectedImage
        settingsSelectionImage.image = Constants.unselectedImage
        tabs.selectTabViewItem(at: 0)
    }
    
    @IBAction func selectSettings(_ sender: Any) {
        guard settingsSelectionImage.image != Constants.selectedImage else {
            return
        }
        
        homeSelectionImage.image = Constants.unselectedImage
        settingsSelectionImage.image = Constants.selectedImage
        tabs.selectTabViewItem(at: 1)
    }
    
    @IBAction func performSearch(_ sender: Any) {
        guard !searchField.stringValue.isEmpty else {
            os_log("searchField stringValue is empty")
            return
        }
        
        guard let url = URL(withSearch: searchField.stringValue) else {
            os_log("unable to create search url")
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
}

extension MainViewController: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(self)
    }
    
    func windowDidBecomeMain(_ notification: Notification) {
        guard let item = tabs.selectedTabViewItem else { return }
        item.viewController?.viewDidAppear()
    }
    
}
