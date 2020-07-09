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

import Cocoa
import SafariServices
import TrackerBlocking
import Statistics
import os

class MainDashboardViewController: DashboardNavigationController {

    enum ProtectionState {

        case on
        case disabled
        case off
        case enabled

    }

    let privacyPracticesImages: [PrivacyPractice.Summary: NSImage] = [
        .unknown: #imageLiteral(resourceName: "PP Icon Unknown"),
        .poor: #imageLiteral(resourceName: "PP Icon Bad"),
        .mixed: #imageLiteral(resourceName: "PP Icon Warning"),
        .good: #imageLiteral(resourceName: "PP Icon Check")
    ]

    let privacyPracticesText: [PrivacyPractice.Summary: String] = [
        .unknown: UserText.dashboardTOSUnknown,
        .good: UserText.dashboardTOSGood,
        .mixed: UserText.dashboardTOSMixed,
        .poor: UserText.dashboardTOSPoor
    ]

    let trustedSites: TrustedSitesManager = Dependencies.shared.trustedSitesManager
    let privacyPracticesManager: PrivacyPracticesManager = Dependencies.shared.privacyPracticesManager
    let blockerListManager: BlockerListManager = Dependencies.shared.blockerListManager

    @IBOutlet weak var siteTitle: NSTextField!
    @IBOutlet weak var enhancedStatementStack: NSView!
    @IBOutlet weak var enhancedStatementTextField: NSTextField!
    @IBOutlet weak var privacyGradeMessage: NSStackView!
    @IBOutlet weak var privacyGradeTextField: NSTextField!
    @IBOutlet weak var regularSitesMessage: NSView!
    @IBOutlet weak var regularSitesTextField: NSTextField!
    @IBOutlet weak var fromIcon: NSImageView!

    @IBOutlet weak var protectionToggle: NSSwitch!
    @IBOutlet weak var protectionBox: NSBox!
    @IBOutlet weak var protectionMessage: NSView!
    @IBOutlet weak var addedToUnprotectedSites: NSView!
    @IBOutlet weak var removedFromUnprotectedSites: NSView!

    @IBOutlet weak var bottomButtons: NSView!
    @IBOutlet weak var manageUnprotectedSitesCTA: NSView!
    @IBOutlet weak var reportBrokenSiteCTA: NSView!
    @IBOutlet weak var brokenYesNo: NSView!

    @IBOutlet weak var trackersLabel: NSTextField!
    @IBOutlet weak var encryptionLabel: NSTextField!
    @IBOutlet weak var privacyPracticesLabel: NSTextField!

    @IBOutlet weak var gradeIcon: NSImageView!
    @IBOutlet weak var trackersIcon: NSImageView!
    @IBOutlet weak var encryptionIcon: NSImageView!
    @IBOutlet weak var privacyPracticesIcon: NSImageView!

    var protection: ProtectionState = .on

    override var pageData: PageData? {
        didSet {
            guard isViewLoaded else { return }
            self.updateUI()
        }
    }
    
    var isTrusted: Bool {
        return pageData?.isTrusted ?? false
    }
    
    private var pixel = Dependencies.shared.pixel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(onTrustedSitesChanged),
                                                            name: TrustedSitesNotification.sitesUpdatedNotificationName,
                                                            object: nil)

        initTextFields()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        pageData = DashboardData.shared.pageData
    }
    
    @objc func onTrustedSitesChanged() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.blockerListManager.update()
            ContentBlockerExtension.reloadSync()
            DispatchQueue.main.async {
                self.updateUI()
                if let domain = self.trustedSites.lastChangedDomain {
                    self.reloadPages(with: domain)
                }
            }
        }
    }
    
    private func updateProtectionToggleState() {
        protectionToggle.state = isTrusted ? .off : .on
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        protection = isTrusted ? .on : .off
        updateProtectionToggleState()
        updateUI()
    }

    @IBAction func toggleProtection(_ sender: Any) {
        guard let url = pageData?.url else { return }
        
        if isTrusted {
            pixel.fire(.dashboardPrivacyProtectionToggleOn)
            trustedSites.removeDomain(forUrl: url)
            protection = .enabled
        } else {
            pixel.fire(.dashboardPrivacyProtectionToggleOff)
            trustedSites.addDomain(forUrl: url)
            protection = .disabled
        }
    }

    @IBAction func showTrackers(_ sender: Any) {
        pixel.fire(.dashboardTrackerNetworksOpened)
        navigationDelegate?.push(controller: .trackersDetail)
    }

    @IBAction func reportBrokenSite(_ sender: Any) {
        navigationDelegate?.present(controller: .reportBrokenWebsite)
    }

    @IBAction func manageUnprotectedSites(_ sender: Any) {
        pixel.fire(.dashboardUnprotectedSitesOpened)
        NSWorkspace.shared.open(URL(string: AppLinks.manageUnprotectedSites)!)
    }

    @IBAction func clearBrokenYesNo(_ sender: Any) {
        protection = isTrusted ? .on : .off
        updateUI()
    }

    private func initTextFields() {
        let textFields = [enhancedStatementTextField!, regularSitesTextField!, privacyGradeTextField!]

        textFields.forEach { $0.attributedStringValue = NSAttributedString(string: $0.stringValue, kern: NSAttributedString.headerKern) }
    }

    private func updateUI() {
        updateEncryptionStatus()
        updateStatement()
        updateTitle()
        updateProtectionStatus()
        updateGradeIcon()
        updateTrackersFound()
        updatePrivacyPractices()
    }

    private func updatePrivacyPractices() {
        privacyPracticesLabel.stringValue = UserText.dashboardTOSUnknown
        privacyPracticesIcon.image = privacyPracticesImages[.unknown]

        guard let url = pageData?.url else { return }
        let practices = privacyPracticesManager.findPrivacyPractice(forUrl: url)
        privacyPracticesIcon.image = privacyPracticesImages[practices.summary]
        privacyPracticesLabel.stringValue = privacyPracticesText[practices.summary] ?? ""
    }

    private func updateEncryptionStatus() {

        let isEncryptionEnabled: Bool
        let imageName: String
        if let url = pageData?.url {
            imageName = url.isEncrypted ? "PP Icon Check" : "PP Icon Bad"
            isEncryptionEnabled = url.isEncrypted
        } else {
            imageName = "PP Icon Unknown"
            isEncryptionEnabled = false
        }

        encryptionIcon.image = NSImage(named: NSImage.Name(imageName))
        encryptionLabel.stringValue = isEncryptionEnabled ? UserText.encryptionEnabled : UserText.encryptionDisabled

    }
    
    private func updateTrackersFound() {

        trackersLabel.stringValue = pageData?.trackersText ?? ""
        trackersIcon.image = pageData?.networksIcon

    }
    
    private func updateStatement() {
        regularSitesMessage.isHidden = pageData?.url != nil
        if let grade = pageData?.calculateGrade(), grade.site.grade != grade.enhanced.grade, !isTrusted {
            enhancedStatementStack.isHidden = false
            fromIcon.image = grade.site.grade.inlineImage
        } else {
            enhancedStatementStack.isHidden = true
        }
        privacyGradeMessage.isHidden = !enhancedStatementStack.isHidden
    }
    
    private func updateTitle() {
        siteTitle.stringValue = pageData?.url?.host?.replacingOccurrences(of: "www.", with: "") ?? "new tab"
    }
    
    private func updateProtectionStatus() {
        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.25
            context.allowsImplicitAnimation = true

            switch self.protection {

            case .on, .off:
                self.protectionMessage.isHidden = false
                self.addedToUnprotectedSites.isHidden = true
                self.removedFromUnprotectedSites.isHidden = true
                self.bottomButtons.isHidden = false
                self.brokenYesNo.isHidden = true

            case .disabled:
                self.protectionMessage.isHidden = true
                self.addedToUnprotectedSites.isHidden = false
                self.removedFromUnprotectedSites.isHidden = true
                self.bottomButtons.isHidden = true
                self.brokenYesNo.isHidden = false

            case .enabled:
                self.protectionMessage.isHidden = true
                self.addedToUnprotectedSites.isHidden = true
                self.removedFromUnprotectedSites.isHidden = false
                self.bottomButtons.isHidden = false
                self.brokenYesNo.isHidden = true

            }

            self.protectionBox.layoutSubtreeIfNeeded()
        }

    }

    private func updateGradeIcon() {
        gradeIcon.image = NSImage(named: NSImage.Name("PP Grade Null"))
        guard let grade = pageData?.calculateGrade(), pageData?.url != nil else { return }
        
        let trusted = isTrusted
        gradeIcon.image = trusted ? grade.site.grade.iconImage(trusted: trusted) : grade.enhanced.grade.iconImage(trusted: trusted)
    }
    
    private func reloadPages(with domain: String) {
        SFSafariApplication.getAllWindows { windows in
            windows.forEach { window in
                window.getAllTabs { tabs in
                    tabs.forEach { tab in
                        tab.getPagesWithCompletionHandler { pages in
                            pages?.forEach { page in
                                page.getPropertiesWithCompletionHandler { properties in
                                    if properties?.url?.host == domain {
                                        self.reloadPage(page)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func reloadPage(_ page: SFSafariPage) {
        page.dispatchMessageToScript(withName: "stopCheckingResources", userInfo: nil)
        page.reload()
        DashboardData.shared.clearCache(forPage: page, withUrl: self.pageData?.url?.absoluteString ?? "")
    }
}

extension Grade.Grading {

    static let inlineIcons: [Grade.Grading: NSImage] = [
        .a: NSImage(named: NSImage.Name("PP Inline A"))!,
        .bPlus: NSImage(named: NSImage.Name("PP Inline B Plus"))!,
        .b: NSImage(named: NSImage.Name("PP Inline B"))!,
        .cPlus: NSImage(named: NSImage.Name("PP Inline C Plus"))!,
        .c: NSImage(named: NSImage.Name("PP Inline C"))!,
        .d: NSImage(named: NSImage.Name("PP Inline D"))!
    ]

    static let icons: [Grade.Grading: String] = [
        .a: "PP Grade A",
        .bPlus: "PP Grade B Plus",
        .b: "PP Grade B",
        .cPlus: "PP Grade C Plus",
        .c: "PP Grade C",
        .d: "PP Grade D"
    ]
    
    var inlineImage: NSImage? {
        return Grade.Grading.inlineIcons[self]
    }
    
    func iconImage(trusted: Bool) -> NSImage? {
        guard let iconName = Grade.Grading.icons[self] else { return nil }
        let suffix = trusted ? "Off" : "On"
        let name = iconName + " " + suffix
        return NSImage(named: NSImage.Name(name))
    }
    
}

extension PageData {

    var networksIcon: NSImage? {
        let imageName: String
        if isTrusted {
            imageName = loadedTrackers.count == 0 ? "PP Icon Check" : "PP Icon Bad"
        } else {
            imageName = "PP Icon Check"
        }
        return NSImage(named: NSImage.Name(imageName))
    }

}
