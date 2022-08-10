//
//  AdClickAttribution.swift
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

import Core
import Foundation
import os

public protocol Tabbing: AnyObject, Equatable {

    associatedtype Page

    func activePage() async -> Page?

}

public protocol AdClickContentBlockerReloading {

    func reload() async

}

public actor AdClickAttribution<Tab: Tabbing> {

    struct Exemption {
        let tab: Tab
        let vendorDomain: String
        let isNewVendor: Bool
        let clickDate: Date = Date()
    }

    struct Heuristic {
        let tab: Tab
        let vendorDomainFromParameter: String?
        let lastAccess: Date = Date()
    }

    nonisolated public let config: AdClickAttributionConfig
    
    private let heuristicTimeoutInterval: TimeInterval = 5.0

    var exemptions = [Exemption]()
    var heuristics = [Heuristic]()

    let pixelFiring: AdClickPixelFiring
    let blockerListManager: BlockerListManager
    let contentBlockerReloader: AdClickContentBlockerReloading

    public init(config: AdClickAttributionConfig,
                pixelFiring: AdClickPixelFiring,
                blockerListManager: BlockerListManager,
                contentBlockerReloader: AdClickContentBlockerReloading) {
        os_log("ACA init", log: lifecycleLog, type: .debug)

        self.config = config
        self.pixelFiring = pixelFiring
        self.blockerListManager = blockerListManager
        self.contentBlockerReloader = contentBlockerReloader
    }

    deinit {
        os_log("ACA deinit", log: lifecycleLog, type: .debug)
    }

    nonisolated public func firePixelForResourceIfNeeded(resourceURL: URL, onPage url: URL) {

        guard config.resourceIsOnAllowlist(resourceURL),
              let vendorDomain = url.eTLDPlus1Host else { return }

        let result = AdClickAttributionExemptions.shared.observedVendors.insert(vendorDomain)
        if result.inserted {
            pixelFiring.fireAdClickAllowListUsed()
        }
        
    }

    public func clearExpiredVendors() async {
        if await removeExpiredExemptions() {
            await blockerListManager.update()
            await contentBlockerReloader.reload()
        }
    }

    public func resetContentBlockingExemptions() async {
        os_log("ACA resetContentBlockingExemptions", log: generalLog, type: .debug)
        self.exemptions = []
        await self.updateContentBlockerRules()
    }

    public func handlePageNavigationToURL(_ url: URL, inTab tab: Tab) async {
        os_log("ACA handlePageNavigationToURL %{public}s", log: generalLog, type: .debug, url.absoluteString)
        switch self.config.attributionTypeForURL(url) {
        case .vendor(let name):
            await vendorDetected(named: name, inTab: tab)

        case .heuristic:
            self.heuristics.append(Heuristic(tab: tab, vendorDomainFromParameter: nil))

        case .none:
            self.updateHeuristicsForTab(tab)
        }

        await self.cleanUpHeuristics()

        if await self.removeExpiredExemptions() {
            await updateContentBlockerRules()
        }
    }

    func removeExpiredExemptions() async -> Bool {
        let vendorDomains = AdClickAttributionExemptions.shared.vendorDomains

        var activeExemptions = [Exemption]()
        for exemption in exemptions {
            if await exemption.tab.activePage() != nil {
                activeExemptions.append(exemption)
            }
        }

        activeExemptions = activeExemptions.filter {
            !config.hasExemptionExpired($0.clickDate)
        }

        let activeVendors = Set(activeExemptions.map { $0.vendorDomain }).sorted()
        self.exemptions = activeExemptions
        AdClickAttributionExemptions.shared.vendorDomains = activeVendors

        return vendorDomains != AdClickAttributionExemptions.shared.vendorDomains
    }

    func vendorDetected(named name: String, inTab tab: Tab) async {
        os_log("ACA vendorDetected %{public}s", log: generalLog, type: .debug, name)
        let isNewVendor = !AdClickAttributionExemptions.shared.containsVendor(name)
        self.exemptions.append(Exemption(tab: tab, vendorDomain: name, isNewVendor: isNewVendor))
        self.heuristics.append(Heuristic(tab: tab, vendorDomainFromParameter: name))

        if isNewVendor {
            await self.updateContentBlockerRules()
        }
    }

    public func pageFinishedLoading(_ url: URL, forTab tab: Tab) async {
        os_log("ACA pageFinishedLoading %{public}s", log: generalLog, type: .debug, url.absoluteString)
        updateHeuristicsForTab(tab)

        if let heuristic = self.heuristics.first(where: { $0.tab == tab }),
           let vendorDomainFromHeuristic = url.eTLDPlus1Host {

            let vendorDomain = heuristic.vendorDomainFromParameter ?? vendorDomainFromHeuristic
            os_log("ACA pageFinishedLoading adding exemption %{public}s", log: generalLog, type: .debug, vendorDomain)

            let recentlyAdded = exemptions.contains {
                $0.vendorDomain == vendorDomain && $0.isNewVendor
            }

            let newVendor = !AdClickAttributionExemptions.shared.containsVendor(vendorDomain)

            // The heuristic is finished so we don't care if it's new at this point
            self.exemptions.append(Exemption(tab: tab, vendorDomain: vendorDomain, isNewVendor: false))
            let exemptionsChanged = await self.removeExpiredExemptions()

            if newVendor || exemptionsChanged {
                if newVendor {
                    pixelFiring.fireAdClickRegistered(vendorDomainFromParameter: heuristic.vendorDomainFromParameter,
                                               vendorDomainFromHeuristic: vendorDomainFromHeuristic)
                }
                await self.updateContentBlockerRules()
            }

            if !newVendor && recentlyAdded {
                pixelFiring.fireAdClickRegistered(vendorDomainFromParameter: heuristic.vendorDomainFromParameter,
                                           vendorDomainFromHeuristic: vendorDomainFromHeuristic)
            }
        }

        // Remove heuristics not for this tab
        self.heuristics = self.heuristics.filter { $0.tab != tab }
    }

    private func updateHeuristicsForTab(_ tab: Tab?) {
        os_log("ACA updateHeuristicsForTab %d", log: lifecycleLog, type: .debug, self.heuristics.count)
        self.heuristics = self.heuristics.map {
            os_log("ACA updateHeuristicsForTab lastAccess %f", log: lifecycleLog, type: .debug,
                   $0.lastAccess.timeIntervalSinceNow)

            // If this heuristic has timedout, remove out
            if $0.lastAccess.timeIntervalSinceNow * -1 > self.heuristicTimeoutInterval {
                print("***", #function, "timeout")
                os_log("ACA heuristic timeout", log: lifecycleLog, type: .debug)
                return nil
            }

            if $0.tab == tab {
                return Heuristic(tab: $0.tab, vendorDomainFromParameter: $0.vendorDomainFromParameter)
            }

            return $0
        }.compactMap { $0 }
        os_log("ACA updateHeuristicsForTab %d", log: lifecycleLog, type: .debug, self.heuristics.count)
    }

    private func cleanUpHeuristics() async {
        updateHeuristicsForTab(nil)
    }

    private func updateContentBlockerRules() async {
        os_log("ACA updateContentBlockerRules %d", log: generalLog, type: .debug, exemptions.count)
        let vendorDomains = [String]((Set<String>(self.exemptions.map { $0.vendorDomain })))

        AdClickAttributionExemptions.shared.allowList = config.allowlist
        AdClickAttributionExemptions.shared.vendorDomains = vendorDomains
        await blockerListManager.update()
        await contentBlockerReloader.reload()
    }

}
