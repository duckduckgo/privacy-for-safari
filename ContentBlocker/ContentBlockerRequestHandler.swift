//
//  ContentBlockerRequestHandler.swift
//  ContentBlocker
//
//  Copyright © 2019 DuckDuckGo. All rights reserved.
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
import Statistics
import SafariServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        
        updateRetentionData()
        
        var items = [Any]()

        let blockerListUrl = Dependencies.shared.blockerListManager.blockerListUrl
        if let attachment = NSItemProvider(contentsOf: blockerListUrl) {
            let item = NSExtensionItem()
            item.attachments = [attachment]
            items.append(item)
        }

        context.completeRequest(returningItems: items)
    }

    func updateRetentionData() {
        let bundle = Bundle(for: type(of: self))
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: bundle.bundleIdentifier!) { state, _ in
            if state?.isEnabled ?? false {
                Statistics.Dependencies.shared.statisticsLoader.refreshAppRetentionAtb(atLocation: "cbrh", completion: nil)
            }
        }
    }
    
}
