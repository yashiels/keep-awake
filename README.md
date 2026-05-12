# KeepAwake

macOS menu bar app that prevents Jamf-managed screen lock by simulating user activity.

## Why

`caffeinate` and similar tools (Amphetamine, KeepingYouAwake) only prevent **system/display sleep** via IOKit assertions. They do **not** prevent the **screensaver lock** enforced by Jamf configuration profiles. KeepAwake simulates actual user input, which resets the `HIDIdleTime` counter that the screensaver daemon monitors.

## Menu Bar App

A native Swift menu bar app with:
- Toggle on/off from the menu bar (sun/moon icon)
- Auto-adjusts interval based on power source (240s on AC, 30s on battery)
- IOKit display sleep assertion on battery
- Active time counter
- Launch at Login support

### Build & Run

```bash
make run
```

### Install to /Applications

```bash
make install
```

## Shell Script (lightweight alternative)

A standalone shell script is also available in `scripts/keep-awake.sh`:

```bash
chmod +x scripts/keep-awake.sh
./scripts/keep-awake.sh
```

## How it works

- Sends `fn` key (key code 63) via System Events, which registers as user activity but produces no visible output
- On AC power: fires every 240s (under the typical Jamf 300s idle timeout)
- On battery: fires every 30s and holds a display sleep assertion (macOS battery settings sleep at 60s)
