import SwiftUI

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("KeepAwakeKeepalive") {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    for window in NSApplication.shared.windows where window.title == "KeepAwakeKeepalive" {
                        window.setFrame(.zero, display: false)
                        window.orderOut(nil)
                    }
                }
        }
        .defaultSize(width: 0, height: 0)

        Settings {
            if let manager = appDelegate.manager {
                SettingsView(settings: manager.settings, manager: manager)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var manager: KeepAwakeManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let detector = PolicyDetector()
        detector.refresh()

        let manager = KeepAwakeManager(policyDetector: detector, settings: settings)
        self.manager = manager
        self.statusBarController = StatusBarController(manager: manager)

        if settings.startOnLaunch {
            manager.start()
            statusBarController?.updateIcon()
        }

        for window in NSApplication.shared.windows where window.title == "KeepAwakeKeepalive" {
            window.setFrame(.zero, display: false)
            window.orderOut(nil)
        }
    }
}
