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
        if Settings().onboardingShown {
            initTabs()
        } else {
            showOnboarding()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
        StatisticsLoader().refreshAppRetentionAtb(atLocation: "mvc", completion: nil)
    }

    @IBAction func selectHome(_ sender: Any) {
        print(#function, sender)
        deselectAllSectionButtons()
        tabs.selectTabViewItem(at: 0)
        setSectionButtonSelected(atIndex: 0)
    }

    @IBAction func selectSendFeedback(_ sender: Any) {
        print(#function, sender)
        deselectAllSectionButtons()
        tabs.selectTabViewItem(at: 2)
        setSectionButtonSelected(atIndex: 2)
    }

    @IBAction func selectTrustedSites(_ sender: Any) {
        print(#function, sender)
        deselectAllSectionButtons()
        tabs.selectTabViewItem(at: 1)
        setSectionButtonSelected(atIndex: 1)
    }
    
    @IBAction func resetOnboarding(_ sender: Any) {
        Settings().onboardingShown = false
    }

    private func deselectAllSectionButtons() {
        sectionButtons.arrangedSubviews.compactMap { $0 as? SectionButton }.forEach { sectionButton in
            sectionButton.deselected()
        }
    }
    
    private func setSectionButtonSelected(atIndex index: Int) {
        (sectionButtons.arrangedSubviews[index] as? SectionButton)?.selected()
    }
    
    private func initTabs() {
        setSectionButtonSelected(atIndex: 0)
        
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "Home", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "TrustedSites", fromStoryboardNamed: "Main")))
        tabs.addTabViewItem(NSTabViewItem(viewController: NSViewController.loadController(named: "SendFeedback", fromStoryboardNamed: "Main")))
    }
    
    private func showOnboarding() {
        let onboardingStoryboard = NSStoryboard(name: NSStoryboard.Name("Onboarding"), bundle: nil)
        guard let onboardingVC = onboardingStoryboard.instantiateInitialController() as? OnboardingPageController else {
            fatalError("Failed to load OnboardingPageController")
        }
        view.addSubview(onboardingVC.view)
        addChild(onboardingVC)
        onboardingVC.finishedDelegate = self
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

extension MainViewController: OnboardingFinishedDelegate {
    
    func finished(onboardingVC: OnboardingPageController) {
        onboardingVC.view.removeFromSuperview()
        onboardingVC.removeFromParent()
        initTabs()
        Settings().onboardingShown = true
    }
    
}
