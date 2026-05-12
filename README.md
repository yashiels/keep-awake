# KeepAwake

A native macOS menu bar app that prevents Jamf-managed (or any MDM) screen lock by simulating user activity.

## Install

**Homebrew:**
```bash
brew install --cask yashiels/keepawake/keepawake
```

**DMG:** Download from [Releases](https://github.com/yashiels/keep-awake/releases), open the DMG, drag KeepAwake to Applications.

**Build from source:**
```bash
make run        # build and launch
make install    # build and copy to /Applications
make dmg        # create DMG installer
```

## Why

`caffeinate`, Amphetamine, and KeepingYouAwake only prevent **system/display sleep** via IOKit assertions. They do **not** prevent the **screensaver lock** enforced by Jamf configuration profiles. KeepAwake simulates actual user input (`fn` keypress), which resets the `HIDIdleTime` counter that the screensaver daemon monitors.

## Features

- Auto-detects MDM screensaver and power management policies
- Calculates optimal keep-alive interval (80% of shortest detected timer)
- Adapts between AC power and battery with different intervals
- Settings window with General, Timing, and About tabs
- Outline sun/moon SF Symbol menu bar icon
- Launch at Login support
- Works with all apps (System Events posts at the OS level)

## How it works

1. Reads `/Library/Managed Preferences/com.apple.screensaver` for the MDM idle timeout
2. Reads `pmset -g custom` for battery/AC sleep timers
3. Calculates the shortest timer and fires at 80% of that interval
4. Sends `fn` key (key code 63) via System Events on each tick
5. Holds an IOKit display sleep assertion when on battery

## Development

```bash
make build      # compile
make test       # run 19 unit tests
make bundle     # create .app bundle
make dmg        # create DMG
make release    # create release DMG with SHA256
```

## Shell Script (lightweight alternative)

A standalone shell script is available in `scripts/keep-awake.sh` for systems where you can't install apps.
