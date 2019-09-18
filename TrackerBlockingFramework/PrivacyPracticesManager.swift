//
//  PrivacyPractices.swift
//  TrackerBlocking
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

public protocol PrivacyPracticesManager {

    func findPrivacyPractice(forUrl: URL) -> PrivacyPractice
    
}

public class DefaultPrivacyPracticesManager: PrivacyPracticesManager {
    
    struct Constants {
        static let unknown = PrivacyPractice(score: 2, summary: .unknown, goodReasons: [], badReasons: [])
    }

    let terms: [String: TermsOfService] = TermsOfService.load() ?? [:]
    let trackerDataManager: TrackerDataManager.Factory
    lazy var entityScores: [Entity: Int] = {
        // derive the worst score possible for an entity by looking at each site in the tosdr data
        var entityScores = [Entity: Int]()
        terms.forEach {
            let score = $1.derivedScore
            if let url = URL(string: "https://" + $0),
                let entity = trackerDataManager().entity(forUrl: url) {
                if entityScores[entity, default: score] <= score {
                    entityScores[entity] = score
                }
            }
        }
        return entityScores
    }()

    init(trackerDataManager: @escaping TrackerDataManager.Factory) {
        self.trackerDataManager = trackerDataManager
    }

    public func findPrivacyPractice(forUrl url: URL) -> PrivacyPractice {
        guard let domainTerms = termsForDomain(url) else { return Constants.unknown }
        let score = worstScore(forUrl: url, defaultScore: domainTerms.derivedScore)

        return PrivacyPractice(score: score,
                        summary: domainTerms.summary,
                        goodReasons: domainTerms.goodReasons,
                        badReasons: domainTerms.badReasons)
    }

    private func worstScore(forUrl url: URL, defaultScore: Int) -> Int {
        guard let entity = trackerDataManager().entity(forUrl: url),
            let entityScore = entityScores[entity] else { return defaultScore }
        return max(defaultScore, entityScore)
    }

    private func termsForDomain(_ url: URL) -> TermsOfService? {
        return (url.hostVariations ?? []).compactMap { terms[$0] }.first
    }

}
