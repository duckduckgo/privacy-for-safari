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

    var resources = [];
    var timeout;

    function debounce(func, time) {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            func()
        }, time);
    }

	function resourceLoaded(resource, type) {
        resources.push(resource);

        debounce(function() {
            console.log(`DDG: checking ${resources.length} resources for trackers`);
            safari.extension.dispatchMessage("resourceLoaded", {
                "resources": resources
            });
            resources = [];
        }, 250);
	}

    document.addEventListener("beforeload", function(event) {

		event.srcElement.onload = function() {
	        if (event.target.nodeName == "LINK") {
	            type = event.target.rel;
	        } else if (event.target.nodeName == "IMG") {
	            type = "image";
	        } else if (event.target.nodeName == "IFRAME") {
	            type = "subdocument";
	        } else {
	            type = event.target.nodeName;
	        }

	        resourceLoaded(event.url, type);
		}

    }, true)


    try {
        var originalImageSrc = Object.getOwnPropertyDescriptor(Image.prototype, 'src')
        delete Image.prototype.src;
        Object.defineProperty(Image.prototype, 'src', {
            get: function() {
                return originalImageSrc.get.call(this);
            },
            set: function(value) {
				resourceLoaded(value, "image");
                originalImageSrc.set.call(this, value);                
            }
        })

    } catch(error) {
        console.log("failed to install image src detection", error);
    }

    try {
        var xhr = XMLHttpRequest.prototype;
        var originalOpen = xhr.open;

        xhr.open = function() {
            var args = arguments;
            var url = arguments[1];
            resourceLoaded(url, "xmlhttprequest");
            return originalOpen.apply(this, args);
        }

    } catch(error) {
        console.log("failed to install xhr detection", error);
    }
 
}) ();
