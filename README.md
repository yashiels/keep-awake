# keep-awake

Lightweight shell script that prevents Jamf-managed macOS screen lock by simulating an `fn` keypress every 4 minutes, resetting the screensaver idle timer.

## Why

`caffeinate` and similar tools (Amphetamine, KeepingYouAwake) only prevent **system/display sleep** via IOKit assertions. They do **not** prevent the **screensaver lock** enforced by Jamf configuration profiles. This script simulates actual user input, which resets the `HIDIdleTime` counter that the screensaver daemon monitors.

## Usage

```bash
chmod +x keep-awake.sh

# Foreground (Ctrl+C to stop)
./keep-awake.sh

# Background
./keep-awake.sh &

# Stop
pkill -f keep-awake.sh
```

## How it works

- Sends `fn` key (key code 63) via `osascript` / System Events every 240 seconds
- `fn` registers as user activity but produces no visible output
- Default interval (240s) stays safely under the typical Jamf 300s idle timeout
