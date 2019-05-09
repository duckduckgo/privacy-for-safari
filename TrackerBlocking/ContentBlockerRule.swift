//
//  ContentBlocker.swift
//  TrackerBlocking
//
//  Created by Christopher Brind on 05/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

public struct ContentBlockerRule: Codable {

    public enum ResourceType: String {
        
        case document
        case image
        case styleSheet = "style-sheet"
        case script
        case font
        case raw
        case svg = "svg-document"
        case media
        case popup
        
    }
    
    public struct Trigger: Codable {

        let urlFilter: String
        let unlessDomain: [String]?
        let ifDomain: [String]?
        let resourceType: [String]?

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case urlFilter = "url-filter"
            case unlessDomain = "unless-domain"
            case ifDomain = "if-domain"
            case resourceType = "resource-type"
        }
        // swiftlint:enable nesting
        
        static func trigger(urlFilter filter: String, unlessDomain domains: [String]) -> Trigger {
            return Trigger(urlFilter: filter, unlessDomain: domains, ifDomain: nil, resourceType: nil)
        }

        static func trigger(urlFilter filter: String, ifDomain domains: [String]) -> Trigger {
            return Trigger(urlFilter: filter, unlessDomain: nil, ifDomain: domains, resourceType: nil)
        }
        
        static func trigger(urlFilter filter: String, resourceType types: [ResourceType]) -> Trigger {
            return Trigger(urlFilter: filter, unlessDomain: nil, ifDomain: nil, resourceType: types.map { $0.rawValue })
        }

    }

    public struct Action: Codable {

        let type: String
        
        static func block() -> Action {
            return Action(type: "block")
        }
        
        static func ignorePreviousRules() -> Action {
            return Action(type: "ignore-previous-rules")
        }
        
    }

    let trigger: Trigger
    let action: Action

}
