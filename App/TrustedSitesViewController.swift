//
//  TrustedSitesViewController.swift
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
import TrackerBlocking

class TrustedSitesViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var noSitesView: NSView!

    let trustedSites = Dependencies.shared.trustedSitesManager
    let blockerListManager = Dependencies.shared.blockerListManager

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(onTrustedSitesChanged),
                                                            name: TrustedSitesNotification.sitesUpdatedNotificationName,
                                                            object: nil)
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        onTrustedSitesChanged()
    }
    
    @objc private func onTrustedSitesChanged() {
        tableView.reloadData()
        tableView.isHidden = trustedSites.count == 0
        noSitesView.isHidden = trustedSites.count != 0
    }
    
}

extension TrustedSitesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            
        if row == 0 {
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Header"), owner: nil)
        } else {
            guard let entry = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Entry"), owner: nil) as? WhitelistEntryView else {
                fatalError("Failed to make 'Entry' view")
            }
            entry.textField?.stringValue = trustedSites.allDomains()[row - 1]
            entry.isAlternate = 0 == (row % 2)
            entry.onDelete = {
                self.trustedSites.removeDomain(at: row - 1)
                self.blockerListManager.setNeedsReload(true)
                self.tableView.reloadData()
            }
            return entry
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return row == 0 ? 100 : 50
    }
    
}

extension TrustedSitesViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return trustedSites.count + 1
    }

}

class WhitelistEntryView: NSTableCellView {
 
    typealias OnDelete = () -> Void
    
    @IBOutlet weak var box: NSBox!
    
    var onDelete: OnDelete?
    
    var isAlternate: Bool = false {
        didSet {
            updateBackground()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateBackground()
    }
    
    func updateBackground() {
        box.fillColor = isAlternate ? NSColor.tableAlt1 : NSColor.tableAlt2
    }
    
    @IBAction func deletePressed(sender: Any?) {
        self.onDelete?()
    }
    
}
