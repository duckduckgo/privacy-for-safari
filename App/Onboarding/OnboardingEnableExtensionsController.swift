//
//  OnboardingEnableExtensionsController.swift
//  DuckDuckGo Privacy Essentials
//
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
import Statistics

class OnboardingEnableExtensionsController: OnboardingScreen, ExtensionsStateWatcher.Delegate {

    var watcher: ExtensionsStateWatcher?
    var detectionTimer: Timer?

    private let pixel = Dependencies.shared.pixel
    private let slideShownPixel = FireOncePixel(pixel: Dependencies.shared.pixel, pixelName: .onboardingEnableExtensionsShown)
    
    override func viewDidAppear() {
        super.viewDidAppear()
        watcher = ExtensionsStateWatcher(delegate: self)
        slideShownPixel.fire()
    }

    @IBAction func buttonPressed(sender: Any) {
        
        pixel.fire(PixelName.onboardingEnableExtensionshSafariPressed)
        
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
