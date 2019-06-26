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
import Statistics

class MainViewController: NSViewController {
    
    @IBOutlet var tabs: NSTabView!
    @IBOutlet var sectionButtons: NSStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSectionButtonSelected(atIndex: 0)
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "Home", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "SendFeedback", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "TrustedSites", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "GlobalStats", fromStoryboardNamed: "Main")))

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
        Dependencies.shared.statisticsLoader.refreshAppRetentionAtb(atLocation: "mvc", completion: nil)
    }

    @IBAction func selectHome(_ sender: NSClickGestureRecognizer) {
        print(#function, sender)
        deselectAllSectionButtons()
        selectSectionButton(from: sender)
        tabs.selectTabViewItem(at: 0)
    }

    @IBAction func selectSendFeedback(_ sender: NSClickGestureRecognizer) {
        print(#function, sender)
        deselectAllSectionButtons()
        selectSectionButton(from: sender)
        tabs.selectTabViewItem(at: 1)
    }

    @IBAction func selectGlobalStats(_ sender: NSClickGestureRecognizer) {
        print(#function, sender)
        deselectAllSectionButtons()
        selectSectionButton(from: sender)
        tabs.selectTabViewItem(at: 2)
    }

    @IBAction func selectTrustedSites(_ sender: NSClickGestureRecognizer) {
        print(#function, sender)
        deselectAllSectionButtons()
        selectSectionButton(from: sender)
        tabs.selectTabViewItem(at: 3)
    }

    private func selectSectionButton(from gestureRecognizer: NSClickGestureRecognizer) {
        let button = gestureRecognizer.view as? SectionButton
        button?.selected()
    }
    
    private func deselectAllSectionButtons() {
        sectionButtons.arrangedSubviews.compactMap { $0 as? SectionButton }.forEach { sectionButton in
            sectionButton.deselected()
        }
    }
    
    private func setSectionButtonSelected(atIndex index: Int) {
        (sectionButtons.arrangedSubviews[index] as? SectionButton)?.selected()
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
