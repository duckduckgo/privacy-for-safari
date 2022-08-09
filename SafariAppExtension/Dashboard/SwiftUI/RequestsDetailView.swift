//
//  RequestsDetailView.swift
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

import SwiftUI
import os

struct RequestsDetailView: View {

    @ObservedObject var model: RequestsDetailViewModel

    var onBack: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 8) {

                    BackNavigationHeaderView(onBack: onBack) {
                        PageHeaderView(icon: model.icon,
                                       message: model.message,
                                       domain: model.domain,
                                       linkText: UserText.dashboardRequestsHeaderLinkText,
                                       destination: URL.aboutWebTrackingProtections)
                    }

                    if !model.adClickEntities.isEmpty {
                        RequestListView(description: UserText.dashboardAdClickMessageForDomain(model.domain),
                                        link: (text: UserText.dashboardAboutSearchProtectionsAndAds,
                                               url: URL.aboutSearchProtectionsAndAds),
                                        entities: model.adClickEntities)
                    }

                    if !model.breakagePreventionEntities.isEmpty {
                        RequestListView(description: UserText.dashboardRequestsLoadedToPreventBreakage,
                                        entities: model.breakagePreventionEntities)
                    }

                    if !model.domainRelatedEntities.isEmpty {
                        RequestListView(description: UserText.dashboardRequestsLoadedBecauseRelatedToDomain(model.domain),
                                        entities: model.domainRelatedEntities)
                    }

                    if !model.otherRequestsEntities.isEmpty {
                        RequestListView(description: UserText.dashboardOtherRequestsLoaded,
                                        entities: model.otherRequestsEntities,
                                        showHeader: model.showOtherRequestsHeader)
                    }

                    if model.thirdPartyRequestsDetected {
                        DisclaimerView()
                    }
                }
                .padding(.top)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            if !model.thirdPartyRequestsDetected {
                DisclaimerView()
                    .padding()
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}

struct RequestListView: View {

    var description: String
    var link: (text: String, url: URL)?
    var entities: [EntityDetailsModel]
    let showHeader: Bool

    init(description: String, link: (text: String, url: URL)? = nil, entities: [EntityDetailsModel], showHeader: Bool = true) {
        self.description = description
        self.link = link
        self.entities = entities
        self.showHeader = showHeader
    }

    var body: some View {
        VStack {

            if showHeader {
                Text(description)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
                    .padding(.horizontal)

                if let link = link {
                    Link(link.text, destination: link.url)
                        .font(.system(size: 12))
                        .padding(.horizontal)
                        .onHover { isHover in
                            if isHover {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }

                Divider()
            }

            VStack {
                ForEach(entities, id: \.name) { entity in
                    EntityRequestList(entity: entity)
                }
            }
            .padding(.bottom, 8)

            Divider()

        }

    }

}
