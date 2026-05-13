import SwiftUI

struct PreferencesGeneralPane: View {
    @Bindable var settings: SettingsStore

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
