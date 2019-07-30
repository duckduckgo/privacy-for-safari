//
//  ClickableTextField.swift
//  SafariAppExtension
//
//  Created by Christopher Brind on 27/06/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

protocol Clickable: NSView {

    func addPointingHandCursor()

}

extension Clickable {

    func addPointingHandCursor() {
        addCursorRect(self.bounds, cursor: .pointingHand)
    }

}

class ClickableView: NSView, Clickable {
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }
    
}

class ClickableTextField: NSTextField, Clickable {

    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }

}

class ClickableBox: NSBox, Clickable {

    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }

}

class ClickableStackView: NSStackView, Clickable {

    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }

}

class ClickableButton: NSButton, Clickable {
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }
    
}
