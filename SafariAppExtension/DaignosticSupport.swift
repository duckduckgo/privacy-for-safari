//
//  DaignosticSupport.swift
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

class DiagnosticSupport {
    
    static let reportFileUrl = BlockerListLocation.containerUrl.appendingPathComponent("report").appendingPathExtension("csv")
    static let domainsListFileUrl = BlockerListLocation.containerUrl.appendingPathComponent("top-sites").appendingPathExtension("json")

    public static func dump(_ trackers: [DetectedTracker], blocked: Bool) {
        #if DEBUG
        DispatchQueue.global(qos: .background).async {
            
            NSLog(#function)
            let action = blocked ? "block" : "ignore"
            let report = trackers.map { "\"\($0.resource.absoluteString.replacingOccurrences(of: ",", with: "\\,"))\","
                + "\"\($0.page.absoluteString.replacingOccurrences(of: ",", with: "\\,"))\","
                + "\(action)" }
            
            guard let data = (report.joined(separator: "\n") + "\n").data(using: .utf8) else {
                NSLog("\(#function) failed to create report data")
                return
            }
            
            if !FileManager.default.fileExists(atPath: reportFileUrl.path) {
                NSLog("\(#function) creating file at \(reportFileUrl.path)")
                FileManager.default.createFile(atPath: reportFileUrl.path, contents: data, attributes: nil)
            } else {
                NSLog("\(#function) appending file at \(reportFileUrl.path)")
                guard let handle = try? FileHandle(forUpdating: reportFileUrl) else {
                    NSLog("\(#function) failed to open file handle \(reportFileUrl.absoluteString)")
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
                NSLog("\(#function) failed to create url from \(next)")
                return
            }
            
            NSLog("\(#function) opening \(url.absoluteString)")
            SFSafariApplication.openWindow(with: url) { window in
                NSLog("\(#function) window open \(url.absoluteString)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    NSLog("\(#function) window closing \(url.absoluteString)")
                    window?.close()
                    nextBlockingTest()
                }
            }
        }
    }
    
    private static func nextUrl() -> String? {
        NSLog("\(#function) IN")
        
        guard let data = try? Data(contentsOf: domainsListFileUrl) else {
            NSLog("\(#function) Could not read domains list")
            return nil
        }
                
        guard var urls = try? JSONDecoder().decode([String].self, from: data) else {
            NSLog("\(#function) Failed to decode url content")
            return nil
        }
        
        guard !urls.isEmpty else {
            NSLog("\(#function) No more urls")
            return nil
        }
        
        let nextUrl = urls.remove(at: 0)
        do {
            try JSONEncoder().encode(urls).write(to: domainsListFileUrl)
        } catch {
            NSLog("\(#function) failed to write urls back \(error.localizedDescription)")
        }
        
        NSLog("\(#function) OUT, \(nextUrl)")
        return nextUrl
    }
    
}
