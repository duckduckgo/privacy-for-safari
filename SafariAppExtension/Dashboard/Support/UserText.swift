//
//  UserText.swift
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

import Foundation

// swiftlint:disable line_length
struct UserText {
    
    static let trackersBlocked = NSLocalizedString("privacy.protection.trackers.blocked", comment: "Trackers blocked")
    static let trackersFound = NSLocalizedString("privacy.protection.trackers.found", comment: "Trackers found")

    static let encryptionEnabled = NSLocalizedString("privacy.encryption.enabled", comment: "Encryption Enabled")
    static let encryptionDisabled = NSLocalizedString("privacy.encryption.disabled", comment: "Encryption Disabled")

    static let dashboardTOSUnknown = NSLocalizedString("dashboard.tos.unknown", comment: "Unknown Privacy Practices")
    static let dashboardTOSGood = NSLocalizedString("dashboard.tos.good", comment: "Good Privacy Practices")
    static let dashboardTOSMixed = NSLocalizedString("dashboard.tos.mixed", comment: "Mixed Privacy Practices")
    static let dashboardTOSPoor = NSLocalizedString("dashboard.tos.poor", comment: "Poor Privacy Practices")

    static let dashboardBrokenSiteThankYouTitle = NSLocalizedString("dashboard.brokensite.thankyou.title", comment: "Broken Site Thank You Title")
    static let dashboardBrokenSiteThankYouBody = NSLocalizedString("dashboard.brokensite.thankyou.body", comment: "Broken Site Thank You Body")
    static let dashboardBrokenSiteSubmitTitle = NSLocalizedString("dashboard.brokensite.submit.title", comment: "Broken Site Submit Title")
    static let dashboardBrokenSiteSubmitBody = NSLocalizedString("dashboard.brokensite.submit.body", comment: "Broken Site Submit Body")

    static let brokenSiteCategoryImages = NSLocalizedString("dashboard.brokensite.category.images", comment: "Broken Site Category")
    static let brokenSiteCategoryPaywall = NSLocalizedString("dashboard.brokensite.category.paywall", comment: "Broken Site Category")
    static let brokenSiteCategoryComments = NSLocalizedString("dashboard.brokensite.category.comments", comment: "Broken Site Category")
    static let brokenSiteCategoryVideos = NSLocalizedString("dashboard.brokensite.category.videos", comment: "Broken Site Category")
    static let brokenSiteCategoryLinks = NSLocalizedString("dashboard.brokensite.category.links", comment: "Broken Site Category")
    static let brokenSiteCategoryContent = NSLocalizedString("dashboard.brokensite.category.content", comment: "Broken Site Category")
    static let brokenSiteCategoryLogin = NSLocalizedString("dashboard.brokensite.category.login", comment: "Broken Site Category")
    static let brokenSiteCategoryOther = NSLocalizedString("dashboard.brokensite.category.other", comment: "Broken Site Category")
    static let brokenSiteCategorySelect = NSLocalizedString("dashboard.brokensite.category.select", comment: "Broken Site Category")

    static let dashboardAboutSearchProtectionsAndAds = "About our search protections and ads"
    static let dashboardTrackersMessage = "The following third-party domains’ requests were blocked from loading because they were identified as tracking requests. If a company's requests are loaded, it can allow them to profile you."
    static let dashboradTrackersNotBlockedMessage = "No tracking requests were blocked from loading because Protections are turned off for this site. If a company's requests are loaded, it can allow them to profile you."
    static let dashboardRequestsSomeLoadedMessage = "The following third-party domains’ requests were loaded. If a company's requests are loaded, it can allow them to profile you, though our other web tracking protections still apply."
    static let dashboardRequestsNoneLoadedMessage = "We did not detect requests from any third-party domains."
    static let dashboardRequestsNoneBlockedMessage = "No third-party requests were blocked from loading because Protections are turned off for this site. If a company's requests are loaded, it can allow them to profile you."

    static let dashboardRequestsSomeLoaded = "third-party requests LOADED"
    static let dashboardRequestsNoneLoaded = "No third-party requests LOADED"

    static let dashboardRequestsHeaderLinkText = "About our Web Tracking Protections"

    static let dashboardRequestsLoadedToPreventBreakage = "The following domain’s requests were loaded to prevent site breakage."
    static let dashboardOtherRequestsLoaded = "The following domain’s requests were also loaded."
    static let dashboardLimitationsMessage = "Please note: platform limitations may limit our ability to detect all requests."

    static func dashboardAdClickMessageForDomain(_ domain: String) -> String {
        return "The following domain’s requests were loaded because a \(domain) ad on DuckDuckGo was recently clicked. These requests help evaluate ad effectiveness. All ads on DuckDuckGo are non-profiling."
    }

    static func dashboardRequestsLoadedBecauseRelatedToDomain(_ domain: String) -> String {
        "The following domain’s requests were loaded because they’re associated with \(domain)."
    }

    static let dashboardIsWebsiteBroken = "Is this website broken?"
    static let dashboardIsWebsiteBrokenYes = "Yes"
    static let dashboardIsWebsiteBrokenNo = "No"
    static let dashboardFooterManageUnprotectedSites = "Unprotected Sites"
    static let dashboardFooterReportBroken = "Report Broken Site"

    static let dashboardToggleProtection = "Site Privacy Protection"
    static let dashboardSiteTemporarilyDisabled = "We temporarily disabled Privacy Protection as it appears to be breaking this site."
    static let dashboardSiteIsNewTab = "We only grade regular sites"
    static let dashboardNewTabDomain = "new tab"
    static let dashboardSiteIsEnhancedFrom = "Site enhanced from"
    static let dashboardSitePrivacyGrade = "Privacy Grade"

    static let dashboardRequestsBlockedFromLoading = "Requests Blocked from Loading"
    static let dashboardNoTrackingRequestsFound = "No Tracking Requests Found"
    static let dashboardNoTrackingRequestsBlocked = "No Tracking Requests Blocked"
    static let dashboardThirdPartyRequestsLoaded = "Third-Party Requests Loaded"
    static let dashboardNoThirdPartyRequestsLoaded = "No Third-Party Requests Loaded"

}
// swiftlint:enable line_length
