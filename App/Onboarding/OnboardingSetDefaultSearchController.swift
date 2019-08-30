//
//  OnboardingSetDefaultSearchController.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Christopher Brind on 17/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class OnboardingSetDefaultSearchController: OnboardingScreen {

    var watcher: ExtensionsStateWatcher? = ExtensionsStateWatcher()

    @IBAction func buttonPressed(sender: Any) {

        if watcher != nil {
            watcher?.showSafariExtensionPreferences()
            watcher = nil
            button.title = "Finish Setup"
        } else {
            delegate?.finish()
        }

    }

}
