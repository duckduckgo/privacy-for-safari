//
//  KnownTracker.swift
//  TrackersBuilder
//
//  Created by Christopher Brind on 05/05/2019.
//  Copyright © 2019 Duck Duck Go, Inc. All rights reserved.
//

import Foundation

extension KnownTracker {

    static func load(fromUrl url: URL?) -> KnownTracker? {
        guard let url = url,
            let data = try? Data(contentsOf: url) else {
                return nil
        }

        return try? decoder.decode(KnownTracker.self, from: data)
    }

}
