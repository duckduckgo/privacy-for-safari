//
//  AdClickAttributionConfig.swift
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

public enum AttributionType {

    case none
    case vendor(name: String)
    case heuristic

}

public struct AdClickAttributionFeature {
    public struct AllowlistEntry {
        public let blocklistEntry: String
        public let host: String
    }

    public struct LinkFormat: Decodable {
        public let url: String
        public let adDomainParameterName: String?

        // https://app.asana.com/0/481882893211075/1202389492148020/f

        func isMatch(url: URL) -> Bool {
            guard let host = url.host,
                  "\(host)\(url.path)" == self.url else { return false }

            if let adDomainParameterName = adDomainParameterName,
               url.getParameter(named: adDomainParameterName) != nil {
                // also returns true if present but blank
                return true
            }

            return false
        }
    }

}

public protocol AdClickAttributionConfig {

    var isEnabled: Bool { get }
    var allowlist: [AdClickAttributionFeature.AllowlistEntry] { get }
    var navigationExpiration: Double { get }
    var totalExpiration: Double { get }
    var isHeuristicDetectionEnabled: Bool { get }
    var isDomainDetectionEnabled: Bool { get }

    var linkFormats: [AdClickAttributionFeature.LinkFormat] { get }

    func attributionTypeForURL(_ url: URL) -> AttributionType
    func hasExemptionExpired(_ date: Date) -> Bool
    func resourceIsOnAllowlist(_ url: URL) -> Bool

}

public struct DefaultAdClickAttributionConfig: AdClickAttributionConfig {

    public let isEnabled: Bool = true
    public let isHeuristicDetectionEnabled: Bool = true
    public let isDomainDetectionEnabled: Bool = true

    public let allowlist: [AdClickAttributionFeature.AllowlistEntry] = [
        .init(blocklistEntry: "bing.com", host: "bat.bing.com"),
        .init(blocklistEntry: "ad-company.site", host: "convert.ad-company.site"),
        .init(blocklistEntry: "ad-company.example", host: "convert.ad-company.example")
    ]

    public let navigationExpiration: Double = 0.5
    public let totalExpiration: Double = 72.hours

    // https://app.asana.com/0/0/1202445948430383/f (as of July 25,2022)
    let linkFormatsJSON =
"""
[
    {
        "url": "duckduckgo.com/y.js",
        "adDomainParameterName": "ad_domain",
        "desc": "SERP Ads"
    },
    {
        "url": "www.search-company.site/y.js",
        "adDomainParameterName": "ad_domain",
        "desc": "Test Domain"
    },
    {
        "url": "www.search-company.example/y.js",
        "adDomainParameterName": "ad_domain",
        "desc": "Test Domain"
    },
    {
        "url": "links.duckduckgo.com/m.js",
        "adDomainParameterName": "ad_domain",
        "desc": "Shopping Ads"
    },
    {
        "url": "www.search-company.site/m.js",
        "adDomainParameterName": "ad_domain",
        "desc": "Test Domain"
    },
    {
        "url": "www.search-company.example/m.js",
        "adDomainParameterName": "ad_domain",
        "desc": "Test Domain"
    }
]
"""

    public let linkFormats: [AdClickAttributionFeature.LinkFormat]

    public init() {
        let data = linkFormatsJSON.data(using: .utf8)!
        do {
            linkFormats = try JSONDecoder().decode([AdClickAttributionFeature.LinkFormat].self, from: data)
        } catch {
            fatalError("Unable to parse link formats JSON")
        }
    }

    public func attributionTypeForURL(_ url: URL) -> AttributionType {
        guard isEnabled else { return .none }

        guard let format = findMatchingLinkFormatForURL(url) else { return .none }

        if !isDomainDetectionEnabled {
            return isHeuristicDetectionEnabled ? .heuristic : .none
        }

        if let adParam = format.adDomainParameterName,
           let vendorDomain = url.getParameter(named: adParam)?.trimmingCharacters(in: .whitespaces) {
            if let name = TLD.shared.eTLDplus1(vendorDomain) {
                return .vendor(name: name)
            }
        }

        return isHeuristicDetectionEnabled ? .heuristic : .none
    }

    public func hasExemptionExpired(_ date: Date) -> Bool {
        let age = date.timeIntervalSinceNow * -1
        os_log("ACA hasExemptionExpired %{public}s", log: generalLog, type: .debug, "\(date) \(age) vs \(totalExpiration)")
        return age >= totalExpiration
    }

    public func resourceIsOnAllowlist(_ url: URL) -> Bool {
        return allowlist.contains(where: {
            $0.host == url.host
        })
    }

    private func findMatchingLinkFormatForURL(_ url: URL) -> AdClickAttributionFeature.LinkFormat? {
        return linkFormats.first(where: { $0.isMatch(url: url) })
    }

}

fileprivate extension URL {

    func getParameter(named name: String) -> String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == name })?.value
    }

}

extension TLD {

    public static let shared = TLD()

}

public extension URL {

    var eTLDPlus1Host: String? {
        TLD.shared.eTLDplus1(host)
    }

}
