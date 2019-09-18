//
//  PageController.swift
//  SafariAppExtension
//
//  Created by Christopher Brind on 02/07/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit
import TrackerBlocking

class NavigationController: NSPageController {

    var pageData: PageData? {
        didSet {
            NSLog("\(self) didSet pageData \(pageData as Any)")
            updateSelectedViewController()
        }
    }

    override func viewDidLoad() {
        NSLog("\(self) \(#function)")
        super.viewDidLoad()
        delegate = self
        transitionStyle = .horizontalStrip
    }
    
    override func viewWillAppear() {
        NSLog("\(self) \(#function)")
        super.viewWillAppear()
        arrangedObjects = [ DashboardControllers.main ]
        updateSelectedViewController()
    }

    private func updateSelectedViewController() {
        NSLog("\(self) \(#function)")
        (selectedViewController as? DashboardNavigationController)?.pageData = pageData
    }

}

extension NavigationController: DashboardNavigationDelegate {

    func present(controller: DashboardControllers) {
        NSLog("\(self) \(#function)")
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
        NSLog("\(self) \(#function)")
        arrangedObjects.append(controller)
        navigateForward(self)
        DispatchQueue.main.async {
            self.updateSelectedViewController()
            self.selectedViewController?.viewDidAppear()
        }
    }

    func popController() {
        NSLog("\(self) \(#function)")
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
        NSLog("\(self) \(#function)")
        completeTransition()
        updateSelectedViewController()
    }

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        NSLog("\(self) \(#function)")
        guard let controllerId = object as? DashboardControllers else {
            fatalError("Unexpected object \(object)")
        }
        return controllerId.rawValue
    }

    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        NSLog("\(self) \(#function) \(identifier)")

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
