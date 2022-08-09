killall cfprefsd

launchctl remove com.duckduckgo.macos.PrivacyEssentials.DuckDuckGoSync
launchctl remove group.com.duckduckgo.macos.PrivacyEssentials.DuckDuckGoHelper

rm -rf ~/Library/Containers/*.com.duckduckgo*Privacy*
rm -rf ~/Library/Application\ Scripts/group.com.duckduckgo*Privacy*
rm -rf ~/Library/Containers/com.duckduckgo*Privacy*
rm -rf ~/Library/Group\ Containers/group.com.duckduckgo*Privacy*
rm -rf ~/Library/Application\ Scripts/com.duckduckgo*Privacy*
rm -rf ~/Library/Developer/Xcode/DerivedData/DuckDuckGo*Privacy*
rm -rf ~/Library/Caches/com.duckduckgo.macos.PrivacyEssentials

rm -rf /Applications/DuckDuckGo*Privacy*

