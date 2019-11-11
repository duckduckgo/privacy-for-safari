killall cfprefsd

launchctl remove com.duckduckgo.macos.PrivacyEssentials.DuckDuckGoSync
launchctl remove group.com.duckduckgo.macos.PrivacyEssentials.DuckDuckGoHelper

rm -rf ~/Library/Containers/*.com.duckduckgo*
rm -rf ~/Library/Application\ Scripts/group.com.duckduckgo*
rm -rf ~/Library/Containers/com.duckduckgo*
rm -rf ~/Library/Group\ Containers/group.com.duckduckgo*
rm -rf ~/Library/Application\ Scripts/com.duckduckgo*
rm -rf ~/Library/Developer/Xcode/DerivedData/DuckDuckGo*
rm -rf ~/Library/Caches/com.duckduckgo.macos.PrivacyEssentials

rm -rf /Applications/DuckDuckGo*

