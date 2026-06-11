# AGENTS.md — KeepAwake

Native macOS menu bar app that prevents Jamf-managed screen lock by simulating user activity. Swift, SwiftUI, AppKit.

## Structure

```
keep-awake/
├── Sources/KeepAwake/
│   ├── KeepAwakeApp.swift          # App entry point, menu bar setup
│   ├── KeepAwakeManager.swift      # Core timer, power source monitoring, activity simulation
│   ├── PolicyDetector.swift        # MDM profile and pmset parser
│   ├── SettingsStore.swift         # Observable settings with UserDefaults persistence
│   ├── SettingsWindowController.swift
│   ├── StatusBarController.swift   # Menu bar icon and menu
│   ├── UpdateChecker.swift         # GitHub release update checks
│   ├── PreferencesView.swift
│   ├── PreferencesGeneralPane.swift
│   ├── PreferencesTimingPane.swift
│   ├── PreferencesAboutPane.swift
│   ├── PreferencesComponents.swift
│   └── Resources/                  # Info.plist, icons, assets
├── Tests/KeepAwakeTests/
│   ├── KeepAwakeManagerTests.swift
│   ├── PolicyDetectorTests.swift
│   └── SettingsStoreTests.swift
├── .github/workflows/
│   ├── ci.yml                      # swift build + test on push to main
│   ├── ship.yml                    # build + DMG + GitHub Release (manual trigger)
│   └── release-impl.yml            # shared release implementation
├── docs/                           # GitHub Pages marketing site
├── scripts/
│   ├── keep-awake.sh               # Lightweight shell script alternative
│   └── generate-icon.swift         # Icon generation script
├── Package.swift
├── Makefile
├── version.env
└── SPEC.md
```

## Build / Test / Lint

| Command      | What it does                                                         |
|--------------|----------------------------------------------------------------------|
| `make ci`    | Run lint then tests — the gate for every PR                          |
| `make lint`  | swiftlint (strict, quiet) if installed; falls back to swift build warnings |
| `make test`  | `swift test --parallel`                                              |
| `make build` | `swift build -c release`                                             |
| `make bundle`| Release build → `.app` bundle → ad-hoc codesign                     |
| `make dmg`   | Bundle → DMG installer with SHA-256                                  |
| `make fmt`   | `swiftformat Sources/ Tests/ Package.swift`                          |
| `make clean` | Remove `.app`, DMG, ZIPs and run `swift package clean`               |

Install optional formatters/linters:
```bash
brew install swiftformat swiftlint
```

## Key Design Decisions

- **Menu bar only** — no dock icon; the app lives entirely in the menu bar.
- **Simulated user activity** — sends `fn` key (CGEvent key code 63) to reset `HIDIdleTime`; no visible effect, no modifier conflict, no subprocess.
- **IOKit display sleep assertion** — held independently of the keypress simulation.
- **Auto-pause on lock** — stops ticking and releases the display assertion while the screen is locked; resumes on unlock.
- **MDM-aware interval** — auto-detects screensaver profiles in `/Library/Managed Preferences`, parses `pmset` timers, fires at 80% of the shortest detected timer (clamped 10s–300s).
- **Battery threshold** — auto-disables below a configurable threshold (5–50%) with 5% hysteresis.
- **Sparkle updates** — optional update checking against GitHub releases via `UpdateChecker`.

## Constraints

- macOS 14+ only. Swift 5.9+. Apple Silicon.
- Do not disable macOS security features or bypass SIP.
- Keep the app as a menu bar-only application (no dock presence).
- SwiftUI for settings panes; AppKit/NSStatusItem for menu bar integration.
- No analytics, no telemetry, no network calls except optional GitHub update checks.

## CI

| Workflow     | Trigger                    | Steps                                      |
|--------------|----------------------------|--------------------------------------------|
| `ci.yml`     | Push / PR to `main`        | `swift build -c release`, `swift test`     |
| `ship.yml`   | Manual (`workflow_dispatch`)| Bump version, build, DMG, GitHub Release, update Homebrew tap |

Run the CI gate locally:
```bash
make ci
```
