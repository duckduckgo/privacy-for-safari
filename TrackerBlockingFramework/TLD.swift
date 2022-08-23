//
//  TLD.swift
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

public class TLD {

    private(set) var tlds: Set<String> = []

    var json: String {
        guard let data = try? JSONEncoder().encode(tlds) else { return "[]" }
        guard let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    public init() {
        guard let url = Bundle.main.url(forResource: "tlds", withExtension: "json") else { return }
        guard let data = try? Data(contentsOf: url) else { return }

        let asString = String(decoding: data, as: UTF8.self)
        let asStringWithoutComments = asString.replacingOccurrences(of: "(?m)^//.*",
                                                                    with: "",
                                                                    options: .regularExpression)
        guard let cleanedData: Data = asStringWithoutComments.data(using: .utf8) else { return }

        guard let tlds = try? JSONDecoder().decode([String].self, from: cleanedData) else { return }
        self.tlds = Set(tlds)
    }

    /// Return valid domain, stripping subdomains of given entity if possible.
    ///
    /// 'test.example.co.uk' -> 'example.co.uk'
    /// 'example.co.uk' -> 'example.co.uk'
    /// 'co.uk' -> 'co.uk'
    public func domain(_ host: String?) -> String? {
        guard let host = host else { return nil }

        let parts = [String](host.components(separatedBy: ".").reversed())

        var stack = ""

        var knownTLDFound = false
        for part in parts {
            stack = !stack.isEmpty ? part + "." + stack : part

            if tlds.contains(stack) {
                knownTLDFound = true
            } else if knownTLDFound {
                break
            }
        }

        // If host does not contain tld treat it as invalid
        if knownTLDFound {
            return stack
        } else {
            return nil
        }
    }

    /// Return eTLD+1 (entity top level domain + 1) strictly.
    ///
    /// 'test.example.co.uk' -> 'example.co.uk'
    /// 'example.co.uk' -> 'example.co.uk'
    /// 'co.uk' -> nil
    public func eTLDplus1(_ host: String?) -> String? {
        guard let domain = domain(host), !tlds.contains(domain) else { return nil }
        return domain
    }

}
