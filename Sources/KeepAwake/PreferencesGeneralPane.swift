import SwiftUI

struct PreferencesGeneralPane: View {
    @Bindable var settings: SettingsStore
    var hasBattery: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSection(contentSpacing: 12) {
                Text("SYSTEM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                PreferenceToggleRow(
                    title: "Start active on launch",
                    subtitle: "Automatically begin keeping your Mac awake when the app starts.",
                    binding: $settings.startOnLaunch)

                PreferenceToggleRow(
                    title: "Pause when screen is locked",
                    subtitle: "Automatically pause activity simulation while the screen is locked.",
                    binding: $settings.pauseWhenLocked)

                PreferenceToggleRow(
                    title: "Launch at Login",
                    subtitle: "Open KeepAwake automatically when you log in.",
                    binding: $settings.launchAtLogin)
            }

            Divider()

            SettingsSection(contentSpacing: 12) {
                Text("NOTIFICATIONS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                PreferenceToggleRow(
                    title: "Notify on power source change",
                    subtitle: "Show a notification when switching between AC and battery power.",
                    binding: $settings.notifyOnPowerChange)
            }

            if hasBattery {
                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("BATTERY")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    PreferenceToggleRow(
                        title: "Pause on low battery",
                        subtitle: "Suspend keep-awake activity when battery drops to the threshold.",
                        binding: $settings.pauseOnLowBattery)

                    if settings.pauseOnLowBattery {
                        HStack {
                            Text("Battery threshold")
                                .font(.body)
                            Spacer()
                            Slider(
                                value: Binding(
                                    get: { Double(settings.batteryThreshold) },
                                    set: { settings.batteryThreshold = Int($0) }
                                ),
                                in: 5...50,
                                step: 5
                            )
                            .frame(maxWidth: 160)
                            Text("\(settings.batteryThreshold)%")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }

            Divider()

            SettingsSection(contentSpacing: 12) {
                Text("BEHAVIOUR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                PreferenceToggleRow(
                    title: "Skip tick when user is active",
                    subtitle: "Avoids sending fake keypresses while you are typing or using the mouse. Disable if your screensaver still fires while you are using the machine.",
                    binding: $settings.skipWhenUserActive)
            }

            Divider()

            SettingsSection(contentSpacing: 12) {
                HStack {
                    Spacer()
                    Button("Quit KeepAwake") { NSApp.terminate(nil) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
