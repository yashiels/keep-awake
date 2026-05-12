import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: SettingsStore
    private let manager: KeepAwakeManager

    init(settings: SettingsStore, manager: KeepAwakeManager) {
        self.settings = settings
        self.manager = manager
    }

    func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(settings: settings, manager: manager)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 450, height: 400)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.title = "KeepAwake Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
