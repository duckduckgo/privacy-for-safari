//
//  XPCStatisticsLoader.swift
//  HelperSupport
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
import Statistics
import os

@objc class XPCStatisticsLoaderDelegate: NSObject, NSXPCListenerDelegate {

    let service: XPCStatisticsLoader

    init(service: XPCStatisticsLoader) {
        self.service = service
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        os_log(#function, log: generalLog, type: .default)
        newConnection.exportedInterface = NSXPCInterface(with: StatisticsLoader.self)
        newConnection.exportedObject = service
        newConnection.resume()
        return true
    }

}

public class XPCStatisticsLoader: StatisticsLoader {

    static let delegate = XPCStatisticsLoaderDelegate(service: XPCStatisticsLoader())

    private let queue: DispatchQueue
    private let loader: StatisticsLoader

    init(loader: StatisticsLoader = DefaultStatisticsLoader(), usingQueue queue: DispatchQueue = DispatchQueue(label: "StatisticsLoader")) {
        self.loader = loader
        self.queue = queue
    }

    public func refreshSearchRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        os_log("refreshing search retention", log: generalLog, type: .default)
        queue.async {
            let group = DispatchGroup()
            group.enter()
            self.loader.refreshSearchRetentionAtb(atLocation: location) {
                completion?()
                group.leave()
            }
            group.wait()
        }
    }

    public func refreshAppRetentionAtb(atLocation location: String, completion: StatisticsLoaderCompletion?) {
        os_log("refreshing app retention", log: generalLog, type: .default)
        queue.async {
            let group = DispatchGroup()
            group.enter()
            self.loader.refreshAppRetentionAtb(atLocation: location) {
                completion?()
                group.leave()
            }
            group.wait()
        }
    }

    public static func start() {
        if Dependencies.shared.statisticsStore.installAtb == nil {
            delegate.service.refreshAppRetentionAtb(atLocation: AtbLocations.xpcStart, completion: nil)
        }
        
        let xpc = NSXPCListener(machServiceName: BundleIds.xpcServiceName)
        xpc.delegate = delegate
        xpc.resume()
    }

}
