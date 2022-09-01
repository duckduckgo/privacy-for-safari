//
//  script.js
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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

(function() {

    // MARK: Listeners and Observers

    const observer = new PerformanceObserver((list, observer) => {
        let resources = list.getEntries().map((entry) => { return { url: entry.name, type: entry.initiatorType } })
        safari.extension.dispatchMessage("resourceLoaded", {
            "resources": resources
        });

    });
    observer.observe({entryTypes: ["resource"]});

    safari.self.addEventListener("message", function(event) {
        if (event.name === "stopCheckingResources") {
            observer.disconnect();
        }
    });

    // Only do these in the top level window
    if (!isBeingFramed()) {

        safari.extension.dispatchMessage("userAgent", {
            "userAgent": navigator.userAgent
        });

        window.addEventListener("beforeunload", function(event) {
           safari.extension.dispatchMessage("beforeUnload");
        });

        window.addEventListener('DOMContentLoaded', function() {
            safari.extension.dispatchMessage("DOMContentLoaded");
        }, true);
    }

    // From: https://github.com/duckduckgo/content-scope-scripts/blob/main/src/utils.js#L59-L65
    function isBeingFramed () {
        if ('ancestorOrigins' in globalThis.location) {
            return globalThis.location.ancestorOrigins.length > 0
        }
        return globalThis.top !== globalThis
    }

}) ();
