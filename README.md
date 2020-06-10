# DuckDuckGo Privacy Essentials for Safari

## Building
Requires Xcode 11 and macOS 10.15 or better.

Open the project in Xcode then build and run the DuckDuckGo scheme.

### SwiftLint
We use [SwifLint](https://github.com/realm/SwiftLint) for enforcing Swift style and conventions, so you'll need to [install it](https://github.com/realm/SwiftLint#installation).

### Fonts
We use Proxima Nova fonts which are proprietary and cannot be committed to source control, see [fonts](https://github.com/duckduckgo/privacy-essentials-safari/tree/develop/fonts/licensed). 

## Cleaning up

***CAUTION** - this is a destructive process.  Please be comfortable with the contents of `deleteApp.sh` before running it.*

To competely remove the app and any files it creates:

* Disable the extension in Safari's Extension Preferences pane. 
* Run the `./deleteApp.sh` script.

## Contribute
Please refer to [contributing](CONTRIBUTING.md).

## Discuss
Contact us at https://duckduckgo.com/feedback if you have feedback, questions or want to chat.  You can also use the feedback form embedded within the macOS app - to do so open the app and select "Send Feedback".

## License
DuckDuckGo Privacy Essentials for Safari is distributed under the Apache 2.0 [license](https://github.com/duckduckgo/privacy-essentials-safari/blob/master/LICENSE).
