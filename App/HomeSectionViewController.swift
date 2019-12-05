//
//  HomeSectionViewController.swift
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
import AppKit
import SafariServices
import Statistics

class HomeSectionViewController: NSViewController {
        
    @IBOutlet weak var versionLabel: NSTextField!
    
    @IBOutlet weak var protectionStateIcon: NSImageView!
    @IBOutlet weak var protectionEnabledLabel: NSTextField!
    @IBOutlet weak var protectionEnableButton: NSButton!
    
    @IBOutlet weak var dashboardStateIcon: NSImageView!
    @IBOutlet weak var dashboardEnabledLabel: NSTextField!
    @IBOutlet weak var dashboardEnableButton: NSButton!
    
    var extensionsState: ExtensionsStateWatcher?
    
    private let pixel = Dependencies.shared.pixel
    private var dashboardEnabled: Bool?
    private var cbEnabled: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let string = dashboardEnabledLabel.stringValue
        dashboardEnabledLabel.attributedStringValue = NSAttributedString(string: string, kern: 1.5)
        protectionEnabledLabel.attributedStringValue = dashboardEnabledLabel.attributedStringValue
        
        versionLabel.attributedStringValue = Utils.versionLabelAttributedString()
        extensionsState = ExtensionsStateWatcher(delegate: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        extensionsState?.refresh()
        refreshUI()
    }
    
    @IBAction func showProtectionPrefences(_ sender: Any?) {
        pixel.fire(.homeOpenSafariToEnableCb)
        extensionsState?.showContentBlockerExtensionPreferences()
    }

    @IBAction func showDashboardPreferences(_ sender: Any?) {
        pixel.fire(.homeOpenSafariToEnableDashboard)
        extensionsState?.showSafariExtensionPreferences()
    }
    
    @IBAction func showSearchPreferences(_ sender: Any?) {
        pixel.fire(.homeOpenSafariForSearch)
        extensionsState?.showSafariExtensionPreferences()
    }
    
    @IBAction func help(_ sender: Any?) {
        pixel.fire(.homeHelpOpened)
        NSWorkspace.shared.open(URL(string: "https://help.duckduckgo.com/desktop/safari/")!)
    }

    private func refreshUI() {
        
        protectionStateIcon.image = activeIcon(extensionsState?.protectionState == .some(.enabled))
        dashboardStateIcon.image = activeIcon(extensionsState?.dashboardState == .some(.enabled))
        
        protectionEnableButton.isHidden = extensionsState?.protectionState == .some(.enabled)
        protectionEnabledLabel.isHidden = extensionsState?.protectionState != .some(.enabled)

        dashboardEnableButton.isHidden = extensionsState?.dashboardState == .some(.enabled)
        dashboardEnabledLabel.isHidden = extensionsState?.dashboardState != .some(.enabled)

    }
    
    private func activeIcon(_ enabled: Bool) -> NSImage? {
        let state = enabled ? "Active" : "Inactive"
        return NSImage(named: NSImage.Name("Extension" + state))
    }
    
    func sendStateChangePixels(dashboardEnabled: Bool, cbEnabled: Bool) {
        
        defer {
            self.dashboardEnabled = dashboardEnabled
            self.cbEnabled = cbEnabled
        }
        
        guard let previousDashboardEnabled = self.dashboardEnabled, let previousCbEnabled = self.cbEnabled else {
            return
        }
        
        if previousDashboardEnabled && !dashboardEnabled {
            pixel.fire(.homeDashboardDisabled)
        }
        if !previousDashboardEnabled && dashboardEnabled {
            pixel.fire(.homeDashboardEnabled)
        }
        if previousCbEnabled && !cbEnabled {
            pixel.fire(.homeCbDisabled)
        }
        if !previousCbEnabled && cbEnabled {
            pixel.fire(.homeCbEnabled)
        }
    }
}

extension HomeSectionViewController: ExtensionsStateWatcher.Delegate {
    
    func stateUpdated(watcher: ExtensionsStateWatcher) {
        DispatchQueue.main.async {
            self.sendStateChangePixels(dashboardEnabled: watcher.dashboardState  == .enabled, cbEnabled: watcher.protectionState  == .enabled)
            self.refreshUI()
        }
    
    }
}
