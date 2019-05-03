//
//  SafariExtensionHandler.swift
//  Safari
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

import SafariServices
import TrackerBlocking

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    enum Messages: String {
        case resourceLoaded
        case entityData
    }

    struct Data {

        static var pageData = PageData()

    }

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        guard let message = Messages(rawValue: messageName) else {
            return
        }
        
        switch message {
        case .resourceLoaded:
            handleResourceLoadedMessage(userInfo, onPage: page)
        case .entityData:
            handleEntityData(userInfo, onPage: page)
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getToolbarItem { toolbarItem in
            toolbarItem?.showPopover()
        }
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")

        Data.pageData = PageData()

        window.getToolbarItem { toolbarItem in
            toolbarItem?.setImage(NSImage(named: NSImage.Name("LogoToolbarItemIcon")))
        }

        window.getActiveTab { tabs in
            tabs?.getActivePage(completionHandler: { page in
                page?.dispatchMessageToScript(withName: "getEntityData", userInfo: nil)
                page?.getPropertiesWithCompletionHandler({ properties in
                    Data.pageData = PageData(url: properties?.url)
                })
            })
        }

    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        SafariExtensionViewController.shared.pageData = Data.pageData
        SafariExtensionViewController.shared.viewWillAppear()
    }

    private func handleResourceLoadedMessage(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        guard let resource = userInfo?["resource"] as? String,
            let type = userInfo?["type"] as? String else {
            return
        }

        page.getPropertiesWithCompletionHandler { properties in
            guard let pageUrl = properties?.url,
                let tracker = Dependencies.shared.trackerDetection.detectTracker(forResource: resource, ofType: type, onPageWithUrl: pageUrl),
                !tracker.isFirstParty else {
                    return
            }

            let entity = tracker.owner ?? "Unknown"
            page.dispatchMessageToScript(withName: "entityNotBlocked", userInfo: [
                "entity": entity as Any,
                "resource": resource as Any
                ])

            Data.pageData = Data.pageData.updateEntities(blocked: [:], notBlocked: [entity: [resource: 1]])
            self.updateToolbar(forPage: page)
        }

    }

    private func handleEntityData(_ userInfo: [String: Any]?, onPage page: SFSafariPage) {
        guard let entitiesBlocked = userInfo?["entitiesBlocked"] as? PageData.Entities else { return }
        guard let entitiesNotBlocked = userInfo?["entitiesNotBlocked"] as? PageData.Entities else { return }

        if !entitiesBlocked.isEmpty || !entitiesNotBlocked.isEmpty {
            Data.pageData = Data.pageData.updateEntities(blocked: entitiesBlocked, notBlocked: entitiesNotBlocked)
        }

        updateToolbar(forPage: page)
    }

    private func updateToolbar(forPage page: SFSafariPage) {
        page.getContainingTab { tab in
            tab.getContainingWindow(completionHandler: { window in
                window?.getToolbarItem { toolbarItem in
                    let count = Data.pageData.notBlockedTrackerCount
                    toolbarItem?.setBadgeText(count > 0 ? "\(count)" : nil)

                    let grade = Data.pageData.calculateGrade().site.grade
                    toolbarItem?.setImage(NSImage(forGrade: grade))
                }
            })
        }
    }
    
}

extension NSImage {
    
    convenience init?(forGrade grade: Grade.Grading) {
        switch grade {
        case .a: self.init(named: "ToolbarGradeA")
        case .bPlus: self.init(named: "ToolbarGradeBPlus")
        case .b: self.init(named: "ToolbarGradeB")
        case .cPlus: self.init(named: "ToolbarGradeCPlus")
        case .c: self.init(named: "ToolbarGradeC")
        case .d: self.init(named: "ToolbarGradeD")
        case .dMinus: self.init(named: "ToolbarGradeD")
        }
    }
    
}
