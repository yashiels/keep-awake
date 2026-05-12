import SwiftUI

@main
struct KeepAwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("KeepAwakeKeepalive") {
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    DispatchQueue.main.async {
                        for window in NSApp.windows where window.title == "KeepAwakeKeepalive" {
                            window.orderOut(nil)
                        }
                    }
                }
        }
        .defaultSize(width: 0, height: 0)
        .windowStyle(.hiddenTitleBar)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var manager: KeepAwakeManager?
    var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let detector = PolicyDetector()
        detector.refresh()

        let manager = KeepAwakeManager(policyDetector: detector, settings: settings)
        self.manager = manager

        let settingsWC = SettingsWindowController(settings: settings, manager: manager)
        self.settingsWindowController = settingsWC

        let statusBar = StatusBarController(manager: manager, settingsWindowController: settingsWC)
        self.statusBarController = statusBar

        manager.onPowerSourceChanged = { [weak statusBar] in
            statusBar?.updateIcon()
            statusBar?.refreshMenu()
        }

        if settings.startOnLaunch {
            manager.start()
            statusBar.updateIcon()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
