//
//  SafariExtensionHandler.swift
//  Safari
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

import os
import SafariServices
import TrackerBlocking
import Statistics

// See https://developer.apple.com/videos/play/wwdc2019/720/
class SafariExtensionHandler: SFSafariExtensionHandler {

    static let trustedSitesMonitor: TrustedSitesMonitor = {
        os_log("SEH installing trustedSitesMonitor", log: lifecycleLog, type: .debug)
        let monitor = TrustedSitesMonitor()
        DistributedNotificationCenter.default().addObserver(monitor,
                                                            selector: #selector(TrustedSitesMonitor.onTrustedSitesChanged),
                                                            name: TrustedSitesNotification.sitesUpdatedNotificationName,
                                                            object: nil)
        return monitor
    }()

    static let actor = SafariExtensionActor()

    override func contentBlocker(withIdentifier contentBlockerIdentifier: String, blockedResourcesWith urls: [URL], on page: SFSafariPage) {
        // No logging, as this one is noisy
        Task {
            await Self.actor.contentBlocker(withIdentifier: contentBlockerIdentifier,
                                       blockedResourcesWith: urls,
                                       on: page)
        }
    }

    override func page(_ page: SFSafariPage, willNavigateTo url: URL?) {
        os_log("SEH page willNavigateTo %{public}s", log: lifecycleLog, type: .debug, url?.absoluteString ?? "<no url>")
        updateRetentionData()
        Task {
            await Self.actor.page(page, willNavigateTo: url)
        }
    }

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        os_log("SEH messageReceived %{public}s", log: lifecycleLog, type: .debug, messageName)
        Task {
            await Self.actor.messageReceived(withName: messageName, from: page, userInfo: userInfo)
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // No logging, as this one is noisy
        validationHandler(true, "")
        Task {
            await Self.actor.validateToolbarItem(in: window)
        }
    }

    override func popoverWillShow(in window: SFSafariWindow) {
        os_log("SEH popoverWillShow", log: lifecycleLog, type: .debug)
        Task { @MainActor in
            let page = await window.activeTab()?.activePage()
            let url = await page?.properties()?.url
            await DashboardData.shared.setCurrentPage(to: page, withUrl: url)
            await Self.actor.popoverWillShow(in: window)
        }
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        os_log("SEH popoverViewController", log: lifecycleLog, type: .debug)
        return SafariExtensionViewController.shared
    }

    override init() {
        os_log("SEH init", log: lifecycleLog, type: .debug)
        super.init()
        SyncScheduler.shared.schedule()
        Self.trustedSitesMonitor.install()
    }

    deinit {
        os_log("SEH deinit", log: lifecycleLog, type: .debug)
    }

    private func updateRetentionData() {
        Task {
            let bundle = Bundle(for: type(of: self))
            let state = try? await SFSafariExtensionManager.stateOfSafariExtension(withIdentifier: bundle.bundleIdentifier!)

            os_log("SEH updateRetentionData > getStateOfSafariExtension %{public}s",
                   log: generalLog,
                   type: .debug,
                   state?.isEnabled == true ? "enabled" : "false/unknown")

            if state?.isEnabled == true {
                DefaultStatisticsLoader.shared.refreshAppRetentionAtb(atLocation: AtbLocations.safariExtensionHandler, completion: nil)
            }
        }
    }

}
