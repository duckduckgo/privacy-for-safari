//
//  AggregatePixel.swift
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

public actor AggregatePixel {

    var lastSendDate: Date {
        get {
            let interval = userDefaults.double(forKey: lastSendDateKey)

            // If this is new then set the last send date to now so we don't send until the next interval
            if interval < 1 {
                let date = Date()
                userDefaults.set(date.timeIntervalSince1970, forKey: lastSendDateKey)
                return date
            }
            return Date(timeIntervalSince1970: interval)
        }

        set {
            let interval = newValue.timeIntervalSince1970
            userDefaults.set(interval, forKey: lastSendDateKey)
        }
    }

    var counter: Int {
        get {
            return userDefaults.integer(forKey: counterKey)
        }

        set {
            userDefaults.set(newValue, forKey: counterKey)
        }
    }

    let pixelName: PixelName
    let sendInterval: TimeInterval
    let pixel: Pixel
    let pixelParameterName: String
    let userDefaults: UserDefaults

    var lastSendDateKey: String {
        return "\(pixelName.rawValue).lastSendDate"
    }

    var counterKey: String {
        return "\(pixelName.rawValue).counter"
    }

    public init(pixelName: PixelName,
                pixelParameterName: String,
                sendInterval: TimeInterval,
                pixel: Pixel = Dependencies.shared.pixel,
                userDefaults: UserDefaults = .standard) {

        self.pixelName = pixelName
        self.pixelParameterName = pixelParameterName
        self.sendInterval = sendInterval
        self.pixel = pixel
        self.userDefaults = userDefaults
    }

    public func incrementAndSendIfNeeded() async {
        counter += 1
        await sendIfNeeded()
    }

    public func sendIfNeeded() async {
        let lastSendInterval = lastSendDate.timeIntervalSinceNow * -1
        print("***", #function, lastSendDate)

        guard lastSendInterval > sendInterval else { return }
        if counter > 0 {
            pixel.fire(pixelName, withParams: [ pixelParameterName: "\(counter)" ]) { _ in
                self.counter = 0
                self.lastSendDate = Date()
            }
        } else {
            counter = 0
            lastSendDate = Date()
        }
    }

}
