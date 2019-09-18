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

}
