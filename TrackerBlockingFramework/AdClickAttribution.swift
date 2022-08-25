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
import Statistics
import os

public protocol Tabbing: AnyObject, Hashable {

    associatedtype Page

    func activePage() async -> Page?
    func currentURL() async -> URL?

}

public protocol AdClickContentBlockerReloading {

    func reload() async

}

private var timerId = 0

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

        func hasExpired(usingInterval interval: TimeInterval) -> Bool {
            return lastAccess.timeIntervalSinceNow * -1 > interval
        }
    }

    class ValidationTimer {
        let vendorDomain: String
        let tab: Tab
        let id: Int

        let work: DispatchWorkItem

        init(vendorDomain: String, tab: Tab, callback: @escaping (Tab) -> Void) {
            self.vendorDomain = vendorDomain
            self.tab = tab
            timerId += 1
            let id = timerId
            self.id = id

            let interval = isDebugBuild ? 5.0 : 0.3

            work = DispatchWorkItem {
                os_log("ValidationTimer fired %d", log: generalLog, type: .debug, id)
                callback(tab)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: work)

            os_log("ValidationTimer scheduled %d", log: generalLog, type: .debug, id)
        }

        static func scheduleForVendor(_ vendorDomain: String, inTab tab: Tab, callback: @escaping (Tab) -> Void) -> ValidationTimer {
            return ValidationTimer(vendorDomain: vendorDomain, tab: tab, callback: callback)
        }

        func invalidate() {
            os_log("ValidationTimer invalidated %d", log: generalLog, type: .debug, id)
            work.cancel()
        }

        deinit {
            os_log("ValidationTimer deinit %d", log: generalLog, type: .debug, id)
        }

    }

    nonisolated public let config: AdClickAttributionConfig

    private let heuristicTimeoutInterval: TimeInterval
    
    var exemptions = [Exemption]()
    var heuristics = [Heuristic]()

    let pixelFiring: AdClickPixelFiring
    let blockerListManager: BlockerListManager
    let contentBlockerReloader: AdClickContentBlockerReloading

    public init(config: AdClickAttributionConfig,
                pixelFiring: AdClickPixelFiring,
                blockerListManager: BlockerListManager,
                contentBlockerReloader: AdClickContentBlockerReloading,
                heuristicTimeoutInterval: TimeInterval = 5.0) {
        os_log("ACA init", log: lifecycleLog, type: .debug)

        self.config = config
        self.pixelFiring = pixelFiring
        self.blockerListManager = blockerListManager
        self.contentBlockerReloader = contentBlockerReloader
        self.heuristicTimeoutInterval = heuristicTimeoutInterval
    }

    deinit {
        os_log("ACA deinit", log: lifecycleLog, type: .debug)
    }

    nonisolated public func firePixelForResourceIfNeeded(resourceURL: URL, onPage url: URL) {

        guard config.resourceIsOnAllowlist(resourceURL),
              let vendorDomain = url.eTLDPlus1Host else { return }

        os_log("ACA firePixelForResourceIfNeeded %{public}s %{public}s", log: generalLog, type: .debug,
               resourceURL.absoluteString, vendorDomain)

        let result = AdClickAttributionExemptions.shared.observedVendors.insert(vendorDomain)
        if result.inserted {
            pixelFiring.fireAdClickAllowListUsed()
        }
        
    }

    public func incrementAdClickPageLoadCounter() async {
        pixelFiring.incrementAdClickPageLoadCounterAndSendIfNeeded()
    }

    nonisolated public func isExemptAllowListResource(_ resourceURL: URL) -> Bool {
        return config.resourceIsOnAllowlist(resourceURL)
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
            await vendorDetected(name, inTab: tab)
            self.heuristics.append(Heuristic(tab: tab, vendorDomainFromParameter: name))

        case .heuristic:
            self.heuristics.append(Heuristic(tab: tab, vendorDomainFromParameter: nil))

        case .none:
            updateHeuristicForTab(tab)
        }

        if await self.removeExpiredExemptions() {
            await updateContentBlockerRules()
        }
    }

    private func updateHeuristicForTab(_ tab: Tab) {
        self.heuristics = self.heuristics.map {
            if tab == $0.tab {
                return Heuristic(tab: tab, vendorDomainFromParameter: $0.vendorDomainFromParameter)
            }
            return $0
        }
    }

    private func removeExpiredExemptions() async -> Bool {
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

    private func vendorDetected(_ vendorDomain: String, inTab tab: Tab) async {
        os_log("ACA vendorDetected %{public}s", log: generalLog, type: .debug, vendorDomain)
        let isNewVendor = !AdClickAttributionExemptions.shared.containsVendor(vendorDomain)
        self.exemptions.append(Exemption(tab: tab, vendorDomain: vendorDomain, isNewVendor: isNewVendor))

        if isNewVendor {
            await self.updateContentBlockerRules()
        }
    }

    private var timers = [Tab: ValidationTimer]()

    func handleHeuristicValidationFired(_ tab: Tab) {
        os_log("ValidationTimer fired", log: generalLog, type: .debug)
        if let timer = timers[tab] {
            Task {
                guard let url = await tab.currentURL() else { return }
                pixelFiring.fireAdClickHeuristicValidation(domainMatches: timer.vendorDomain == url.eTLDPlus1Host)
            }
        }
        self.timers[tab] = nil
    }

    public func pageFinishedLoading(_ url: URL, forTab tab: Tab) async {
        os_log("ACA pageFinishedLoading %{public}s", log: generalLog, type: .debug, url.absoluteString)

        if let timer = timers[tab] {
            os_log("ValidationTimer rescheduling", log: generalLog, type: .debug)
            timer.invalidate()
            timers[tab] = ValidationTimer.scheduleForVendor(timer.vendorDomain, inTab: tab,
                                                            callback: handleHeuristicValidationFired)
        }

        if let vendorDomain = url.eTLDPlus1Host,
           let heuristic = heuristics.first(where: { $0.tab == tab }) {

            if !heuristic.hasExpired(usingInterval: self.heuristicTimeoutInterval) {

                if heuristic.vendorDomainFromParameter == nil {
                    await vendorDetected(vendorDomain, inTab: tab)
                    await updateContentBlockerRules()
                    os_log("ValidationTimer creating", log: generalLog, type: .debug)
                    timers[tab] = ValidationTimer.scheduleForVendor(vendorDomain, inTab: tab, callback: handleHeuristicValidationFired)
                }
            }

            pixelFiring.fireAdClickDetected(vendorDomainFromParameter: heuristic.vendorDomainFromParameter,
                                            vendorDomainFromHeuristic: vendorDomain)
        }

        self.heuristics = self.heuristics.filter { $0.tab != tab }
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
