//
//  PageController.swift
//  SafariAppExtension
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

import AppKit
import TrackerBlocking
import os

class NavigationController: NSPageController {

    var pageData: PageData? {
        didSet {
            os_log("SEVC sent page data", log: lifecycleLog, type: .debug)
            updateSelectedViewController()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        transitionStyle = .horizontalStrip
        delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        arrangedObjects = [ DashboardControllers.main ]
        updateSelectedViewController()
    }

    private func updateSelectedViewController() {
        (selectedViewController as? DashboardNavigationController)?.pageData = pageData
    }
    
    override func scrollWheel(with event: NSEvent) {
        // prevent the swipe bounce from happening
    }

}

extension NavigationController: DashboardNavigationDelegate {

    func present(controller: DashboardControllers) {
        arrangedObjects.append(controller)
        self.selectedIndex += 1
        DispatchQueue.main.async {
            self.updateSelectedViewController()
            self.selectedViewController?.viewDidAppear()
        }
    }

    func closeController() {
        popController()
    }

    func push(controller: DashboardControllers) {
        arrangedObjects.append(controller)
        navigateForward(self)
        DispatchQueue.main.async {
            self.updateSelectedViewController()
            self.selectedViewController?.viewDidAppear()
        }
    }

    func popController() {
        guard arrangedObjects.count > 1 else { return }
        navigateBack(self)
        DispatchQueue.main.async {
            _ = self.arrangedObjects.popLast()
            self.updateSelectedViewController()
        }
    }

}

extension NavigationController: NSPageControllerDelegate {

    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        updateSelectedViewController()
        completeTransition()
    }

    func pageControllerWillStartLiveTransition(_ pageController: NSPageController) {
        updateSelectedViewController()
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let controllerId = object as? DashboardControllers else {
            fatalError("Unexpected object \(object)")
        }
        return controllerId.rawValue
    }

    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {

        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) else {
            fatalError("instantiateController with identifier \(identifier) failed")
        }

        guard let navController = controller as? DashboardNavigationController else {
            fatalError("failed to convert \(controller) to DashboardNavigationController")
        }
        navController.pageData = pageData
        navController.navigationDelegate = self
        return navController
    }

}
