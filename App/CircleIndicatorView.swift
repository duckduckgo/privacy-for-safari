//
//  CircleIndicatorView.swift
//  DuckDuckGo Privacy for Safari
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
