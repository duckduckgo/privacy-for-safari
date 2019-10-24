//
//  ContentBlockerExtension.swift
//  DuckDuckGo
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
import os

class ContentBlockerExtension {
    
    typealias Completion = (Error?) -> Void
    
    static func reload(completion: Completion? = nil) {
        os_log("ContentBlockerExtension reload START", log: generalLog)
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: BundleIds.contentBlockerExtension) { error in
            os_log("ContentBlockerExtension reload END, %{public}s", log: generalLog, error?.localizedDescription ?? "SUCCESS")
            completion?(error)
        }
    }
    
    static func reloadSync() {
        os_log("ContentBlockerExtension reloadSync START", log: generalLog)
        let group = DispatchGroup()
        group.enter()
        reload { _ in
            group.leave()
        }
        group.wait()
        os_log("ContentBlockerExtension reloadSync END", log: generalLog)
    }
    
}
