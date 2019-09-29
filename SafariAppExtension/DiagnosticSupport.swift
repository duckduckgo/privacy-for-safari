//
//  DiagnosticSupport.swift
//  SafariAppExtension
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

import Foundation
import TrackerBlocking
import SafariServices
import os

class DiagnosticSupport {
    
    private static let logger = OSLog(subsystem: BundleIds.app, category: "Diagnostics")
    
    private static let reportFileUrl = BlockerListLocation.containerUrl.appendingPathComponent("report").appendingPathExtension("csv")
    private static let domainsListFileUrl = BlockerListLocation.containerUrl.appendingPathComponent("top-sites").appendingPathExtension("json")

    public static func dump(_ trackers: [DetectedTracker], blocked: Bool) {
        #if DEBUG
        DispatchQueue.global(qos: .background).async {
            
            let action = blocked ? "block" : "ignore"
            let report = trackers.map { "\"\($0.resource.absoluteString.replacingOccurrences(of: ",", with: "\\,"))\","
                + "\"\($0.page.absoluteString.replacingOccurrences(of: ",", with: "\\,"))\","
                + "\(action)" }
            
            guard let data = (report.joined(separator: "\n") + "\n").data(using: .utf8) else { return }
            
            if !FileManager.default.fileExists(atPath: reportFileUrl.path) {
                FileManager.default.createFile(atPath: reportFileUrl.path, contents: data, attributes: nil)
            } else {
                guard let handle = try? FileHandle(forUpdating: reportFileUrl) else {
                    os_log("Unable to open FileHandle %{public}%s", log: logger, type: .default, reportFileUrl.absoluteString)
                    return
                }
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        }
        #endif
    }
        
    /// When running this test, you have to manually move the domains list to the location at domainsListFileUrl
    public static func executeBlockingTest() {
        try? FileManager.default.removeItem(at: reportFileUrl)
        nextBlockingTest()
    }

    private static func nextBlockingTest() {
        DispatchQueue.global(qos: .background).async {
            guard let next = nextUrl() else { return }
            guard let url = URL(string: next) else {
                os_log("Next URL is invalid: %{public}s", log: logger, type: .default, next)
                return
            }
            
            SFSafariApplication.openWindow(with: url) { window in
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    window?.close()
                    nextBlockingTest()
                }
            }
        }
    }
    
    private static func nextUrl() -> String? {
        
        guard let data = try? Data(contentsOf: domainsListFileUrl) else {
            os_log("Failed to read %{public}s", log: logger, type: .error, domainsListFileUrl.absoluteString)
            return nil
        }
                
        guard var urls = try? JSONDecoder().decode([String].self, from: data) else {
            os_log("Failed to decode %{public}s", log: logger, type: .error, domainsListFileUrl.absoluteString)
            return nil
        }
        
        guard !urls.isEmpty else {
            // No urls found, we're finished
            return nil
        }
        
        let nextUrl = urls.remove(at: 0)
        do {
            try JSONEncoder().encode(urls).write(to: domainsListFileUrl)
        } catch {
            os_log("Failed to re-encode %{public}s", log: logger, type: .error, domainsListFileUrl.absoluteString)
        }
        
        return nextUrl
    }
    
}
