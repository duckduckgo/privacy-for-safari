//
//  APIHeaders.swift
//  Core
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

public class APIHeaders {
    
    public struct Name {
        public static let userAgent = "User-Agent"
        public static let etag = "ETag"
    }
    
    private let appVersion: AppVersion
    
    public init(appVersion: AppVersion = DefaultAppVersion()) {
        self.appVersion = appVersion
    }
    
    public var defaultHeaders: [String: String] {
        return [
            Name.userAgent: userAgent
        ]
    }

    private var osVersion: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }
    
    public var userAgent: String {
        return "ddg_macos/\(appVersion.fullVersion) (\(appVersion.identifier); macOS \(osVersion))"
    }
    
    public func addHeaders(to request: inout URLRequest) {
        request.addValue(userAgent, forHTTPHeaderField: Name.userAgent)
    }
    
}
