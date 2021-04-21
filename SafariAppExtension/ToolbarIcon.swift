//
//  ToolbarIcon.swift
//  SafariAppExtension
//
//  Created by Tomas Strba on 21/04/2021.
//  Copyright © 2021 Duck Duck Go, Inc. All rights reserved.
//

import Cocoa

class ToolbarIcon {

    private static let lightIcon = NSImage(named: "ToolbarIconLight")
    private static let darkIcon = NSImage(named: "ToolbarIconDark")

    public static var currentIcon: NSImage? {
        NSApplication.shared.effectiveAppearance.isDarkMode ? Self.darkIcon : Self.lightIcon
    }

}

fileprivate extension NSAppearance {

    var isDarkMode: Bool {
        debugDescription.lowercased().contains("dark")
    }

}
