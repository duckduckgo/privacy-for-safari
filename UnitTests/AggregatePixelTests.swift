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
    var pixel = MockPixel()

    override func setUp() {
        userDefaults.removePersistentDomain(forName: "test")
        super.setUp()
    }

    func test() async throws {
        pixel = DelayedMockPixel(delay: 1.0)
        let subject1 = createSubject()
        await subject1.incrementAndSendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds allows things to fire

        await subject1.sendIfNeeded() // This will wait 5.0 seconds before sending using concurrency to block further calls

        (pixel as? DelayedMockPixel)?.delay = 0.0 // allows subsequent calls to fire instantly

        Task {
            await subject1.incrementAndSendIfNeeded() // Concurrency will increment the counter but prevent this firing
        }

//        XCTAssertEqual(1, pixel.pixels.count)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds allows things to fire again
        await subject1.incrementAndSendIfNeeded() // Increment again, and try to send which should happen immediately

        XCTAssertEqual(2, pixel.pixels.count)

        XCTAssertEqual("1", pixel.pixels[0].params?["count"])
        XCTAssertEqual("2", pixel.pixels[1].params?["count"])
    }

    func test_WhenPixelFiredAndIntervalPassesButNoCount_ThenNoPixelFired() async throws {
        let subject = createSubject()
        await subject.sendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        await subject.sendIfNeeded()
        XCTAssertTrue(pixel.pixels.isEmpty)
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

private class DelayedMockPixel: MockPixel {

    var delay: TimeInterval

    init(delay: TimeInterval) {
        self.delay = delay
    }

    override func fire(_ pixel: PixelName, withParams params: [String: String], onComplete: @escaping PixelCompletion) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            super.fire(pixel, withParams: params, onComplete: onComplete)
        }
    }

}
