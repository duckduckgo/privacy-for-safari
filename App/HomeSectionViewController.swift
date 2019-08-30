//
//  HomeSectionViewController.swift
//  DuckDuckGo
//
//  Created by Chris Brind on 20/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit
import SafariServices

class HomeSectionViewController: NSViewController {
    
    @IBOutlet weak var enabledStateView: NSView!
    @IBOutlet weak var disabledStateView: NSView!
    @IBOutlet weak var unknownStateView: NSView!
    
    var extensionsState: ExtensionsStateWatcher?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extensionsState = ExtensionsStateWatcher(delegate: self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        extensionsState?.refresh()
        refreshUI()
    }
    
    private func refreshUI() {
        
        guard let state = extensionsState else { return }
    
        unknownStateView.isHidden = state.allKnown
        enabledStateView.isHidden = !state.allKnown || !state.allEnabled
        disabledStateView.isHidden = !state.allKnown || state.allEnabled
        
    }
    
}

extension HomeSectionViewController: ExtensionsStateWatcher.Delegate {
    
    func stateUpdated(watcher: ExtensionsStateWatcher) {
        DispatchQueue.main.async {
            self.refreshUI()
        }
    }
    
}
