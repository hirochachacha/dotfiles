#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Browser
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# set app1 to "Dia"
# set app2 to "Brave Browser"

# tell application "System Events"
# 	set frontApp to name of first application process whose frontmost is true
# end tell
# 
# if frontApp is app1 then
# 	tell application app2 to activate
# 	tell application "System Events" to set visible of process app1 to false
# else if frontApp is app2 then
# 	tell application "System Events" to set visible of process app2 to false
# else
#   tell application app1 to activate
# end if

set appName to "Zen"
set bundleID to "app.zen-browser.zen"

tell application "System Events"
	set isRunning to (exists (processes where bundle identifier is bundleID))
end tell

if isRunning then
	tell application "System Events"
		set isFrontmost to (frontmost of process appName)
	end tell

	if isFrontmost then
		tell application "System Events" to set visible of process appName to false
	else
		tell application id bundleID to activate
	end if
else
	tell application id bundleID to activate
end if
