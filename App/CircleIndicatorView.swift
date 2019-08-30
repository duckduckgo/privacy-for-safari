//
//  CircleIndicatorView.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Chris Brind on 01/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

@IBDesignable
class CircleIndicatorView: NSView {
    
    @IBInspectable
    var tint: NSColor?
    
    @IBInspectable
    var active: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 10, height: 10)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        
        let color = tint ?? NSColor.controlAccentColor
        
        if active {
            
            context.scaleBy(x: bounds.width / 10, y: bounds.height / 10)
            
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(3)
            context.strokeEllipse(in: NSRect(x: 1.5, y: 1.5, width: 7, height: 7))
        } else {
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: bounds)
        }
        context.restoreGState()
    }
    
}
