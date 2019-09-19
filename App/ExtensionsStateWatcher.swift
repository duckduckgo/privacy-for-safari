//
//  ExtensionsManager.swift
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

import Foundation
import SafariServices

protocol ExtensionsStateWatcherDelegate: NSObjectProtocol {
    
    func stateUpdated(watcher: ExtensionsStateWatcher)
    
}

class ExtensionsStateWatcher {

    typealias Delegate = ExtensionsStateWatcherDelegate
    
    enum State {
        case unknown, enabled, disabled
    }
    
    private let contentBlockerExtensionId = BundleIds.contentBlockerExtension
    private let safariAppExtensionId = BundleIds.safariAppExtension
    
    private(set) var protectionState = State.unknown
    private(set) var dashboardState = State.unknown
    
    var allEnabled: Bool {
        return protectionState == .enabled && dashboardState == .enabled
    }

    var allKnown: Bool {
        return protectionState != .unknown && dashboardState != .unknown
    }

    weak var delegate: Delegate?
    
    init(delegate: Delegate? = nil) {
        self.delegate = delegate
        refresh()
    }
    
    func refresh() {
        refreshContentBlockerExtensionState()
        refreshSafariExtensionState()
    }
    
    func showContentBlockerExtensionPreferences() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: contentBlockerExtensionId)
    }
    
    func showSafariExtensionPreferences() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: safariAppExtensionId)
    }

    private func refreshContentBlockerExtensionState() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: contentBlockerExtensionId) { state, _ in
            self.protectionState = (state?.isEnabled ?? false) ? .enabled : .disabled
            self.delegate?.stateUpdated(watcher: self)
        }
    }
    
    private func refreshSafariExtensionState() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: safariAppExtensionId) { state, _ in
            self.dashboardState = (state?.isEnabled ?? false) ? .enabled : .disabled
            self.delegate?.stateUpdated(watcher: self)
        }
    }
}
