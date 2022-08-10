//
//  MainDashboardViewModel.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import Foundation
import AppKit
import TrackerBlocking
import SwiftUI

class MainDashboardViewModel: ObservableObject {

    enum Icons {

        static let unknown = "PP Icon Unknown"
        static let gray = "PP Icon Info"
        static let green = "PP Icon Check"
        static let red = "PP Icon Bad"

    }

    enum Strings {

        static let requestsBlockedFromLoading = UserText.dashboardRequestsBlockedFromLoading
        static let noTrackingRequestsFound = UserText.dashboardNoTrackingRequestsFound
        static let noTrackingRequestsBlocked = UserText.dashboardNoTrackingRequestsBlocked

        static let thirdPartyRequestsLoaded = UserText.dashboardThirdPartyRequestsLoaded
        static let noThirdPartyRequestsLoaded = UserText.dashboardNoThirdPartyRequestsLoaded

        static let privacyPracticesUnknown = UserText.dashboardTOSUnknown
        static let privacyPracticesGood = UserText.dashboardTOSGood
        static let privacyPracticesPoor = UserText.dashboardTOSPoor
        static let privacyPracticesMixed = UserText.dashboardTOSMixed

    }

    @Published var isItBrokenShowing = false

    // These initial values largely don't matter, and are reset in the assignDefaults func
    @Published var isNewTab = true
    @Published var gradeHeroImage = ""
    @Published var domain = UserText.dashboardSiteIsNewTab
    @Published var protectionsEnabled = true
    @Published var temporarilyDisabled = false
    @Published var enhancedFromGrade: String? = ""

    @Published var encryptionStatusText = ""
    @Published var encryptionStatusIcon = Icons.unknown

    @Published var trackersBlockedText = ""
    @Published var trackersBlockedIcon = Icons.unknown

    @Published var requestsLoadedText = ""
    @Published var requestsLoadedIcon = Icons.gray

    @Published var privacyPracticesText = ""
    @Published var privacyPracticesIcon = Icons.unknown

    @Published var state: String = "??"

    let trustedSitesManager: TrustedSitesManager

    init(trustedSitesManager: TrustedSitesManager = Dependencies.shared.trustedSitesManager) {
        self.trustedSitesManager = trustedSitesManager
        assignDefaults()
    }

    var pageData: PageData?

    func updateFromPageData(_ pageData: PageData?) {
        os_log("MDVM updateFromPageData %{public}s", log: generalLog, type: .debug,
               "\(pageData as Any) \(pageData?.loadedTrackers.count ?? -1) \(pageData?.blockedTrackers.count ?? -1)")
        assignDefaults()
        self.pageData = pageData

        protectionsEnabled = pageData?.protectionsEnabled == true

        updatePrivacyPractices()
        updateEncryptionStatus()
        updateHeader()
        updateState()
    }

    func updatePrivacyPractices() {
        privacyPracticesText = Strings.privacyPracticesUnknown
        privacyPracticesIcon = Icons.unknown

        guard let url = pageData?.url else { return }
        let privacyPracticesManager: PrivacyPracticesManager = Dependencies.shared.privacyPracticesManager
        let practices = privacyPracticesManager.findPrivacyPractice(forUrl: url)
        switch practices.summary {
        case .unknown:
            privacyPracticesIcon = Icons.unknown
            privacyPracticesText = Strings.privacyPracticesUnknown

        case .mixed:
            privacyPracticesIcon = Icons.unknown
            privacyPracticesText = Strings.privacyPracticesMixed

        case .good:
            privacyPracticesIcon = Icons.green
            privacyPracticesText = Strings.privacyPracticesGood

        case .poor:
            privacyPracticesIcon = Icons.red
            privacyPracticesText = Strings.privacyPracticesPoor
        }
    }

    func updateHeader() {
        guard let pageData = pageData,
              let url = pageData.url else {
            return
        }

        isNewTab = false
        domain = url.host ?? ""

        let grade = pageData.calculateGrade()
        os_log("MDVM updateHeader %{public}s", log: generalLog, type: .debug, "\(grade.site.grade) vs \(grade.enhanced.grade)")
        if grade.site.grade != grade.enhanced.grade && protectionsEnabled {
            enhancedFromGrade = grade.site.grade.inlineImage
        }

        let score = !protectionsEnabled ? grade.site : grade.enhanced
        if let iconImage = score.grade.iconImage(trusted: !protectionsEnabled) {
            gradeHeroImage = iconImage
        }

    }

    func updateEncryptionStatus() {
        if pageData?.isEncrypted == true {
            encryptionStatusIcon = Icons.green
            encryptionStatusText = UserText.encryptionEnabled
        } else {
            encryptionStatusIcon = Icons.red
            encryptionStatusText = UserText.encryptionDisabled
        }
    }

    // swiftlint:disable function_body_length
    func updateState() {
        guard let pageData = pageData, !isNewTab else { return }

        // https://app.asana.com/0/0/1202702259694393/f

        let protectionsEnabled = self.protectionsEnabled
        let hasBlocked = pageData.hasBlockedTrackers
        let hasSpecialRequests = pageData.hasSpecialThirdPartyRequests
        let hasNoneSpecialRequests = pageData.hasNonSpecialThirdPartyRequests

        switch (hasBlocked, hasSpecialRequests, hasNoneSpecialRequests, protectionsEnabled) {

        case (true, false, true, false),
            (true, true, false, false),
            (true, true, true, false),
            (true, false, false, false):
            // These states are replicated below with hasBlocked == true, but that shouldn't happen
            os_log("MDVM state unexpected %{public}s", log: generalLog, type: .debug,
                   "\((hasBlocked, hasSpecialRequests, hasNoneSpecialRequests, protectionsEnabled))")
            state = "unexpected"

        case (true, true, false, true),
            (true, false, true, true),
            (true, true, true, true):
            os_log("MDVM state 1", log: generalLog, type: .debug)
            state = "1"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.requestsBlockedFromLoading
            requestsLoadedIcon = Icons.gray
            requestsLoadedText = Strings.thirdPartyRequestsLoaded

        case (false, true, false, true),
            (false, true, true, true):
            os_log("MDVM state 2", log: generalLog, type: .debug)
            state = "2"
            trackersBlockedIcon = Icons.gray
            trackersBlockedText = Strings.noTrackingRequestsFound
            requestsLoadedIcon = Icons.gray
            requestsLoadedText = Strings.thirdPartyRequestsLoaded

        case (false, false, true, true):
            os_log("MDVM state 3", log: generalLog, type: .debug)
            state = "3"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.noTrackingRequestsFound
            requestsLoadedIcon = Icons.gray
            requestsLoadedText = Strings.thirdPartyRequestsLoaded

        case (false, false, false, true):
            os_log("MDVM state 4", log: generalLog, type: .debug)
            state = "4"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.noTrackingRequestsFound
            requestsLoadedIcon = Icons.green
            requestsLoadedText = Strings.noThirdPartyRequestsLoaded

        case (true, false, false, true):
            os_log("MDVM state 5", log: generalLog, type: .debug)
            state = "5"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.requestsBlockedFromLoading
            requestsLoadedIcon = Icons.green
            requestsLoadedText = Strings.noThirdPartyRequestsLoaded

        case (false, true, false, false),
            (false, true, true, false):
            os_log("MDVM state 6", log: generalLog, type: .debug)
            state = "6"
            trackersBlockedIcon = Icons.red
            trackersBlockedText = Strings.noTrackingRequestsBlocked
            requestsLoadedIcon = Icons.gray
            requestsLoadedText = Strings.thirdPartyRequestsLoaded

        case (false, false, true, false):
            os_log("MDVM state 7", log: generalLog, type: .debug)
            state = "7"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.noTrackingRequestsFound
            requestsLoadedIcon = Icons.gray
            requestsLoadedText = Strings.thirdPartyRequestsLoaded

        case (false, false, false, false):
            os_log("MDVM state 8", log: generalLog, type: .debug)
            state = "8"
            trackersBlockedIcon = Icons.green
            trackersBlockedText = Strings.noTrackingRequestsFound
            requestsLoadedIcon = Icons.green
            requestsLoadedText = Strings.noThirdPartyRequestsLoaded
        }

    }
    // swiftlint:enable function_body_length

    func manageUnprotectedSites() {
        NSWorkspace.shared.open(URL(string: AppLinks.manageUnprotectedSites)!)
    }

    func toggleProtectionState(_ state: Bool) {
        os_log("MDVM updateProtections %{public}s", log: generalLog, type: .debug,
               state ? "turn on" : "turn off")

        guard let url = pageData?.url else { return }
        if trustedSitesManager.isTrusted(url: url) {
            trustedSitesManager.removeDomain(forUrl: url)
            protectionsEnabled = true
        } else {
            trustedSitesManager.addDomain(forUrl: url)
            protectionsEnabled = false
            withAnimation {
                isItBrokenShowing = true
            }
        }

        updateHeader()
        updateState()
    }

    private func assignDefaults() {
        isNewTab = true
        gradeHeroImage = "PP Grade Null"
        domain = UserText.dashboardNewTabDomain
        protectionsEnabled = true
        enhancedFromGrade = nil

        encryptionStatusText = UserText.encryptionDisabled
        encryptionStatusIcon = Icons.unknown

        trackersBlockedText = Strings.noTrackingRequestsFound
        trackersBlockedIcon = Icons.unknown

        requestsLoadedText = Strings.noThirdPartyRequestsLoaded
        requestsLoadedIcon = Icons.unknown

        privacyPracticesText = UserText.dashboardTOSUnknown
        privacyPracticesIcon = Icons.unknown

        state = "??"
    }

}

extension Grade.Grading {

    static let inlineIcons: [Grade.Grading: String] = [
        .a: "PP Inline A",
        .bPlus: "PP Inline B Plus",
        .b: "PP Inline B",
        .cPlus: "PP Inline C Plus",
        .c: "PP Inline C",
        .d: "PP Inline D"
    ]

    static let icons: [Grade.Grading: String] = [
        .a: "PP Grade A",
        .bPlus: "PP Grade B Plus",
        .b: "PP Grade B",
        .cPlus: "PP Grade C Plus",
        .c: "PP Grade C",
        .d: "PP Grade D"
    ]

    var inlineImage: String? {
        return Grade.Grading.inlineIcons[self]
    }

    func iconImage(trusted: Bool) -> String? {
        guard let iconName = Grade.Grading.icons[self] else { return nil }
        let suffix = trusted ? "Off" : "On"
        let name = iconName + " " + suffix
        return name
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
