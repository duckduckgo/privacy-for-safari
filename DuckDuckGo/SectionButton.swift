//
//  SectionButton.swift
//  DuckDuckGo
//
//  Created by Chris Brind on 20/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class SectionButton: NSBox {
    
    @IBOutlet var label: NSTextField!
    @IBOutlet var emphasis: NSBox!

    func deselected() {
        fillColor = NSColor.clear
        label.textColor = nil
        emphasis.isHidden = true
    }
    
    func selected() {
        emphasis.isHidden = false

        fillColor = NSColor(named: NSColor.Name("SelectedBackground"))!
        if #available(OSX 10.14, *) {
            label.textColor = NSColor.controlAccentColor
        } else {
            label.textColor = NSColor(named: NSColor.Name("SelectedText"))
        }
        
    }
     
}
