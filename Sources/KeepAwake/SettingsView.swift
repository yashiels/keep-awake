import SwiftUI

struct SettingsView: View {
    let settings: SettingsStore
    let manager: KeepAwakeManager

    var body: some View {
        TabView {
            GeneralTab(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }
            TimingTab(settings: settings, manager: manager)
                .tabItem { Label("Timing", systemImage: "clock") }
            AboutTab(manager: manager)
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 320)
    }
}

private struct GeneralTab: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Toggle("Start active on launch", isOn: $settings.startOnLaunch)
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Notify on power source change", isOn: $settings.notifyOnPowerChange)
        }
        .formStyle(.grouped)
    }
}

private struct TimingTab: View {
    @Bindable var settings: SettingsStore
    let manager: KeepAwakeManager

    var body: some View {
        Form {
            Picker("Interval mode", selection: $settings.useAutoInterval) {
                Text("Automatic (recommended)").tag(true)
                Text("Manual").tag(false)
            }

            if !settings.useAutoInterval {
                Stepper(
                    "Interval: \(settings.manualInterval)s",
                    value: $settings.manualInterval,
                    in: 10...300,
                    step: 10
                )
            }

            Section("Detected Timers") {
                LabeledContent("Current interval") {
                    Text("\(Int(manager.interval))s")
                        .monospacedDigit()
                }
                LabeledContent("Power source") {
                    Text(manager.isOnAC ? "AC Power" : "Battery")
                }
                if let t = manager.policyDetector.screensaverIdleTime {
                    LabeledContent("Screensaver idle timeout") {
                        Text("\(t)s (MDM managed)")
                            .monospacedDigit()
                    }
                }
                if let t = manager.isOnAC ? manager.policyDetector.acDisplaySleep : manager.policyDetector.batteryDisplaySleep {
                    LabeledContent("Display sleep") {
                        Text(t == 0 ? "Never" : "\(t) min")
                            .monospacedDigit()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct AboutTab: View {
    let manager: KeepAwakeManager

    var body: some View {
        Form {
            Section {
                LabeledContent("Version") { Text("1.0.0") }
            }

            Section("Detected MDM Policies") {
                if manager.policyDetector.policies.isEmpty {
                    Text("No managed policies detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.policyDetector.policies) { policy in
                        LabeledContent(policy.key) {
                            VStack(alignment: .trailing) {
                                Text(policy.value)
                                Text(policy.source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("How it works") {
                Text("KeepAwake simulates an invisible fn keypress at a regular interval, resetting the macOS idle timer that MDM-managed screensaver policies monitor. This prevents the screen from locking without modifying any system settings.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
