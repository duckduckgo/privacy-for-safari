//
//  OnboardingPageController.swift
//  DuckDuckGo Privacy Essentials
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
import SafariServices

protocol OnboardingFinishedDelegate: NSObjectProtocol {
    
    func finished(onboardingVC: OnboardingPageController)
    
}

protocol OnboardingScreenDelegate: NSObjectProtocol {
    func navigateForward(_ sender: Any?)
    func finish()
}

class OnboardingPageController: NSPageController {
    
    @IBOutlet weak var page1: CircleIndicatorView!
    @IBOutlet weak var page2: CircleIndicatorView!
    @IBOutlet weak var page3: CircleIndicatorView!
    
    weak var finishedDelegate: OnboardingFinishedDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        transitionStyle = .horizontalStrip
        arrangedObjects = [ "GetStarted", "EnableExtensions", "SetDefaultSearch" ]
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
        
}

extension OnboardingPageController: NSPageControllerDelegate {
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        completeTransition()
        
        [page1, page2, page3].enumerated().forEach { index, view in
            view?.active = index == selectedIndex
        }
        
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let id = object as? String else { fatalError("Unexpected object \(object)") }
        return id
    }
    
    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        
        NSLog("\(self) \(#function)")
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? OnboardingScreen else {
            fatalError("Failed to load \(identifier) controller")
        }
        controller.delegate = self
        
        return controller
    }
        
}

extension OnboardingPageController: OnboardingScreenDelegate {
 
    func finish() {
        finishedDelegate?.finished(onboardingVC: self)
    }
    
}
