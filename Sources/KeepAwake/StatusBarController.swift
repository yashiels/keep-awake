import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let manager: KeepAwakeManager
    private let settingsWindowController: SettingsWindowController

    init(manager: KeepAwakeManager, settingsWindowController: SettingsWindowController) {
        self.manager = manager
        self.settingsWindowController = settingsWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        updateIcon()
        statusItem.button?.imagePosition = .imageOnly
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = manager.isActive ? "sun.max" : "moon.zzz"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "KeepAwake")
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.image = image?.withSymbolConfiguration(config)
        button.image?.isTemplate = true
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        if manager.isActive {
            let statusItem = NSMenuItem(
                title: "Active for \(formatUptime())",
                action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            statusItem.image = dotImage(color: .systemGreen)
            menu.addItem(statusItem)

            let powerLabel = manager.isOnAC ? "AC Power" : "Battery"
            let powerItem = NSMenuItem(
                title: "\(powerLabel)  ·  \(Int(manager.interval))s interval",
                action: nil, keyEquivalent: "")
            powerItem.image = NSImage(systemSymbolName: manager.isOnAC ? "bolt.fill" : "battery.50",
                                       accessibilityDescription: nil)
            powerItem.isEnabled = false
            menu.addItem(powerItem)
        } else {
            let pausedItem = NSMenuItem(title: "Paused", action: nil, keyEquivalent: "")
            pausedItem.isEnabled = false
            pausedItem.image = dotImage(color: .systemGray)
            menu.addItem(pausedItem)
        }

        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: manager.isActive ? "Disable" : "Enable",
            action: #selector(toggleKeepAwake), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit KeepAwake", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func toggleKeepAwake() {
        manager.toggle()
        updateIcon()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func quitApp() {
        manager.stop()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Helpers

    private func formatUptime() -> String {
        let total = Int(manager.uptime)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "< 1m"
    }

    private func dotImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 8, height: 8)
        return NSImage(size: size, flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }
}
