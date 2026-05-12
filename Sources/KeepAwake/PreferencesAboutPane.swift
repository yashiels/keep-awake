import SwiftUI

struct PreferencesAboutPane: View {
    let manager: KeepAwakeManager
    @State private var updateChecker = UpdateChecker()
    @State private var iconHover = false

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    var body: some View {
        VStack(spacing: 14) {
            if let image = NSApplication.shared.applicationIconImage {
                Button {
                    if let url = URL(string: "https://github.com/yashiels/keep-awake") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 88, height: 88)
                        .cornerRadius(16)
                        .scaleEffect(iconHover ? 1.05 : 1.0)
                        .shadow(color: iconHover ? .accentColor.opacity(0.25) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        iconHover = hovering
                    }
                }
            }

            VStack(spacing: 3) {
                Text("KeepAwake")
                    .font(.title3).bold()
                Text("Version \(versionString)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Keeps your Mac awake when MDM wants it asleep.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .center, spacing: 6) {
                AboutLinkRow(
                    icon: "chevron.left.slash.chevron.right",
                    title: "GitHub",
                    url: "https://github.com/yashiels/keep-awake")
                AboutLinkRow(
                    icon: "globe",
                    title: "Website",
                    url: "https://yashiels.github.io/keep-awake")
                AboutLinkRow(
                    icon: "ant",
                    title: "Report an Issue",
                    url: "https://github.com/yashiels/keep-awake/issues")
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity)

            Divider()

            VStack(spacing: 10) {
                if updateChecker.updateAvailable, let latest = updateChecker.latestVersion {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Update available: v\(latest)")
                            .font(.callout.bold())
                    }
                    if let url = updateChecker.releaseURL {
                        Button("Download Update") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                } else {
                    Button {
                        updateChecker.checkForUpdates()
                    } label: {
                        if updateChecker.isChecking {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 16, height: 16)
                            Text("Checking...")
                        } else {
                            Text("Check for Updates")
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Text("\u{00A9} 2026 Yashiel Sookdeo. MIT License.")
                .font(.footnote)
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                updateChecker.checkForUpdates()
            }
        }
    }
}

private struct AboutLinkRow: View {
    let icon: String
    let title: String
    let url: String
    @State private var hovering = false

    var body: some View {
        Button {
            if let url = URL(string: url) { NSWorkspace.shared.open(url) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .underline(hovering, color: .accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
