//
//  main.swift
//  TrackerDetectionValidator
//
//  Created by Chris Brind on 10/09/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation
import TrackerBlocking

// NOTE: Run the main app before running this to make sure latest tracker data is in the correct place for reading.

let dataUrl = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Downloads")
    .appendingPathComponent("data")
    .appendingPathExtension("csv")

let badCsv = FileManager.default.homeDirectoryForCurrentUser
.appendingPathComponent("Downloads")
.appendingPathComponent("bad")
.appendingPathExtension("csv")

print("Loading data from", dataUrl.path)
print("Writing not found trackers to", badCsv.path)

FileManager.default.createFile(atPath: badCsv.path, contents: nil, attributes: nil)
guard let badCsvHandle = try? FileHandle(forWritingTo: badCsv) else {
    print("Unable to write to", badCsv.path)
    exit(1)
}

guard let lineReader = LineReader(path: dataUrl.path) else { exit(1) }

// write the headers to the not found csv
let headers = lineReader.nextLine!
badCsvHandle.write(headers.data(using: .utf8)!)
defer {
    badCsvHandle.closeFile()
}

var trackersNotFound = 0
var badResourceUrls = 0
var notBlocked = 0
var notIgnored = 0
var pass = 0
var badAction = 0

let start = Date()

let detection = Dependencies.shared.trackerDetection

func validate(line: String) {
    let json = "[\(line)]".data(using: .utf8)!
    guard let parts = try? JSONDecoder().decode([String].self, from: json) else {
        badResourceUrls += 1
        return
    }
        
    guard let resourceUrl = URL(string: parts[0].replacingOccurrences(of: "}", with: "%7B").replacingOccurrences(of: "{", with: "%7D")) else {
        badCsvHandle.write(line.data(using: .utf8)!)
        badResourceUrls += 1
        return
    }
    
    let pageUrl = URL(string: parts[1])!
    let type = parts[2]
    let action = parts[3]
    
    guard let result = detection.detectTrackerFor(resourceUrl: resourceUrl, onPageWithUrl: pageUrl, asResourceType: type) else {
        // badCsvHandle.write(line.data(using: .utf8)!)
        trackersNotFound += 1
        return
    }
    
    switch action {
        
    case "block":
        if result.action != .block {
            notBlocked += 1
            // badCsvHandle.write(line.data(using: .utf8)!)
            return
        }
        pass += 1

    case "ignore":
        if result.action != .ignore {
            notIgnored += 1
            // badCsvHandle.write(line.data(using: .utf8)!)
            return
        }
        pass += 1
        
    default:
        badAction += 1
        
    }

}

// tracker, site, type, action
for line in lineReader {
    validate(line: line)
}

print("bad resource urls", badResourceUrls)
print("trackers not found", trackersNotFound)
print("incorrectly ignored", notBlocked)
print("incorrectly blocked", notIgnored)
print("pass", pass)
print("Finished in", abs(start.timeIntervalSinceNow), "seconds")

