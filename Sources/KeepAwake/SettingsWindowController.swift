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
        NSApp.setActivationPolicy(.accessory)

        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = PreferencesView(settings: settings, manager: manager)
        let w = PreferencesTab.defaultWidth
        let h = PreferencesTab.windowHeight
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: w, height: h)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.title = "KeepAwake Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
