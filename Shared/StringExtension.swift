//
//  StringExtension.swift
//  DuckDuckGo Privacy Essentials
//
//  Created by Chris Brind on 04/07/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

extension String {
    
    func dropPrefix(_ prefix: String) -> String {
        return hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
    
}
