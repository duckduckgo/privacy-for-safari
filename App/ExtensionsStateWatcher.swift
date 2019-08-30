//
//  ExtensionsManager.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Chris Brind on 01/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
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
    
    private let contentBlockerExtensionId = (Bundle.main.bundleIdentifier ?? "") + ".ContentBlockerExtension"
    private let safariAppExtensionId = (Bundle.main.bundleIdentifier ?? "") + ".SafariAppExtension"
    
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
