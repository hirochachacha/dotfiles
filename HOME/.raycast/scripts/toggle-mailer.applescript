#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Mailer
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

set appName to "Spark Desktop"
set bundleID to "com.readdle.SparkDesktop.appstore"

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
