//
//  TrustedSitesMonitor.swift
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
import TrackerBlocking
import SafariServices

class TrustedSitesMonitor: NSObject {

    var domainsToReload = Set<String>()
    var lastWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        os_log("TSM trustedSitesMonitor init", log: lifecycleLog, type: .debug)
    }

    func install() {
        os_log("TSM trustedSitesMonitor install", log: lifecycleLog, type: .debug)
        // no-op for logging and to allow static to init
    }

    @objc func onTrustedSitesChanged() {
        os_log("TSM trustedSitesMonitor onTrustedSitesChanged", log: lifecycleLog, type: .debug)

        guard let domain = Dependencies.shared.trustedSitesManager.lastChangedDomain,
              domainsToReload.insert(domain).inserted == true else { return }

        scheduleReload()
    }

    private func scheduleReload() {
        os_log("TSM trustedSitesMonitor scheduleReload", log: lifecycleLog, type: .debug)
        lastWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            let domains = self.domainsToReload
            self.domainsToReload.removeAll()
            self.reloadPagesForDomains(domains)
        }
        lastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func reloadPagesForDomains(_ domains: Set<String>) {
        os_log("TSM trustedSitesMonitor reloadPagesForDomains %{public}s", log: lifecycleLog, type: .debug, "\(domains)")
        Task {
            for domain in domains {
                if let page = await DashboardData.shared.pageForDomain(domain) {
                    os_log("TSM trustedSitesMonitor pageReloading for %{public}s", log: lifecycleLog, type: .debug, domain)
                    page.reload()
                }
            }
        }
    }

    deinit {
        os_log("TSM trustedSitesMonitor deinit", log: lifecycleLog, type: .debug)
    }

}
