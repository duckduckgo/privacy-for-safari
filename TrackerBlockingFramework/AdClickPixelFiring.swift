//
//  AdClickPixelFiring.swift
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
import Statistics
import os

// https://app.asana.com/0/0/1202565358472695/f
public protocol AdClickPixelFiring {

    func fireAdClickDetected(vendorDomainFromParameter: String?, vendorDomainFromHeuristic: String?)
    func fireAdClickAllowListUsed()
    func fireAdClickHeuristicValidation(domainMatches: Bool)
    func incrementAdClickPageLoadCounterAndSendIfNeeded()

}

public class DefaultAdClickPixelFiring: AdClickPixelFiring {

    enum RegistrationType: String {

        /// both SERP-provided and heuristic domain matched
        case matched

        /// SERP-provided domain does not match heuristic
        case mismatch

        /// only SERP-provided domain used, heuristic not run
        case serpOnly = "serp_only"

        /// only heuristic domain used, SERP did not provide a domain
        case heuristicOnly = "heuristic_only"

        /// both methods did not return a domain (should never happen)
        case none

    }

    private let pixel: Pixel

    private let pageLoadsPixel = AggregatePixel(pixelName: .adClickAttributedPageLoads,
                                                pixelParameterName: PixelParameters.adClickAttributedPageLoadsCount,
                                                sendInterval: isDebugBuild ? 60.0 : 24.hours)

    public init(pixel: Pixel = Statistics.Dependencies.shared.pixel) {
        self.pixel = pixel

        Task {
            await pageLoadsPixel.sendIfNeeded()
        }
    }

    public func incrementAdClickPageLoadCounterAndSendIfNeeded() {
        Task {
            await pageLoadsPixel.incrementAndSendIfNeeded()
        }
    }

    public func fireAdClickDetected(vendorDomainFromParameter: String?, vendorDomainFromHeuristic: String?) {
        let registrationType: RegistrationType

        switch (vendorDomainFromParameter, vendorDomainFromHeuristic) {

        case (let param, let heuristic) where param != nil && param == heuristic:
            registrationType = .matched

        case (let param, let heuristic) where param != nil && heuristic == nil:
            registrationType = .serpOnly

        case (let param, let heuristic) where param == nil && heuristic != nil:
            registrationType = .heuristicOnly

        case (let param, let heuristic) where param != heuristic:
            registrationType = .mismatch

        default: // param and heuristic must both be nil here
            registrationType = .none
        }

        os_log("ACA fireAdClickDetected %{public}s", log: generalLog, type: .debug, registrationType.rawValue)
        pixel.fire(.adClickDetected, withParams: [
            "domainDetection": registrationType.rawValue
        ])
    }

    public func fireAdClickAllowListUsed() {
        os_log("ACA fireAdClickAllowListUsed", log: generalLog, type: .debug)
        pixel.fire(.adClickActive)
    }

    public func fireAdClickHeuristicValidation(domainMatches: Bool) {
        os_log("ACA fireAdClickHeuristicValidation %{public}s", log: generalLog, type: .debug,
               domainMatches ? "match" : "mismatch")
        if domainMatches {
            pixel.fire(.adClickHeuristicValidationMatch)
        } else {
            pixel.fire(.adClickHeuristicValidationMismatch)
        }
    }

}
