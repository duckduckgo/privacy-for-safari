//
//  SafariTabAddClickAttribution.swift
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
import SafariServices
import os
import TrackerBlocking

struct SafariTabAddClickAttribution {

    struct ContentBlockerReloader: AdClickContentBlockerReloading {
        func reload() async {
            do {
                try await ContentBlockerExtension.reload()
            } catch {
                os_log("Failed to reload Content Blocker Extension %{public}s", log: generalLog, type: .error, error.localizedDescription)
            }
        }
    }

    static let shared: AdClickAttribution<SFSafariTab> = {
        let attribution = AdClickAttribution<SFSafariTab>(
            config: DefaultAdClickAttributionConfig(),
            pixelFiring: DefaultAdClickPixelFiring(),
            blockerListManager: Dependencies.shared.blockerListManager,
            contentBlockerReloader: ContentBlockerReloader()
        )

        // If this is being recreated then Safari was restarted or similar,
        //  but either way reset the exemptions to prevent trackers leaking.
        Task {
            await attribution.resetContentBlockingExemptions()
        }
        return attribution
    }()

}

extension SFSafariTab: Tabbing { }
