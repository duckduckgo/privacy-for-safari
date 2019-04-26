//
//  SettingsViewController.swift
//  DuckDuckGo
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

import Cocoa

class SettingsViewController: NSViewController {

    @IBOutlet weak var trustedSitesOutline: NSOutlineView!
    @IBOutlet weak var removeTrustedSiteButton: NSButton!
    
    let trustedSites = TrustedSitesManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        observeTrustedSiteChanges()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        refreshTrustedSites()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? DomainPromptViewController {
            controller.delegate = self
        }
    }
    
    @IBAction func removeTrustedSite(sender: Any) {
        trustedSites.removeSite(at: trustedSitesOutline.selectedRow)
    }
    
    @objc func refreshTrustedSites() {
        trustedSites.readFromUserDefaults()
        trustedSitesOutline.reloadData()
    }
    
    private func observeTrustedSiteChanges() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(refreshTrustedSites),
                                                            name: TrustedSitesManager.updatedNotificationName,
                                                            object: nil)
    }
    
}

extension SettingsViewController: DomainPromptDelegate {
    
    func addDomain(_ domain: String) {
        trustedSites.addDomain(domain)
    }
    
}

extension SettingsViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? trustedSites.count : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return trustedSites.allDomains()[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item
    }
        
}

extension SettingsViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self)
            as? NSTableCellView else { return nil }
        view.textField?.stringValue = item as? String ?? ""
        return view
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        removeTrustedSiteButton.isEnabled = trustedSitesOutline.selectedRow >= 0
    }
    
}
