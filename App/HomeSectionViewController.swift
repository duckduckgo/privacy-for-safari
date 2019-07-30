//
//  HomeSectionViewController.swift
//  DuckDuckGo
//
//  Created by Chris Brind on 20/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit
import SafariServices

class HomeSectionViewController: NSViewController {
    
    struct ViewHeights {
        static let homeThanksView: CGFloat = 401
        static let homeDiscoverView: CGFloat = 322
        static let homeButtonsView: CGFloat = 20
        static let homeProtectedView: CGFloat = 250
    }
    
    @IBOutlet weak var stack: NSStackView!
    @IBOutlet weak var stackHeight: NSLayoutConstraint!
    @IBOutlet weak var homeThanksView: NSView!
    @IBOutlet weak var homeDiscoverView: NSView!
    @IBOutlet weak var homeButtonsView: NSView!
    @IBOutlet weak var homeProtectedView: NSView!
    @IBOutlet weak var protectionButton: NSButton!
    
    var detectionTimer: Timer?
    
    var protectionEnabled = false {
        didSet {
            if protectionEnabled != oldValue { refreshUI() }
        }
    }
    
    var dashboardEnabled = false {
        didSet {
            if dashboardEnabled != oldValue { refreshUI() }
        }
    }
    
    var hasTopOffenders = false {
        didSet {
            if hasTopOffenders != oldValue { refreshUI() }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stack.addArrangedSubview(homeThanksView)
        stack.addArrangedSubview(homeDiscoverView)
        stack.addArrangedSubview(homeButtonsView)
        stack.addArrangedSubview(homeProtectedView)
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        refreshUI()
        refreshProtectionState()
        refreshDashboardState()

        view.window?.defaultButtonCell = protectionButton.cell as? NSButtonCell
        
        startDetection()
    }
    
    @IBAction func showPrivacyPreferences(_ sender: Any) {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlockerExtension"
        SFSafariApplication.showPreferencesForExtension(withIdentifier: id)
    }
    
    @IBAction func showDashboardPreferences(_ sender: Any) {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".SafariAppExtension"
        SFSafariApplication.showPreferencesForExtension(withIdentifier: id)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        print(#function, segue)
    }
    
    private func refreshProtectionState() {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlockerExtension"
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: id) { state, _ in
            DispatchQueue.main.async {
                self.protectionEnabled = state?.isEnabled ?? false
                self.startDetection()
                self.bringUserBack()
            }
        }
    }
    
    private func refreshDashboardState() {
        let id = (Bundle.main.bundleIdentifier ?? "") + ".SafariAppExtension"
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: id) { state, _ in
            DispatchQueue.main.async {
                self.dashboardEnabled = state?.isEnabled ?? false
                self.startDetection()
                self.bringUserBack()
            }
        }
    }
    
    private func startDetection() {
        print(#function, protectionEnabled, dashboardEnabled)
        if !protectionEnabled || !dashboardEnabled {
            detectionTimer?.invalidate()

            detectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                print("timer!")
                DispatchQueue.main.async {
                    self.refreshProtectionState()
                    self.refreshDashboardState()
                }
            })

        }
    }

    private func bringUserBack() {
        print(#function, protectionEnabled, dashboardEnabled)
        if protectionEnabled && dashboardEnabled {
            detectionTimer?.invalidate()
            detectionTimer = nil
            view.window?.orderFrontRegardless()
        }
        
    }
    
    private func refreshUI() {
        
        homeThanksView.isHidden = protectionEnabled
        homeDiscoverView.isHidden = !protectionEnabled || dashboardEnabled
        homeButtonsView.isHidden = protectionEnabled && dashboardEnabled
        homeProtectedView.isHidden = !protectionEnabled || !dashboardEnabled
        protectionButton.isHidden = protectionEnabled
        
        var height: CGFloat = 0
        height += homeThanksView.isHidden ? 0 : ViewHeights.homeThanksView
        height += homeDiscoverView.isHidden ? 0 : ViewHeights.homeDiscoverView
        height += homeButtonsView.isHidden ? 0 : ViewHeights.homeButtonsView
        height += homeProtectedView.isHidden ? 0 : ViewHeights.homeProtectedView
        stackHeight.constant = height
        
    }
  
}
