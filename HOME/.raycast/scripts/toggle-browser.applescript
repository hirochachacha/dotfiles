#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Browser
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# set appChrome to "Google Chrome"
# set appBrave to "Brave Browser"
set appChrome to "Brave Browser"
set appBrave to "Google Chrome"

tell application "System Events"
	set frontApp to name of first application process whose frontmost is true
end tell

if frontApp is appChrome then
	tell application appBrave to activate
	tell application "System Events" to set visible of process appChrome to false
else if frontApp is appBrave then
	tell application "System Events" to set visible of process appBrave to false
else
  tell application appChrome to activate
end if
