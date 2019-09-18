//
//  TrustedSitesViewController.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Chris Brind on 16/09/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit
import TrackerBlocking

class TrustedSitesViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var noSitesView: NSView!

    let trustedSites = Dependencies.shared.trustedSitesManager

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(onTrustedSitesChanged),
                                                            name: TrustedSitesManagerUpdatedNotificationName,
                                                            object: nil)
        
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        onTrustedSitesChanged()
    }
    
    @objc private func onTrustedSitesChanged() {
        trustedSites.load()
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
        box.fillColor = NSColor(named: NSColor.Name(isAlternate ? "TableAlt1" : "TableAlt2")) ?? NSColor.clear
    }
    
    @IBAction func deletePressed(sender: Any?) {
        self.onDelete?()
    }
    
}
