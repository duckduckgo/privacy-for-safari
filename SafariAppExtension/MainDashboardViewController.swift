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

class MainDashboardViewController: DashboardNavigationController {

    enum ProtectionState {

        case on
        case disabled
        case off
        case enabled

    }

    let trustedSites: TrustedSitesManager = Dependencies.shared.trustedSitesManager

    @IBOutlet weak var siteTitle: NSTextField!
    @IBOutlet weak var enhancedStatementStack: NSView!
    @IBOutlet weak var regularSitesMessage: NSView!
    @IBOutlet weak var fromIcon: NSImageView!
    @IBOutlet weak var toIcon: NSImageView!

    @IBOutlet weak var protectionToggle: NSButton!
    @IBOutlet weak var protectionBox: NSBox!
    @IBOutlet weak var protectionMessage: NSView!
    @IBOutlet weak var addedToWhitelist: NSView!
    @IBOutlet weak var removedFromWhitelist: NSView!

    @IBOutlet weak var bottomButtons: NSView!
    @IBOutlet weak var manageWhitelistCTA: NSView!
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
            NSLog("MDVC pageDataSet \(isViewLoaded)")
            if isViewLoaded {
                updateUI()
            }
        }
    }
    
    var isTrusted: Bool {
        return pageData?.isTrusted ?? false
    }
    
    override func viewWillAppear() {
        NSLog("MDVC viewWillAppear \(pageData as Any)")
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        NSLog("MDVC viewDidAppear \(pageData as Any)")
        super.viewDidAppear()
        trustedSites.load()
        protection = isTrusted ? .on : .off
        updateUI()
    }

    @IBAction func toggleProtection(_ sender: Any) {
        guard let url = pageData?.url else { return }
        
        if isTrusted {
            trustedSites.removeDomain(forUrl: url)
            protection = .enabled
        } else {
            trustedSites.addDomain(forUrl: url)
            protection = .disabled
        }

        DispatchQueue.global(qos: .background).async {
            self.trustedSites.save()
        }

        updateUI()
        reloadPage()
    }

    @IBAction func showScoreCard(_ sender: Any) {
        navigationDelegate?.push(controller: .scoreCard)
    }

    @IBAction func showTrackers(_ sender: Any) {
        navigationDelegate?.push(controller: .trackersDetail)
    }

    @IBAction func showPrivacyPracties(_ sender: Any) {
        navigationDelegate?.push(controller: .privacyPractices)
    }

    @IBAction func reportBrokenSite(_ sender: Any) {
        navigationDelegate?.push(controller: .reportBrokenWebsite)
    }

    @IBAction func manageWhitelist(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: AppLinks.manageWhitelist)!)
    }

    @IBAction func clearBrokenYesNo(_ sender: Any) {
        protection = isTrusted ? .on : .off
        updateUI()
    }

    private func updateUI() {
        NSLog("MDVC updateUI")
        updateEncryptionStatus()
        updateStatement()
        updateTitle()
        updateProtectionStatus()
        updateGradeIcon()
        updateTrackersFound()
    }

    private func updateEncryptionStatus() {

        let isEncryptionEnabled: Bool
        let imageName: String
        if let url = pageData?.url {
            imageName = url.isEncrypted ? "PP Icon Connection On" : "PP Icon Connection Bad"
            isEncryptionEnabled = url.isEncrypted
        } else {
            imageName = "PP Icon Connection Off"
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
            toIcon.image = grade.enhanced.grade.inlineImage
        } else {
            enhancedStatementStack.isHidden = true
        }
    }
    
    private func updateTitle() {
        siteTitle.stringValue = pageData?.url?.host?.replacingOccurrences(of: "www.", with: "") ?? "new tab"
    }
    
    private func updateProtectionStatus() {

        if isTrusted {
            protectionBox.fillColor = NSColor(named: NSColor.Name("ProtectionToggleOff")) ?? NSColor.red
            (protectionToggle.cell as? NSButtonCell)?.state = .off
        } else {
            protectionBox.fillColor = NSColor(named: NSColor.Name("ProtectionToggleOn")) ?? NSColor.red
            (protectionToggle.cell as? NSButtonCell)?.state = .on
        }

        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.25
            context.allowsImplicitAnimation = true

            switch self.protection {

            case .on, .off:
                self.protectionMessage.isHidden = false
                self.addedToWhitelist.isHidden = true
                self.removedFromWhitelist.isHidden = true
                self.bottomButtons.isHidden = false
                self.brokenYesNo.isHidden = true

            case .disabled:
                self.protectionMessage.isHidden = true
                self.addedToWhitelist.isHidden = false
                self.removedFromWhitelist.isHidden = true
                self.bottomButtons.isHidden = true
                self.brokenYesNo.isHidden = false

            case .enabled:
                self.protectionMessage.isHidden = true
                self.addedToWhitelist.isHidden = true
                self.removedFromWhitelist.isHidden = false
                self.bottomButtons.isHidden = false
                self.brokenYesNo.isHidden = true

            }

            self.protectionBox.layoutSubtreeIfNeeded()
        }

    }

    private func updateGradeIcon() {
        NSLog("updateGradeIcon")
        gradeIcon.image = NSImage(named: NSImage.Name("PP Grade Null"))
        guard let grade = pageData?.calculateGrade(), pageData?.url != nil else {
            NSLog("updateGradeIcon -> null")
            return
        }
        
        let trusted = isTrusted
        gradeIcon.image = trusted ? grade.site.grade.iconImage(trusted: trusted) : grade.enhanced.grade.iconImage(trusted: trusted)
    }
    
    private func reloadPage() {
        SFSafariApplication.getActiveWindow { window in
            window?.getActiveTab(completionHandler: { tab in
                tab?.getActivePage(completionHandler: { page in
                    page?.reload()
                })
            })
        }
    }
}

extension Grade.Grading {

    static let inlineIcons: [Grade.Grading: NSImage] = [
        .a: NSImage(named: NSImage.Name("PP Inline A"))!,
        .bPlus: NSImage(named: NSImage.Name("PP Inline B Plus"))!,
        .b: NSImage(named: NSImage.Name("PP Inline B"))!,
        .cPlus: NSImage(named: NSImage.Name("PP Inline C Plus"))!,
        .c: NSImage(named: NSImage.Name("PP Inline C"))!,
        .d: NSImage(named: NSImage.Name("PP Inline D"))!,
        .dMinus: NSImage(named: NSImage.Name("PP Inline D"))!
    ]

    static let icons: [Grade.Grading: String] = [
        .a: "PP Grade A ",
        .bPlus: "PP Grade B Plus ",
        .b: "PP Grade B ",
        .cPlus: "PP Grade C Plus ",
        .c: "PP Grade C ",
        .d: "PP Grade D ",
        .dMinus: "PP Grade D"
    ]
    
    var inlineImage: NSImage? {
        return Grade.Grading.inlineIcons[self]
    }
    
    func iconImage(trusted: Bool) -> NSImage? {
        guard let iconName = Grade.Grading.icons[self] else {
            NSLog("No image for \(self)")
            return nil
        }
        let suffix = trusted ? "Off" : "On"
        let name = iconName + suffix
        NSLog("heroImage named \(name)")
        return NSImage(named: NSImage.Name(name))
    }
    
}

extension PageData {

    var networksIcon: NSImage? {
        let imageName: String
        if isTrusted {
            imageName = loadedTrackers.count == 0 ? "PP Icon Major Networks Off" : "PP Icon Major Networks Bad"
        } else {
            imageName = "PP Icon Major Networks On"
        }
        return NSImage(named: NSImage.Name(imageName))
    }

}
