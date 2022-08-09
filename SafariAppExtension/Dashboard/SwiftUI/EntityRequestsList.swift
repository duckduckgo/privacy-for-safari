//
//  EntityRequestsList.swift
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

struct EntityRequestList: View {

    var entity: EntityDetailsModel

    var body: some View {
        VStack {
            HStack {
                Text(entity.name)
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                if let image = NSImage(named: entity.image) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color("UnknownNetworkColor"))
                            .frame(width: 24, height: 24)

                        Text(entity.name.uppercased().prefix(1))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(NSColor.controlBackgroundColor))
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(entity.requests, id: \.domain) { request in
                    HStack {
                        Text(request.domain)
                        Spacer()
                        Text(request.category)
                    }
                    .font(.system(size: 13))
                }
            }
            .padding(.bottom, 12)
        }
    }

}
