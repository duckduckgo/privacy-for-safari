//
//  DashboardNavigationDelegate.swift
//  Safari App Extension
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

import Cocoa
import SafariServices
import TrackerBlocking

enum DashboardControllers: String {
    case main = "MainDashboard"
    case trackersDetail = "TrackersDetail"
    case requestsDetail = "RequestsDetail"
    case reportBrokenWebsite = "ReportBrokenWebsite"
}

class DashboardNavigationController: NSViewController {
    
    weak var navigationDelegate: DashboardNavigationDelegate?
    var pageData: PageData?
    
    @IBAction func back(sender: Any) {
        navigationDelegate?.popController()
    }
    
}

protocol DashboardNavigationDelegate: NSObjectProtocol {
    
    func push(controller: DashboardControllers)

    func popController()

    func present(controller: DashboardControllers)

    func closeController()
    
}
