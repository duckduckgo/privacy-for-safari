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
import SafariServices
import os

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    
    override init() {
        os_log("CBRH init", log: lifecycleLog)
        super.init()
    }
    
    func beginRequest(with context: NSExtensionContext) {
        
        os_log(#function, log: lifecycleLog)
        
        let blockerListUrl = BlockerListLocation.blockerListUrl
                        
        var items = [Any]()
        if let attachment = NSItemProvider(contentsOf: blockerListUrl) {
            let item = NSExtensionItem()
            item.attachments = [attachment]
            items.append(item)
        }

        context.completeRequest(returningItems: items)
        
    }
    
    deinit {
        os_log("CBRH deinit", log: lifecycleLog)
    }
    
}
