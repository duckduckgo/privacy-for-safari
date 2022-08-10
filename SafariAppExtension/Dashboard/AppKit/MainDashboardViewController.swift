//
//  MainDashboardViewController.swift
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

import SwiftUI
import Statistics
import TrackerBlocking
import SafariServices

@MainActor
class MainDashboardViewController: DashboardNavigationController {

    private var hostingView: NSHostingView<MainDashboardView>?

    private var model = MainDashboardViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingView = NSHostingView(
            rootView: MainDashboardView(model: model) { controller in
                self.navigationDelegate?.push(controller: controller)
            }
        )

        view.addSubview(hostingView)
        self.hostingView = hostingView

        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(onTrustedSitesChanged),
                                                            name: TrustedSitesNotification.sitesUpdatedNotificationName,
                                                            object: nil)

    }

    override var pageData: PageData? {
        didSet {
            guard isViewLoaded else { return }
            model.updateFromPageData(pageData)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        hostingView?.frame = view.frame
    }

    @objc func onTrustedSitesChanged() {
        Task { @MainActor in
            model.pageData = await DashboardData.shared.pageData
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        Task { @MainActor in
            pageData = await DashboardData.shared.pageData
        }
    }

}
