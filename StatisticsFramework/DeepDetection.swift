//
//  DeepDetection.swift
//  DuckDuckGo Privacy for Safari
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

    struct Params {
        
        static let country = "ct"
        static let affiliate = "a"
        static let query = "q"
        static let sequence = "s"
        
    }
    
    private let pixel: Pixel
    private let statisticsLoader: StatisticsLoader
    
    public init(pixel: Pixel = Dependencies.shared.pixel,
                statisticsLoader: StatisticsLoader = DefaultStatisticsLoader.shared) {
        self.pixel = pixel
        self.statisticsLoader = statisticsLoader
    }
    
    public func check(resource: String?, onPage pageUrl: URL) {
        
        guard pageUrl.host == "duckduckgo.com" else { return }
        
        guard let resource = resource else { return }
        guard let components = URLComponents(string: resource) else { return }
        guard components.path == "/d.js" else { return }
        guard components.queryItems?.first(where: { $0.name == Params.sequence && $0.value == "0" }) != nil else { return }
                
        var params = [String: String]()
        if let ct = components.queryItems?.first(where: { $0.name == Params.country })?.value {
            params[Params.country] = ct
        }

        if let a = components.queryItems?.first(where: { $0.name == Params.affiliate })?.value {
            params[Params.affiliate] = a
        }

        pixel.fire(.safariBrowserExtensionSearch, withParams: params)
     
        checkForSearch(pageUrl)
    }
    
    private func checkForSearch(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard components?.queryItems?.contains(where: { $0.name == Params.query  }) ?? false else { return }
        statisticsLoader.refreshSearchRetentionAtb(atLocation: AtbLocations.deepDetection, completion: nil)
    }
    
}
