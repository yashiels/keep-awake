import SwiftUI

enum PreferencesTab: String, CaseIterable, Hashable {
    case general
    case timing
    case about

    static let defaultWidth: CGFloat = 500
    static let windowHeight: CGFloat = 460

    var title: String {
        switch self {
        case .general: "General"
        case .timing: "Timing"
        case .about: "About"
        }
    }

    var preferredWidth: CGFloat { PreferencesTab.defaultWidth }
    var preferredHeight: CGFloat { PreferencesTab.windowHeight }
}

struct PreferencesView: View {
    let settings: SettingsStore
    let manager: KeepAwakeManager
    @State private var selectedTab: PreferencesTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            PreferencesGeneralPane(settings: settings)
                .tabItem { Label(PreferencesTab.general.title, systemImage: "gearshape") }
                .tag(PreferencesTab.general)

            PreferencesTimingPane(settings: settings, manager: manager)
                .tabItem { Label(PreferencesTab.timing.title, systemImage: "clock") }
                .tag(PreferencesTab.timing)

            PreferencesAboutPane(manager: manager)
                .tabItem { Label(PreferencesTab.about.title, systemImage: "info.circle") }
                .tag(PreferencesTab.about)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: PreferencesTab.defaultWidth, height: PreferencesTab.windowHeight)
    }
}
