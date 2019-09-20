//
//  DeepDetection.swift
//  DuckDuckGo Privacy Essentials
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
import Core

public class DeepDetection {
    
    private let pixel: Pixel
    
    public init(pixel: Pixel = Dependencies.shared.pixel) {
        self.pixel = pixel
    }
    
    public func check(resource: String?, onPage pageUrl: URL) {
        
        guard pageUrl.host == "duckduckgo.com" else { return }
        
        guard let resource = resource else { return }
        guard let components = URLComponents(string: resource) else { return }
        guard components.path == "/d.js" else { return }
        
        var params = [String: String]()
        if let ct = components.queryItems?.first(where: { $0.name == "ct" })?.value {
            params["ct"] = ct
        }

        if let a = components.queryItems?.first(where: { $0.name == "a" })?.value {
            params["a"] = a
        }

        pixel.fire(.safariBrowserExtensionSearch, withParams: params)
    }
    
}
