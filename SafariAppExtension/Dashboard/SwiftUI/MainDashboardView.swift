//
//  MainDashboardView.swift
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

struct MainDashboardView: View {

    @ObservedObject var model: MainDashboardViewModel

    let push: (DashboardControllers) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DashboardHeaderView(isNewTab: model.isNewTab,
                                gradeHeroImage: model.gradeHeroImage,
                                domain: model.domain,
                                protectionsEnabled: model.protectionsEnabled,
                                temporarilyDisabled: model.temporarilyDisabled,
                                enhancedFromGrade: model.enhancedFromGrade)
            .frame(height: 190)
#if DEBUG
            .modifier(StateTextModifier(state: model.state))
#endif

            NavigationCell(title: model.encryptionStatusText, icon: model.encryptionStatusIcon)

            NavigationCell(title: model.trackersBlockedText, icon: model.trackersBlockedIcon) {
                push(.trackersDetail)
            }

            NavigationCell(title: model.requestsLoadedText, icon: model.requestsLoadedIcon) {
                push(.requestsDetail)
            }

            NavigationCell(title: model.privacyPracticesText, icon: model.privacyPracticesIcon)

            ProtectionToggleView(protectionsEnabled: Binding(get: {
                model.protectionsEnabled
            }, set: { isOn in
                model.toggleProtectionState(isOn)
            }))

            ZStack {
                if !model.isItBrokenShowing {
                    DashboardFooterButtons(onManagedUnprotectedSites: model.manageUnprotectedSites) {
                        push(.reportBrokenWebsite)
                    }
                    .onHover { isHover in
                        if isHover {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }

                if model.isItBrokenShowing {

                    IsItBrokenView(showing: $model.isItBrokenShowing) {
                        push(.reportBrokenWebsite)
                    }
                    .transition(.move(edge: .bottom))

                }

            }
            .frame(height: 50)

        }
        .frame(width: 310)
        .onHover { isHover in
            if isHover {
                NSCursor.arrow.push()
            } else {
                NSCursor.pop()
            }
        }
    }

}

struct IsItBrokenView: View {

    @Binding var showing: Bool

    let onReportBrokenSite: () -> Void

    var body: some View {
        VStack {
            Text(UserText.dashboardIsWebsiteBroken)

            HStack {
                Spacer()

                Button(UserText.dashboardIsWebsiteBrokenYes) {
                    withAnimation {
                        showing = false
                    }
                    onReportBrokenSite()
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(UserText.dashboardIsWebsiteBrokenNo) {
                    withAnimation {
                        showing = false
                    }
                }
                .buttonStyle(.borderless)

                Spacer()

            }
        }
        .modifier(DashboardTextModifier(size: 15))
    }

}

struct DashboardFooterButtons: View {

    let onManagedUnprotectedSites: () -> Void
    let onReportBrokenWebsite: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button {
                onManagedUnprotectedSites()
            } label: {
                Text(UserText.dashboardFooterManageUnprotectedSites)
                    .modifier(DashboardTextModifier())
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)

            Spacer()

            Divider()
                .padding(0)

            Spacer()

            Button {
                onReportBrokenWebsite()
            } label: {
                Text(UserText.dashboardFooterReportBroken)
                    .modifier(DashboardTextModifier())
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity)

            Spacer()

        }
    }

}

struct ProtectionToggleView: View {

    @Binding var protectionsEnabled: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                Text(UserText.dashboardToggleProtection)
                    .modifier(DashboardTextModifier())

                Spacer()

                Toggle("", isOn: $protectionsEnabled)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)
            .padding(.leading, 4)
            .frame(height: 50)

            Divider()
        }.frame(height: 50)
    }

}

struct NavigationCell: View {

    let title: String
    let icon: String
    let action: (() -> Void)?

    init(title: String, icon: String, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {

        let content = HStack {
            Image(icon)
            Text(title)
                .modifier(DashboardTextModifier())

            Spacer()

            if action != nil {
                Image("PP Arrow Forward")
            }
        }
        .frame(height: 50)
        .padding(.horizontal)

        ZStack(alignment: .bottom) {

            if let action = action {
                Button {
                    action()
                } label: {
                    content
                        .onHover { isHover in
                            if isHover {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
                .modifier(PreferBorderlessButtonStyleModifier())
                .frame(maxWidth: .infinity)
            } else {
                content
            }

            Divider()
        }
        .frame(height: 50)
    }

}

/// On macOS 11 borderless does not size correctly, but it's preferred because otherwise the button doesn't press if the user clicks in the space between content
struct PreferBorderlessButtonStyleModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(macOS 12, *) {
            content.buttonStyle(.borderless)
        } else {
            content.buttonStyle(.plain)
        }
    }

}

struct DashboardHeaderView: View {

    let isNewTab: Bool
    let gradeHeroImage: String
    let domain: String
    let protectionsEnabled: Bool
    let temporarilyDisabled: Bool
    let enhancedFromGrade: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack(alignment: .center, spacing: 8) {
                Group {
                    Image(gradeHeroImage)
                        .resizable()
                        .frame(width: 140, height: 105)

                    DomainLabel(name: domain)

                    HStack {
                        if temporarilyDisabled {

                            Text(UserText.dashboardSiteTemporarilyDisabled)
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 11, weight: .medium))

                        } else {

                            Group {
                                if isNewTab {
                                    Text(UserText.dashboardSiteIsNewTab)
                                } else if let enhancedFromGrade = enhancedFromGrade {
                                    Text(UserText.dashboardSiteIsEnhancedFrom)
                                    Image(enhancedFromGrade)
                                } else {
                                    Text(UserText.dashboardSitePrivacyGrade)
                                }
                            }
                            .modifier(HeaderMessageTextModifier())

                        }

                    }.frame(height: 14)

                }.padding(.horizontal)
            }.frame(height: 190)

            Divider()
        }
    }

}

struct HeaderMessageTextModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color("HeaderMessage"))
            .textCase(.uppercase)

    }

}

struct DashboardTextModifier: ViewModifier {

    let size: CGFloat

    init(size: CGFloat = 14) {
        self.size = size
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .medium))
            .foregroundColor(Color("ItemTitle"))

    }

}

#if DEBUG
struct StateTextModifier: ViewModifier {

    let state: String

    func body(content: Content) -> some View {
        if #available(macOS 12, *) {
            content
                .overlay {
                    Text("State: \(state)")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
        }
    }

}
#endif
