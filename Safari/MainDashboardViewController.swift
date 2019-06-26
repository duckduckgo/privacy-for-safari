//
//  MainDashboardViewController.swift
//  Safari App Extension
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

import Cocoa
import SafariServices
import TrackerBlocking

class MainDashboardViewController: NSViewController {
 
    weak var navigationDelegate: DashboardNavigationDelegate?

    let trustedSites: TrustedSitesManager = Dependencies.shared.trustedSitesManager

    @IBOutlet weak var trustedSitesLabel: NSTextField!
    @IBOutlet weak var urlLabel: NSTextField!
    @IBOutlet weak var entities: NSTextView!

    var pageData: PageData! {
        didSet {
            updateUI()
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        trustedSites.load()
        updateTrustedSitesLabel()
    }
    
    @IBAction func clearTrustedSites(sender: Any) {
        trustedSites.clear()
        updateTrustedSitesLabel()
    }
    
    @IBAction func next(sender: Any) {
        navigationDelegate?.push(controller: .privacyScoreCard)
    }

    private func updateTrustedSitesLabel() {
        trustedSitesLabel.stringValue = "\(trustedSites.count) trusted sites"
    }

    private func updateUI() {
        
        class R {
            
            var entities = [String: [String]]()
            
        }
        
        func reduce(result: R, tracker: DetectedTracker) -> R {
            let entityName = tracker.owner ?? "<unknown>"
            var resources = result.entities[entityName, default: [String]()]
            resources.append(tracker.resource.absoluteString)
            result.entities[entityName] = resources
            return result
        }
        
        func entitiesMapper(tracker: DetectedTracker) -> String? {
            return tracker.owner
        }
        
        urlLabel.stringValue = pageData.url?.host ?? "No URL"
        entities.string = "Enhanced from " + String(describing: pageData.calculateGrade().site.grade.rawValue)
            + " to " + String(describing: pageData.calculateGrade().enhanced.grade.rawValue)
            + "\n\nNOT BLOCKED: "
            + String(describing: pageData.loadedTrackers.reduce(R(), reduce).entities)
            + "\n\nBLOCKED: "
            + String(describing: pageData.blockedTrackers.reduce(R(), reduce).entities)
    }

}
