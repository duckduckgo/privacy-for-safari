//
//  script.js
//  DuckDuckGo
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
//  distributed under the dwdLicense is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// MARK: Detection Methods
(function() {

    safari.extension.dispatchMessage("userAgent", {
        "userAgent": navigator.userAgent
    });

    var maxPerformanceTimeout = 3000;
    var performanceTimeoutIncrement = 200;
    var performanceTimeout = 100;
    var performanceIndex = 0; 

    function reportLoadedResources() {

        let entries = performance.getEntriesByType("resource");

        if (entries.length > performanceIndex) {
             var resources = [];

            for (var i = performanceIndex; i < entries.length; i++) {
                var entry = entries[i];
                resources.push({ url: entry.name, type: entry.initiatorType });
            }

            safari.extension.dispatchMessage("resourceLoaded", {
                    "resources": resources
                });

            performanceIndex = entries.length;
        }

        // backoff from calling it so often - all the interesting stuff is in the first few seconds
        performanceTimeout = Math.min(performanceTimeout + performanceTimeoutIncrement, maxPerformanceTimeout)
        setTimeout(reportLoadedResources, performanceTimeout);
    }

    setTimeout(reportLoadedResources, performanceTimeout);

}) ();
