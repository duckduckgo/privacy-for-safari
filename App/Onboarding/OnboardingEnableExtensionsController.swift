//
//  OnboardingEnableExtensionsController.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Christopher Brind on 17/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class OnboardingEnableExtensionsController: OnboardingScreen, ExtensionsStateWatcher.Delegate {

    var watcher: ExtensionsStateWatcher?
    var detectionTimer: Timer?

    override func viewDidAppear() {
        super.viewDidAppear()
        watcher = ExtensionsStateWatcher(delegate: self)
    }

    @IBAction func buttonPressed(sender: Any) {

        guard let watcher = watcher else { return }

        if watcher.protectionState != .enabled {
            watcher.showContentBlockerExtensionPreferences()
        } else if watcher.dashboardState != .enabled {
            watcher.showSafariExtensionPreferences()
        }
    }

    func stateUpdated(watcher: ExtensionsStateWatcher) {
        print(#function, watcher.allEnabled)
        if watcher.allEnabled {
            killTimer()
            nextScreen()
        } else {
            startTimer()
        }
    }

    func startTimer() {
        print(#function)
        killTimer()

        DispatchQueue.main.async {
            self.detectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                print("timer fired")
                self.watcher?.refresh()
            })
        }
    }

    func killTimer() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }

    func nextScreen() {
        print(#function)
        DispatchQueue.main.async {
            self.view.window?.orderFrontRegardless()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.delegate?.navigateForward(self)
            }
        }
    }

}
