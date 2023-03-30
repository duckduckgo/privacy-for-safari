//
//  RequestsDetailViewModel.swift
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

import Foundation
import TrackerBlocking
import TrackerRadarKit
import os

class RequestsDetailViewModel: ObservableObject {

    enum Icons {

        static let green = "Counter-128"
        static let gray = "Shield-Info-64"

    }

    enum Messages {

        static let thirdPartyRequestsLoaded = UserText.dashboardRequestsSomeLoadedMessage
        static let noThirdPartyRequestsLoaded = UserText.dashboardRequestsNoneLoadedMessage
        static let noThirdPartyRequestsBlocked = UserText.dashboardRequestsNoneBlockedMessage

    }

    @Published var domain: String = ""
    @Published var icon: String = Icons.gray
    @Published var message: String = UserText.dashboardSiteIsNewTab

    @Published var adClickEntities = [EntityDetailsModel]()
    @Published var breakagePreventionEntities = [EntityDetailsModel]()
    @Published var domainRelatedEntities = [EntityDetailsModel]()
    @Published var otherRequestsEntities = [EntityDetailsModel]()

    var pageData: PageData?

    var showOtherRequestsHeader: Bool {
        return !adClickEntities.isEmpty || !breakagePreventionEntities.isEmpty || !domainRelatedEntities.isEmpty
    }

    var thirdPartyRequestsDetected: Bool {
        return !adClickEntities.isEmpty || !breakagePreventionEntities.isEmpty || !domainRelatedEntities.isEmpty || !otherRequestsEntities.isEmpty
    }

    var isNewTab: Bool {
        pageData?.url == nil
    }

    var protectionsEnabled: Bool {
        return pageData?.isTrusted == false
    }

    let trackerDataManager: TrackerDataManager

    init(trackerDataManager: TrackerDataManager = Dependencies.shared.trackerDataManager) {
        self.trackerDataManager = trackerDataManager
    }

    func updateFromPageData(_ pageData: PageData?) async {
        os_log("RDVM updateFromPageData, %d", log: lifecycleLog, type: .debug, pageData?.loadedTrackers.count ?? -1)
        self.pageData = pageData
        domain = pageData?.url?.host ?? UserText.dashboardNewTabDomain

        if pageData?.isTrusted == true {
            putAllTrackersAndRequestsIntoOtherSection()
        } else {
            putTrackersAndRequestsIntoSections()
        }

        updateState()
    }

    func putAllTrackersAndRequestsIntoOtherSection() {
        adClickEntities = []
        breakagePreventionEntities = []
        domainRelatedEntities = []
        otherRequestsEntities = []

        guard let pageData = pageData else { return }

        let trackers: Set<DetectedTracker> = pageData.blockedTrackers.union(pageData.loadedTrackers)
        let requests: Set<PageData.DetectedRequest> = pageData.otherRequests

        otherRequestsEntities = EntityDetailsModel.entityDetailsFromTrackers(trackers, andRequests: requests)
    }

    func putTrackersAndRequestsIntoSections() {

        var adClickTrackers = Set<DetectedTracker>()
        var breakagePreventionTrackers = Set<DetectedTracker>()
        var domainRelatedTrackers = Set<DetectedTracker>()
        var otherTrackers = Set<DetectedTracker>()

        let isVendorDomain = pageData?.url?.isVendorDomain ?? false

        pageData?.loadedTrackers.forEach { tracker in
            if isVendorDomain && tracker.isOnAllowList {

                adClickTrackers.insert(tracker)
            } else if let domain = pageData?.url?.eTLDPlus1Host,
                        trackerDataManager.detectedTracker(tracker, isRelatedToDomain: domain) {
                domainRelatedTrackers.insert(tracker)

            } else if tracker.isIgnoredForBreakageOnUrl(url: pageData?.url) {

                breakagePreventionTrackers.insert(tracker)

            } else {
                otherTrackers.insert(tracker)
            }
        }

        var nonRelatedRequests = Set<PageData.DetectedRequest>()
        var relatedRequests = Set<PageData.DetectedRequest>()

        if let entity = pageData?.entity {
            pageData?.otherRequests.forEach {
                if trackerDataManager.entity(forUrl: $0.url)?.displayName == entity.displayName {
                    relatedRequests.insert($0)
                } else {
                    os_log("updateRequestList %{public}s not in domain list for %{public}s", log: lifecycleLog, type: .debug,
                           $0.url.eTLDPlus1Host ?? "nil host", entity.displayName ?? "nil entity")
                    nonRelatedRequests.insert($0)
                }
            }
        } else {
            nonRelatedRequests = pageData?.otherRequests ?? .init()
        }
        os_log("updateRequestList nonRelated %d, related %d", log: lifecycleLog, type: .debug, nonRelatedRequests.count, relatedRequests.count)

        adClickEntities = EntityDetailsModel.entityDetailsFromTrackers(adClickTrackers)
        breakagePreventionEntities = EntityDetailsModel.entityDetailsFromTrackers(breakagePreventionTrackers)
        domainRelatedEntities = EntityDetailsModel.entityDetailsFromTrackers(domainRelatedTrackers, andRequests: relatedRequests)
        otherRequestsEntities = EntityDetailsModel.entityDetailsFromTrackers(otherTrackers, andRequests: nonRelatedRequests)

        os_log("updateRequestList, DONE %d, %d, %d, %d", log: lifecycleLog, type: .debug,
               adClickEntities.count,
               breakagePreventionEntities.count,
               domainRelatedEntities.count,
               otherRequestsEntities.count)

    }

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

        case (true, true, false, true),
            (true, false, true, true),
            (true, true, true, true):
            os_log("MDVM state 1", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.thirdPartyRequestsLoaded

        case (false, true, false, true),
            (false, true, true, true):
            os_log("MDVM state 2", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.thirdPartyRequestsLoaded

        case (false, false, true, true):
            os_log("MDVM state 3", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.thirdPartyRequestsLoaded

        case (false, false, false, true):
            os_log("MDVM state 4", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.noThirdPartyRequestsLoaded

        case (true, false, false, true):
            os_log("MDVM state 5", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.noThirdPartyRequestsLoaded

        case (false, true, false, false),
            (false, true, true, false):
            os_log("MDVM state 6", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.noThirdPartyRequestsBlocked

        case (false, false, true, false):
            os_log("MDVM state 7", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.noThirdPartyRequestsBlocked

        case (false, false, false, false):
            os_log("MDVM state 8", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.noThirdPartyRequestsLoaded

        }

    }

}

extension DetectedTracker {

    var isOnAllowList: Bool {
        let config = SafariTabAddClickAttribution.shared.config
        return config.allowlist.contains(where: {
            $0.host == resource.host
        })
    }

    func isIgnoredForBreakageOnUrl(url: URL?) -> Bool {
        os_log("isIgnoredForBreakageOnUrl IN %{public}s %{public}s", log: generalLog, type: .debug,
               url?.host ?? "nil", matchedTracker?.domain ?? "nil")
        guard let url = url,
              let matchedTracker = matchedTracker,
              let matchedTrackerDomain = matchedTracker.domain else {
            os_log("isIgnoredForBreakageOnUrl OUT %{public}s no URL or matched tracker", log: generalLog, type: .debug, url?.host ?? "nil")
            return false
        }

        if matchedTracker.defaultAction == .ignore {
            os_log("isIgnoredForBreakageOnUrl OUT %{public}s defaultAction is ignore", log: generalLog, type: .debug, url.host ?? "nil")
            return true
        }

        let noProtocol = resource.absoluteString.dropPrefix("http://").dropPrefix("https://")

        if matchedTracker.rules?.contains(where: {
            os_log("isIgnoredForBreakageOnUrl OUT %{public}s %{public}s", log: generalLog, type: .debug,
                   url.host ?? "nil", $0.rule ?? "nil rule", matchedTrackerDomain)

            return $0.rule?.matches(noProtocol) == true
                && ($0.action == .ignore || $0.exceptions?.domains?.contains(where: { $0 == url.eTLDPlus1Host }) == true)
        }) == true {
            os_log("isIgnoredForBreakageOnUrl OUT %{public}s rule matched", log: generalLog, type: .debug, url.host ?? "nil")
            return true
        }

        os_log("isIgnoredForBreakageOnUrl OUT %{public}s no rule matched", log: generalLog, type: .debug, url.host ?? "nil")
        return false
    }

}

extension URL {

    var isVendorDomain: Bool {
        guard let host = eTLDPlus1Host else { return false }
        return AdClickAttributionExemptions.shared.vendorDomains.contains(host)
    }

}

extension TrackerDataManager {

    func detectedTracker(_ tracker: DetectedTracker, isRelatedToDomain domain: String) -> Bool {
        guard let owner = tracker.owner else { return false }
        return self.entity(forName: owner)?.domains?.contains(domain) == true
    }

    public func findEntity(forHost host: String) -> Entity? {
        for host in variations(of: host) {
            if let entityName = trackerData?.domains[host] {
                return trackerData?.entities[entityName]
            }
        }
        return nil
    }

    private func variations(of host: String) -> [String] {
        var parts = host.components(separatedBy: ".")
        var domains = [String]()
        while parts.count > 1 {
            let domain = parts.joined(separator: ".")
            domains.append(domain)
            parts.removeFirst()
        }
        return domains
    }

}

extension String {

    func matches(_ string: String) -> Bool {
        // opt: memoize?
        guard let regex = try? NSRegularExpression(pattern: self, options: [ .caseInsensitive ]) else {
            return false
        }

        let matches = regex.matches(in: string, options: [ ], range: NSRange(location: 0, length: string.utf16.count))
        return !matches.isEmpty
    }

}
