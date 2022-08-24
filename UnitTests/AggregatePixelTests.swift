//
//  AggregatePixelTests.swift
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

@testable import Core
@testable import Statistics

class AggregatePixelTests: XCTestCase {

    let userDefaults = UserDefaults(suiteName: "test")!
    let pixel = MockPixel()

    override func setUp() {
        userDefaults.removePersistentDomain(forName: "test")
        super.setUp()
    }

    func test_WhenNewInstanceOfAggregateCreatedAfterIntervalPasses_ThenFiresPixel() async throws {
        let subject1 = createSubject()
        await subject1.incrementAndSendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let subject2 = createSubject()
        await subject2.incrementAndSendIfNeeded()
        XCTAssertFalse(pixel.pixels.isEmpty)
    }

    func test_WhenAggregateHasIncrementedAndIntervalPasses_ThenFiresPixel() async throws {
        let subject = createSubject()

        await subject.incrementAndSendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        await subject.incrementAndSendIfNeeded()
        XCTAssertEqual(1, pixel.pixels.count)
        XCTAssertEqual("2", pixel.pixels[0].params?["count"])
        pixel.pixels = []

        await subject.incrementAndSendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)
    }

    private func createSubject() -> AggregatePixel {
        AggregatePixel(pixelName: .adClickAttributedPageLoads,
                                     pixelParameterName: PixelParameters.adClickAttributedPageLoadsCount,
                                     sendInterval: 1, // 1 second for testing
                                     pixel: pixel,
                                     userDefaults: userDefaults)
    }

}
