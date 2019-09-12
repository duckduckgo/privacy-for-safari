//
//  ReportBrokenSiteController.swift
//  SafariAppExtension
//
//  Created by Chris Brind on 30/08/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import AppKit

class ReportBrokenSiteController: DashboardNavigationController {
    
    @IBOutlet weak var runTestsView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
        runTestsView.isHidden = false
        #endif
        
    }
    
    @IBAction func startTests(sender: Any?) {
        DiagnosticSupport.executeBlockingTest()
    }
    
}
