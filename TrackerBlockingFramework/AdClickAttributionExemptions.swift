//
//  AdClickAttributionExemptions.swift
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
import os

public class AdClickAttributionExemptions {

    public static let shared = AdClickAttributionExemptions()

    public internal(set) var allowList = [AdClickAttributionFeature.AllowlistEntry]()
    public internal(set) var vendorDomains = [String]() {
        willSet {
            let oldDomains = Set<String>(vendorDomains)
            let newDomains = Set<String>(newValue)
            observedVendors = observedVendors.subtracting(oldDomains.subtracting(newDomains))
        }
    }
    public internal(set) var observedVendors = Set<String>() {
        didSet {
            os_log("ADA observedVendors = %{public}s", log: generalLog, type: .debug, String(describing: observedVendors))
        }
    }

    func containsVendor(_ named: String) -> Bool {
        return vendorDomains.contains(named)
    }

}
