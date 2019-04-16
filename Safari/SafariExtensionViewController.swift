//
//  SafariExtensionViewController.swift
//  Safari
//
//  Created by Chris Brind on 17/04/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 320, height: 240)
        return shared
    }()

}
