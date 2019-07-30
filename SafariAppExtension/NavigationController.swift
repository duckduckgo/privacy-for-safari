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

    func push(controller: DashboardControllers) {
        NSLog("\(self) \(#function)")
        arrangedObjects.append(controller)
        navigateForward(self)
        DispatchQueue.main.async {
            self.updateSelectedViewController()
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
        NSLog("\(self) \(#function)")
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? DashboardNavigationController else {
            fatalError("instantiateController DashboardNavigationController failed")
        }
        controller.pageData = pageData
        controller.navigationDelegate = self
        return controller
    }

}
