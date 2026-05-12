import SwiftUI

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("KeepAwake Settings", id: "settings") {
            if let manager = appDelegate.manager {
                SettingsView(settings: manager.settings, manager: manager)
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
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

        // Hide settings window on launch — only show via menu
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            for window in NSApplication.shared.windows {
                if window.title == "KeepAwake Settings" {
                    window.orderOut(nil)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let existing = NSApp.windows.first(where: { $0.title == "KeepAwake Settings" }) {
            existing.makeKeyAndOrderFront(nil)
        }
    }
}
