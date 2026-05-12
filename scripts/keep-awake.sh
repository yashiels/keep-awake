#!/bin/bash
# Simulates fn keypress to reset Jamf's screensaver idle timer.
# The fn key (key code 63) registers as user activity but has no visible effect.
# Adjusts interval based on power source — battery has aggressive sleep timers.

trap 'echo "keep-awake stopped."; exit 0' INT TERM

get_interval() {
    if pmset -g batt | grep -q "AC Power"; then
        echo 240  # AC: Jamf locks at 300s, fire at 240s
    else
        echo 30   # Battery: display sleeps at 120s, system at 60s — fire at 30s
    fi
}

echo "keep-awake running. Ctrl+C to stop."
while true; do
    interval=$(get_interval)
    osascript -e 'tell application "System Events" to key code 63'
    caffeinate -dims -t "$interval" &
    caff_pid=$!
    sleep "$interval"
    kill "$caff_pid" 2>/dev/null
done
