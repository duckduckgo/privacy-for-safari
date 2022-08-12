//
//  AdClickPixelFiringTests.swift
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

import XCTest
@testable import TrackerBlocking
@testable import Statistics

class AdClickPixelFiringTests: XCTestCase {

    let pixel = MockPixel()

    func testWhen_parameterAndHeuristicAreMissing_Then_PixelFiredWithDomainDetectionParameterSetToNone() {
        let subject = DefaultAdClickPixelFiring(pixel: pixel)
        subject.fireAdClickDetected(vendorDomainFromParameter: nil, vendorDomainFromHeuristic: nil)
        XCTAssertEqual(pixel.pixels[0].name, PixelName.adClickDetected)
        XCTAssertEqual(pixel.pixels[0].params?["domainDetection"], "none")
    }

    func testWhen_parameterPresentAndHeuristicMissing_Then_PixelFiredWithDomainDetectionParameterSetToSerpOnly() {
        let subject = DefaultAdClickPixelFiring(pixel: pixel)
        subject.fireAdClickDetected(vendorDomainFromParameter: "serp", vendorDomainFromHeuristic: nil)
        XCTAssertEqual(pixel.pixels[0].name, PixelName.adClickDetected)
        XCTAssertEqual(pixel.pixels[0].params?["domainDetection"], "serp_only")
    }

    func testWhen_parameterMissingAndHeuristicPresent_Then_PixelFiredWithDomainDetectionParameterSetToSerpOnly() {
        let subject = DefaultAdClickPixelFiring(pixel: pixel)
        subject.fireAdClickDetected(vendorDomainFromParameter: nil, vendorDomainFromHeuristic: "heuristic")
        XCTAssertEqual(pixel.pixels[0].name, PixelName.adClickDetected)
        XCTAssertEqual(pixel.pixels[0].params?["domainDetection"], "heuristic_only")
    }

    func testWhen_parameterAndHeuristicSame_Then_PixelFiredWithDomainDetectionParameterSetToMatch() {
        let subject = DefaultAdClickPixelFiring(pixel: pixel)
        subject.fireAdClickDetected(vendorDomainFromParameter: "match", vendorDomainFromHeuristic: "match")
        XCTAssertEqual(pixel.pixels[0].name, PixelName.adClickDetected)
        XCTAssertEqual(pixel.pixels[0].params?["domainDetection"], "matched")
    }

    func testWhen_parameterAndHeuristicPresentButNotSame_Then_PixelFiredWithDomainDetectionParameterSetToMatch() {
        let subject = DefaultAdClickPixelFiring(pixel: pixel)
        subject.fireAdClickDetected(vendorDomainFromParameter: "hello", vendorDomainFromHeuristic: "world")
        XCTAssertEqual(pixel.pixels[0].name, PixelName.adClickDetected)
        XCTAssertEqual(pixel.pixels[0].params?["domainDetection"], "mismatch")
    }

}
