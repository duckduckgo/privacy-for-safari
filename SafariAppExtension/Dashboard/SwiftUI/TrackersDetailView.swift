//
//  TrackersDetailView.swift
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
import SwiftUI

struct TrackersDetailView: View {

    @ObservedObject var model: TrackersDetailViewModel

    let onBack: () -> Void

    var body: some View {

        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    BackNavigationHeaderView(onBack: onBack) {
                        PageHeaderView(icon: model.icon,
                                       message: model.message,
                                       domain: model.domain,
                                       linkText: UserText.dashboardRequestsHeaderLinkText,
                                       destination: URL.aboutWebTrackingProtections)
                    }

                    ForEach(model.blockedEntities, id: \.name) { entity in
                        EntityRequestList(entity: entity)
                    }

                    if !model.blockedEntities.isEmpty {
                        VStack {
                            Divider()

                            DisclaimerView()
                                .padding(.top, 8)
                                .padding(.bottom)
                        }
                    }

                }
                .padding(.top)
                .padding(.horizontal, 20)

            }

            if model.blockedEntities.isEmpty {
                DisclaimerView()
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}
