# KeepAwake — macOS Menu Bar App Specification

## Overview

KeepAwake is a native macOS menu bar utility that prevents Jamf-managed (or any MDM-managed) Macs from locking the screen due to idle timeout policies. It auto-detects the enforced policies, calculates the optimal keep-alive interval, and simulates invisible user activity to continuously reset the OS idle timer.

The app is distributed as a Homebrew cask and lives permanently in the menu bar with a minimal, native-feeling UI.

## Problem

Corporate MDM solutions (Jamf, Kandji, Mosyle) enforce screen lock via managed configuration profiles — specifically `com.apple.screensaver` with an `idleTime` value. Tools like `caffeinate`, Amphetamine, and KeepingYouAwake only prevent **system/display sleep** via IOKit power assertions. They do **not** prevent the **screensaver lock**, which is driven by a separate idle timer (`HIDIdleTime`) read by the `ScreenSaverEngine` daemon.

The only reliable way to defeat the screensaver idle timer is to simulate user input (mouse movement or keypress), which resets `HIDIdleTime` at the OS level.

## Architecture

### Build System
- Swift Package Manager (`Package.swift`) with `swift-tools-version: 5.10`
- Platform target: macOS 14+ (Sonoma)
- `Makefile` for building, bundling into `.app`, and installing
- No Xcode project — the app builds entirely via `swift build`
- Info.plist embedded via linker flags (`-sectcreate __TEXT __info_plist`)

### App Structure
```
Sources/KeepAwake/
  KeepAwakeApp.swift          — @main entry point, AppDelegate, invisible keepalive window
  KeepAwakeManager.swift      — Core engine: timer, activity simulation, power monitoring
  PolicyDetector.swift        — Reads Jamf/MDM managed preferences and pmset to detect policies
  StatusBarController.swift   — NSStatusItem, NSMenu construction, NSMenuDelegate
  SettingsView.swift          — SwiftUI Settings window (General, Timing, About tabs)
  SettingsStore.swift         — UserDefaults-backed @Observable settings model
  Resources/
    Info.plist                — LSUIElement=true, bundle ID, version
    AppIcon.icns              — macOS app icon (sun/moon motif)
```

### Key Design Decisions
- **NSStatusItem + NSMenu** (not SwiftUI `MenuBarExtra`) — more control, proven pattern from CodexBar/RepoBar
- **Rebuild menu on each open** via `NSMenuDelegate.menuWillOpen` — always fresh data, no stale state
- **osascript via Process** for activity simulation — proven to work on Jamf-managed machines, no Accessibility permission needed for the app itself (System Events handles it)
- **IOPMAssertion** for display sleep prevention on battery — belt-and-suspenders alongside input simulation
- **UserDefaults** for settings persistence — simple, no database needed

## Feature Specification

### 1. Jamf/MDM Policy Detection

On launch and periodically (every 5 minutes), the app reads:

**Managed Preferences** (no admin rights needed to read):
- `/Library/Managed Preferences/com.apple.screensaver` → `idleTime` (screensaver idle timeout in seconds)
- `/Library/Managed Preferences/com.apple.screensaver` → `askForPassword`, `askForPasswordDelay`
- `/Library/Managed Preferences/com.apple.screensaver` → `loginWindowIdleTime`

**Power Management** (via `pmset -g custom`):
- Battery: `sleep`, `displaysleep` values
- AC: `sleep`, `displaysleep` values

**Computed Values**:
- `effectiveIdleTimeout`: the minimum of all detected idle timers for the current power source
- `keepAliveInterval`: `effectiveIdleTimeout * 0.8` (fire at 80% of the shortest timer, with a floor of 10s and ceiling of 300s)

**Display in UI**: The Settings > About tab shows a "Detected Policies" section listing each discovered timer with its source and value, plus the computed interval. This helps the user understand what the app is working against.

### 2. Menu Bar Icon

- **Active state**: SF Symbol `sun.max` (outline weight `.regular`, point size 14)
- **Paused state**: SF Symbol `moon.zzz` (outline weight `.regular`, point size 14)
- Both rendered as template images (monochrome, adapts to light/dark mode and menu bar tinting)
- No text in the menu bar — icon only

### 3. Menu Bar Dropdown

When the user clicks the menu bar icon, an NSMenu appears:

```
┌─────────────────────────────────┐
│  ● Active for 2h 34m            │   ← green dot, disabled (info only)
│  ⚡ AC Power · 240s interval    │   ← bolt/battery SF Symbol, disabled
├─────────────────────────────────┤
│  Disable                        │   ← toggles to "Enable" when paused
├─────────────────────────────────┤
│  Settings...               ⌘,  │   ← opens Settings window
├─────────────────────────────────┤
│  Quit KeepAwake            ⌘Q  │
└─────────────────────────────────┘
```

When paused:
```
┌─────────────────────────────────┐
│  ○ Paused                       │   ← grey dot, disabled
├─────────────────────────────────┤
│  Enable                         │
├─────────────────────────────────┤
│  Settings...               ⌘,  │
├─────────────────────────────────┤
│  Quit KeepAwake            ⌘Q  │
└─────────────────────────────────┘
```

### 4. Settings Window

SwiftUI `Settings` scene with `TabView` (macOS-native tabs):

**General Tab**:
- Toggle: "Start KeepAwake on launch" (auto-enable on app start, default: ON)
- Toggle: "Launch at Login" (via `SMAppService.mainApp`, default: OFF)
- Toggle: "Show notification when switching power source" (default: ON)

**Timing Tab**:
- Picker: "Interval mode"
  - "Automatic (recommended)" — uses PolicyDetector to calculate optimal interval
  - "Manual" — shows a stepper/slider for custom interval (10s – 300s)
- Read-only display: "Current interval: Xs" (computed from mode + power source)
- Read-only display: "Detected screensaver timeout: Xs" (from PolicyDetector)
- Read-only display: "Detected display sleep: Xs" (from pmset for current power source)

**About Tab**:
- App name + version
- "Detected MDM Policies" section — table showing each detected policy, its source file, key, and value
- "How it works" — one-paragraph explanation
- Link to GitHub repo

### 5. App Icon

A proper macOS `.icns` app icon is required so the app doesn't look like a generic executable in Finder/Applications.

Design: a rounded-rect macOS icon shape with a sun outline (matching the `sun.max` SF Symbol aesthetic) on a gradient background (warm amber/gold to soft blue). Clean, minimal, professional.

For the initial version, generate the icon programmatically using AppKit:
- Create an `NSImage` at each required size (16, 32, 128, 256, 512 @1x and @2x)
- Draw a rounded rect background with a gradient fill
- Render the `sun.max` SF Symbol centered in white
- Export as `.icns` using `iconutil`

### 6. Activity Simulation

The core keep-alive mechanism:

```swift
func simulateActivity() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", "tell application \"System Events\" to key code 63"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
}
```

- `key code 63` is the `fn` key — registers as user activity but produces no visible output
- Works regardless of which app is in the foreground (System Events sends at the OS level)
- Works on all macOS apps — the event goes through the HID system, not to a specific app
- No Accessibility permission needed for KeepAwake itself (System Events is the one posting the event)

Additionally, when active, hold an IOKit assertion to prevent display sleep:
```swift
IOPMAssertionCreateWithName(
    kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    "KeepAwake" as CFString,
    &assertionID
)
```

### 7. Power Source Monitoring

- Check power source on each timer tick by reading `pmset -g batt`
- When power source changes (AC ↔ Battery), recalculate the interval from PolicyDetector
- On battery: interval is shorter (based on battery sleep/displaysleep timers which are typically 1-2 min)
- On AC: interval can be longer (based on screensaver idleTime, typically 5 min)
- Optionally show a macOS notification on power source change (if enabled in Settings)

### 8. Homebrew Distribution

Create a Homebrew cask for installation:

**GitHub Release workflow**:
1. Tag a release (`git tag v1.0.0`)
2. `make bundle` produces `KeepAwake.app`
3. Zip it: `zip -r KeepAwake-v1.0.0.zip KeepAwake.app`
4. Create GitHub Release with the zip attached
5. Compute SHA256: `shasum -a 256 KeepAwake-v1.0.0.zip`

**Homebrew Tap** (`homebrew-keepawake` repo):
```ruby
cask "keepawake" do
  version "1.0.0"
  sha256 "COMPUTED_SHA256"

  url "https://github.com/yashiels/keep-awake/releases/download/v#{version}/KeepAwake-v#{version}.zip"
  name "KeepAwake"
  desc "Menu bar app to prevent Jamf-managed macOS screen lock"
  homepage "https://github.com/yashiels/keep-awake"

  app "KeepAwake.app"

  zap trash: [
    "~/Library/Preferences/com.yashiels.KeepAwake.plist",
  ]
end
```

**Installation**: `brew install --cask yashiels/keepawake/keepawake`

### 9. Behavioral Requirements

- **Auto-start active**: When the app launches, it immediately starts keeping the machine awake (configurable via "Start KeepAwake on launch" setting)
- **No dock icon**: `LSUIElement = true` — the app only appears in the menu bar
- **Single instance**: `LSMultipleInstancesProhibited = true`
- **Graceful shutdown**: On Quit, release all IOPMAssertions and cancel all timers before terminating
- **Resilient**: If `osascript` fails (process error), log the failure but continue the timer — don't crash or stop
- **Low resource usage**: Timer fires at most every 10 seconds (battery worst case). Each tick is a sub-100ms osascript call. CPU usage should be unmeasurable.

## File-by-File Implementation Guide

### Package.swift
- `swift-tools-version: 5.10`
- Single `.executableTarget` named `KeepAwake`
- `exclude: ["Resources/Info.plist"]` (embedded via linker, not SPM resources)
- Linker flags to embed Info.plist in `__TEXT` segment

### KeepAwakeApp.swift
- `@main struct KeepAwakeApp: App` with `@NSApplicationDelegateAdaptor`
- `body`: invisible 1x1 `WindowGroup` keepalive (required for Settings scene) + `Settings` scene with `SettingsView`
- `AppDelegate`: creates `KeepAwakeManager`, `PolicyDetector`, `SettingsStore`, `StatusBarController` in `applicationDidFinishLaunching`
- Auto-starts the manager if `settingsStore.startOnLaunch` is true

### PolicyDetector.swift
- Reads `/Library/Managed Preferences/com.apple.screensaver` via `UserDefaults(suiteName:)` or `defaults read` via Process
- Reads `pmset -g custom` and parses battery/AC sleep and displaysleep values
- Exposes `DetectedPolicy` structs with source, key, value
- Computes `recommendedInterval(isOnAC: Bool) -> TimeInterval`

### KeepAwakeManager.swift
- Holds `isActive`, `isOnAC`, `startTime` state
- Uses `Timer.scheduledTimer` for the keep-alive loop
- On each tick: `simulateActivity()`, `updatePowerSource()`, recalculate interval if power changed
- Manages IOPMAssertion lifecycle (create on start, release on stop)
- Delegates interval calculation to `PolicyDetector`

### StatusBarController.swift
- `NSObject` subclass conforming to `NSMenuDelegate`
- Creates `NSStatusItem` with `sun.max` / `moon.zzz` template SF Symbol
- `menuWillOpen`: rebuilds entire menu from current state
- Menu items: status info (disabled), toggle, settings, quit
- Settings item triggers `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)` or `NSApp.activate()` + open settings

### SettingsView.swift
- SwiftUI `TabView` with `.tabItem` for General, Timing, About
- General: toggles for start-on-launch, launch-at-login, power-change notifications
- Timing: picker for auto/manual mode, interval stepper (when manual), detected values display
- About: version, detected policies table, how-it-works text

### SettingsStore.swift
- `@Observable` class backed by `UserDefaults.standard` with `com.yashiels.KeepAwake.` key prefix
- Properties: `startOnLaunch`, `launchAtLogin`, `notifyOnPowerChange`, `intervalMode` (auto/manual), `manualInterval`
- `launchAtLogin` setter calls `SMAppService.mainApp.register()`/`.unregister()`

### Makefile
- `build`: `swift build -c release`
- `bundle`: creates `.app` bundle with binary, Info.plist, and AppIcon.icns
- `install`: copies bundle to `/Applications`
- `run`: builds, bundles, opens
- `release`: bundles, zips, computes sha256
- `clean`: removes build artifacts

### AppIcon Generation
- A build-time script or a Swift helper that:
  1. Creates NSImage at required sizes
  2. Draws a rounded-rect with a warm gradient background
  3. Renders `sun.max` SF Symbol in white, centered
  4. Exports via `iconutil` to `.icns`
- Alternatively, include a pre-built `AppIcon.icns` in Resources/
