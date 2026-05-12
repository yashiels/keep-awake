import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let manager: KeepAwakeManager

    init(manager: KeepAwakeManager) {
        self.manager = manager
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

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = manager.isActive ? "sun.max" : "moon.zzz"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "KeepAwake")
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.image = image?.withSymbolConfiguration(config)
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let toggleItem = NSMenuItem(
            title: manager.isActive ? "Disable" : "Enable",
            action: #selector(toggleKeepAwake),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        if manager.isActive {
            menu.addItem(.separator())

            let uptimeItem = NSMenuItem(
                title: "Active for \(formatUptime())",
                action: nil,
                keyEquivalent: ""
            )
            uptimeItem.isEnabled = false
            menu.addItem(uptimeItem)

            let powerLabel = manager.isOnAC ? "AC Power" : "Battery"
            let powerItem = NSMenuItem(
                title: "\(powerLabel)  ·  \(Int(manager.interval))s interval",
                action: nil,
                keyEquivalent: ""
            )
            let powerIcon = manager.isOnAC ? "bolt.fill" : "battery.50"
            powerItem.image = NSImage(systemSymbolName: powerIcon, accessibilityDescription: nil)
            powerItem.isEnabled = false
            menu.addItem(powerItem)
        }

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = manager.launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit KeepAwake",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func toggleKeepAwake() {
        manager.toggle()
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin() {
        manager.launchAtLogin.toggle()
    }

    @objc private func quitApp() {
        manager.stop()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Formatting

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
}
