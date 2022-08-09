//
//  PageHeaderView.swift
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

struct PageHeaderView: View {

    let icon: String
    let message: String
    let domain: String
    let linkText: String
    let destination: URL

    var body: some View {
        VStack(spacing: 12) {
            Image(icon)
                .padding(.bottom, 6)

            DomainLabel(name: domain)

            Text(message)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .lineSpacing(7)
                .font(.system(size: 13, weight: .regular))

            Link(linkText, destination: destination)
                .font(.system(size: 14))
                .onHover { isHover in
                    if isHover {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }

            Divider()
        }
    }

}
