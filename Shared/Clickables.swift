//
//  ClickableTextField.swift
//  SafariAppExtension
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

class ClickableImage: NSImageView, Clickable {

    override func resetCursorRects() {
        super.resetCursorRects()
        addPointingHandCursor()
    }

}
