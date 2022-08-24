//
//  Pixel.swift
//  Statistics
//
//  Copyright © 2018 DuckDuckGo. All rights reserved.
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
import Core
import os

public enum PixelName: String {
    case onboardingGetStartedShown = "eon_gs_s"
    case onboardingGetStartedPressed = "eon_gs_p"
    case onboardingEnableExtensionsShown = "eon_ee_s"
    case onboardingEnableExtensionshSafariPressed = "eon_ee_spp"
    case onboardingEnableDDGSearchShown = "eon_ed_s"
    case onboardingEnableDDGSearchSafariPressed = "eon_ed_spp"
    case onboardingEnableDDGSearchTime = "eon_ed_t"
    
    case homeShown = "eapp_h"
    case homeUnprotectedSitesOpened = "eapp_h_w"
    case homeHelpOpened = "eapp_h_h"
    case homeOpenSafariToEnableDashboard = "eapp_h_sd"
    case homeOpenSafariToEnableCb = "eapp_h_scb"
    case homeOpenSafariForSearch = "eapp_h_ss"
    case homeDashboardEnabled = "eapp_h_d_on"
    case homeDashboardDisabled = "eapp_h_d_off"
    case homeCbEnabled = "eapp_h_cb_on"
    case homeCbDisabled = "eapp_h_cb_off"

    case dashboardPopupOpened = "ep"
    case dashboardMenuOpened = "eph"
    case dashboardHomePageOpened = "ep_h"
    case dashboardPrivacyProtectionToggleOn = "ept_on"
    case dashboardPrivacyProtectionToggleOff = "ept_off"
    case dashboardTrackerNetworksOpened = "epn"
    case dashboardUnprotectedSitesOpened = "epw"
    
    case safariBrowserExtensionSearch = "sbes"

    // Ad click attribution
    case adClickDetected = "m_ad_click_detected"
    case adClickActive = "m_ad_click_active"
    case adClickAttributedPageLoads = "m_pageloads_with_ad_attribution"
    case adClickHeuristicValidation = "m_ad_click_heuristic_validation"

    // debug pixels
    case debugStatisticsTimeout = "m_sae_dbg_sts"
    case debugSyncTimeout = "m_sae_dbg_syn"
    case debugSchedulerTimeout = "m_sae_dbg_sch"
    case debugReloadTimeout = "m_sae_dbg_rel"
}

public typealias PixelCompletion = (Error?) -> Void

public struct PixelParameters {
    public static let atb = "atb"
    public static let version = "extensionVersion"
    public static let elapsed = "elapsed"

    public static let adClickAttributedPageLoadsCount = "count"
    
    #if DEBUG
    public static let test = "test"
    #endif
}

public struct PixelValues {
    #if DEBUG
    public static let test = "1"
    #endif
}

public protocol  Pixel {
    func fire(_ pixel: PixelName, withParams params: [String: String], onComplete: @escaping PixelCompletion)
}

extension Pixel {
    public func fire(_ pixel: PixelName, withParams params: [String: String] = [:], onComplete: @escaping PixelCompletion = {_ in }) {
        fire(pixel, withParams: params, onComplete: onComplete)
    }
}

public class DefaultPixel: Pixel {

    private let statisticsStore: StatisticsStore
    private let appVersion: AppVersion
    private let apiRequest: APIRequest.Factory
    
    public init(statisticsStore: StatisticsStore, appVersion: AppVersion = DefaultAppVersion(), apiRequest: @escaping APIRequest.Factory) {
        self.statisticsStore = statisticsStore
        self.appVersion = appVersion
        self.apiRequest = apiRequest
    }
    
    public func fire(_ pixel: PixelName, withParams additionalParams: [String: String], onComplete: @escaping PixelCompletion) {
        
        let path = "/t/\(pixel.rawValue)_safari"
        
        var params = [String: String]()

        let appStatsExcluded = [
            PixelName.adClickHeuristicValidation,
            PixelName.adClickAttributedPageLoads
        ].contains(pixel)

        if !appStatsExcluded {
            params[PixelParameters.atb] = statisticsStore.installAtb ?? ""
            params[PixelParameters.version] = appVersion.fullVersion
        }

        #if DEBUG
        params[PixelParameters.test] = PixelValues.test
        #endif
                
        params.merge(additionalParams) { (current, _) in current }
      
        apiRequest().get(path, withParams: params) { _, _, error in
            os_log("Pixel fired %{public}s %{public}s, error: %{publics}", log: generalLog, pixel.rawValue,
                   String(describing: params), error?.localizedDescription ?? "none")
        }
    }
}
