//
//  QueueExtensions.swift
//  SafariAppExtension
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
import SafariServices

extension DispatchQueue {

    static let dashboard = DispatchQueue(label: "Dashboard")

}

extension SFSafariTab {

    func getActivePageOnQueue(_ q: DispatchQueue = DispatchQueue.dashboard, completionHandler: @escaping (SFSafariPage?) -> Void) {
        getActivePage { page in
            q.async {
                completionHandler(page)
            }
        }
    }

}

extension SFSafariPage {

    func getPropertiesOnQueue(_ q: DispatchQueue = DispatchQueue.dashboard, _ completionHandler: @escaping (SFSafariPageProperties?) -> Void) {
        getPropertiesWithCompletionHandler { properties in
            q.async {
                completionHandler(properties)
            }
        }
    }

}
