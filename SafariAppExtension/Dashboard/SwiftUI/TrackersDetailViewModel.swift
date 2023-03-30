//
//  TrackersDetailViewModel.swift
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

class TrackersDetailViewModel: ObservableObject {

    enum Icons {

        static let gray = "PP Hero Major Off"
        static let green = "PP Hero Major On"
        static let red = "PP Hero Major Bad"

    }

    enum Messages {

        static let requestsBlocked = UserText.dashboardTrackersMessage
        static let requestsNotBlocked = UserText.dashboradTrackersNotBlockedMessage

    }

    @Published var domain = UserText.dashboardNewTabDomain
    @Published var blockedEntities = [EntityDetailsModel]()
    @Published var protectionsEnabled = true
    @Published var icon = Icons.gray
    @Published var message = UserText.dashboardSiteIsNewTab

    var pageData: PageData?

    var isNewTab: Bool {
        pageData?.url == nil
    }

    func updateFromPageData(_ pageData: PageData?) {
        self.pageData = pageData
        objectWillChange.send()

        domain = pageData?.url?.host ?? UserText.dashboardNewTabDomain
        protectionsEnabled = pageData?.isTrusted == false
        updateState()

        guard let pageData = pageData else {
            blockedEntities = []
            return
        }
        blockedEntities = EntityDetailsModel.entityDetailsFromTrackers(pageData.blockedTrackers)
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
            icon = Icons.green
            message = Messages.requestsBlocked

        case (false, true, false, true),
            (false, true, true, true):
            os_log("MDVM state 2", log: generalLog, type: .debug)
            icon = Icons.gray
            message = Messages.requestsBlocked

        case (false, false, true, true):
            os_log("MDVM state 3", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.requestsBlocked

        case (false, false, false, true):
            os_log("MDVM state 4", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.requestsBlocked

        case (true, false, false, true):
            os_log("MDVM state 5", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.requestsBlocked

        case (false, true, false, false),
            (false, true, true, false):
            os_log("MDVM state 6", log: generalLog, type: .debug)
            icon = Icons.red
            message = Messages.requestsNotBlocked

        case (false, false, true, false):
            os_log("MDVM state 7", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.requestsNotBlocked

        case (false, false, false, false):
            os_log("MDVM state 8", log: generalLog, type: .debug)
            icon = Icons.green
            message = Messages.requestsNotBlocked

        }

    }

}
