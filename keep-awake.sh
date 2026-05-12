#!/bin/bash
# Simulates fn keypress every 4 minutes to reset Jamf's screensaver idle timer.
# The fn key (key code 63) registers as user activity but has no visible effect.
# Your Jamf policy locks at 300s idle — this fires at 240s to stay under.

trap 'echo "keep-awake stopped."; exit 0' INT TERM

echo "keep-awake running (fn key every 240s). Ctrl+C to stop."
while true; do
    osascript -e 'tell application "System Events" to key code 63'
    sleep 240
done
