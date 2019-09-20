//
//  DeepDetectionTests.swift
//  UnitTests
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

import XCTest
@testable import Statistics

class DeepDetectionTests: XCTestCase {
    
    struct Urls {
        
        static let example = URL(string: "http://example.com")!
        static let ddg = URL(string: "https://duckduckgo.com")!
        
    }
    
    func testWhenResourceIsNilThenNoPixel() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: nil, onPage: Urls.example)
        XCTAssertTrue(pixel.pixels.isEmpty)
        
    }

    func testWhenResourceIsNotDuckDuckGoThenNoPixel() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: "d.js", onPage: Urls.example)
        XCTAssertTrue(pixel.pixels.isEmpty)
        
    }

    func testWhenResourceIsNotDeepThenNoPixel() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: "sample.txt", onPage: Urls.ddg)
        XCTAssertTrue(pixel.pixels.isEmpty)
        
    }
    
    func testWhenResourceIsDeepWithCtParamThenPixelFiredIsFiredWithCtParams() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: "/d.js?q=ehello&l=wt-wt&s=0&ct=GB&ss_mkt=us", onPage: Urls.ddg)
        XCTAssertEqual(1, pixel.pixels.count)
        XCTAssertEqual("GB", pixel.pixels[0].params?["ct"])
        XCTAssertNil(pixel.pixels[0].params?["a"])

    }

    func testWhenResourceIsDeepWithCtAndAParamThenPixelFiredIsFiredWithCtAndAParams() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: "/d.js?q=ehello&l=wt-wt&s=0&a=osx&ct=GB&ss_mkt=us", onPage: Urls.ddg)
        XCTAssertEqual(1, pixel.pixels.count)
        XCTAssertEqual(pixel.pixels[0].name, .safariBrowserExtensionSearch)
        XCTAssertEqual("GB", pixel.pixels[0].params?["ct"])
        XCTAssertEqual("osx", pixel.pixels[0].params?["a"])

    }

    func testWhenResourceIsNotDeepWithCtAndAParamThenPixelFiredIsFiredWithCtAndAParams() {
    
        let pixel = MockPixel()
        let detection = DeepDetection(pixel: pixel)
        detection.check(resource: "/notdeep.js?q=ehello&l=wt-wt&s=0&a=osx&ct=GB&ss_mkt=us", onPage: Urls.ddg)
        XCTAssertEqual(0, pixel.pixels.count)

    }

}
