//
//  ReportBrokenSiteController.swift
//  SafariAppExtension
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

import AppKit
import Core
import TrackerBlocking
import Statistics
import Feedback

class ReportBrokenSiteController: DashboardNavigationController {
    
    @IBOutlet weak var runTestsView: NSView!
    @IBOutlet weak var popupBackground: NSBox!
    @IBOutlet weak var popupMenu: NSPopUpButton!
    @IBOutlet weak var submitButton: NSBox!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var bodyLabel: NSTextField!
    @IBOutlet weak var infoLabel: NSTextField!
    @IBOutlet weak var describeLabel: NSTextField!

    var buttonEnabled: Bool {
        return popupMenu.indexOfSelectedItem != 0
    }

    // https://github.com/duckduckgo/duckduckgo-privacy-extension/blob/develop/shared/js/ui/templates/breakage-form.es6.js#L2
    var categories: [(text: String, value: String)] = []
    
    var category: String? {
        return categories[popupMenu.indexOfSelectedItem].value
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        runTestsView.isHidden = false
        #endif
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        showThankYouState(false)
        updatePopupMenu()
        updateButton()
    }

    override func back(sender: Any) {
        navigationDelegate?.closeController()
    }
    
    @IBAction func startTests(sender: Any?) {
        DiagnosticSupport.executeBlockingTest()
    }

    @IBAction func selectionChanged(sender: Any?) {
        updateButton()
    }

    @IBAction func submitClicked(sender: Any?) {
        NSLog("\(#function), \(buttonEnabled)")
        guard buttonEnabled else { return }
        showThankYouState(true)
        submit()
    }
    
    private func updatePopupMenu() {
        popupMenu.removeAllItems()
        
        categories = [
               (text: UserText.brokenSiteCategoryImages, value: "images"),
               (text: UserText.brokenSiteCategoryPaywall, value: "paywall"),
               (text: UserText.brokenSiteCategoryComments, value: "comments"),
               (text: UserText.brokenSiteCategoryVideos, value: "videos"),
               (text: UserText.brokenSiteCategoryLinks, value: "links"),
               (text: UserText.brokenSiteCategoryContent, value: "content"),
               (text: UserText.brokenSiteCategoryLogin, value: "login")
        ].shuffled()
        
        categories.insert((text: UserText.brokenSiteCategorySelect, value: ""), at: 0)
        categories.append((text: UserText.brokenSiteCategoryOther, value: "Other"))
        popupMenu.addItems(withTitles: categories.map { $0.text })
        popupMenu.selectItem(at: 0)
    }

    private func updateButton() {
        submitButton.fillColor = buttonEnabled ? NSColor.brokenSiteButtonEnabled : NSColor.brokenSiteButtonDisabled
    }

    private func showThankYouState(_ state: Bool) {

        if state {
            titleLabel.stringValue = UserText.dashboardBrokenSiteThankYouTitle
            bodyLabel.stringValue = UserText.dashboardBrokenSiteThankYouBody
        } else {
            titleLabel.stringValue = UserText.dashboardBrokenSiteSubmitTitle
            bodyLabel.stringValue = UserText.dashboardBrokenSiteSubmitBody
        }

        popupBackground.isHidden = state
        infoLabel.isHidden = state
        describeLabel.isHidden = state
        submitButton.isHidden = state
    }
    
    private func submit() {
        guard let pageData = pageData else { return }
        guard let url = pageData.url else { return }
        guard let category = category else { return }
        
        BrokenSiteReporter().reportBreakageOn(url: url, withBlockedTrackers: pageData.blockedTrackers, inCategory: category)
    }
    
}
