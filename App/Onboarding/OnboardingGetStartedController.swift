//
//  OnboardingGetStartedController.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Christopher Brind on 17/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class OnboardingGetStartedController: OnboardingScreen {

    @IBAction func getStarted(sender: Any) {
        delegate?.navigateForward(self)
    }

}
