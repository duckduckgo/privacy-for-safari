//
//  OnboardingScreen.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Christopher Brind on 17/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class OnboardingScreen: NSViewController {

    @IBOutlet weak var button: NSButton!

    weak var delegate: OnboardingScreenDelegate?

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.defaultButtonCell = button.cell as? NSButtonCell
    }

}
