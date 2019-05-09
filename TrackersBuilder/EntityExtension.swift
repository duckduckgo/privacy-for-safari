//
//  EntityExtension.swift
//  TrackersBuilder
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

extension Entity {
    
    static func load(entityNamed: String, fromDirectory dir: URL) -> Entity? {
        let fileName = entityNamed.replacingOccurrences(of: "/", with: "").replacingOccurrences(of: "!", with: "")
        let file = dir.appendingPathComponent(fileName).appendingPathExtension("json")
        
        guard let data = try? Data(contentsOf: file) else {
            print("Failed to read file", file)
            return nil
        }
        
        do {
            return try JSONDecoder().decode(Entity.self, from: data)
        } catch {
            print("Failed to decode", fileName, error)
        }
        return nil
    }
    
}
