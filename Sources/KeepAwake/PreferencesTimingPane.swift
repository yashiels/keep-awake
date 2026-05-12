import SwiftUI

struct PreferencesTimingPane: View {
    @Bindable var settings: SettingsStore
    let manager: KeepAwakeManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 12) {
                    Text("INTERVAL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interval mode")
                                .font(.body)
                            Text("Automatic uses 80% of the shortest detected policy timer.")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Picker("", selection: $settings.useAutoInterval) {
                            Text("Automatic").tag(true)
                            Text("Manual").tag(false)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 160)
                    }

                    if !settings.useAutoInterval {
                        HStack {
                            Text("Manual interval")
                                .font(.body)
                            Spacer()
                            Stepper(
                                "\(settings.manualInterval)s",
                                value: $settings.manualInterval,
                                in: 10...300,
                                step: 10
                            )
                            .monospacedDigit()
                        }
                    }
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("CURRENT STATE")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack {
                        Text("Active interval")
                        Spacer()
                        Text("\(Int(manager.interval))s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Power source")
                        Spacer()
                        Text(manager.isOnAC ? "AC Power" : "Battery")
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                SettingsSection(contentSpacing: 10) {
                    Text("DETECTED POLICIES")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if manager.policyDetector.policies.isEmpty {
                        Text("No policies detected")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    } else {
                        if let t = manager.policyDetector.screensaverIdleTime {
                            HStack {
                                Text("Screensaver timeout")
                                Spacer()
                                Text("\(t)s")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Text("MDM")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        if let t = manager.policyDetector.batteryDisplaySleep {
                            policyRow("Battery display sleep", value: t == 0 ? "Never" : "\(t) min")
                        }
                        if let t = manager.policyDetector.batterySleep {
                            policyRow("Battery system sleep", value: t == 0 ? "Never" : "\(t) min")
                        }
                        if let t = manager.policyDetector.acDisplaySleep {
                            policyRow("AC display sleep", value: t == 0 ? "Never" : "\(t) min")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func policyRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
