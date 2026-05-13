import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let manager: KeepAwakeManager
    private let settingsWindowController: SettingsWindowController
    private var refreshTimer: Timer?

    private var statusMenuItem: NSMenuItem?
    private var powerMenuItem: NSMenuItem?
    private var toggleMenuItem: NSMenuItem?

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
        menu.autoenablesItems = false

        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        let power = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        power.isEnabled = false
        menu.addItem(power)
        powerMenuItem = power

        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "Enable", action: #selector(toggleKeepAwake), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        toggleMenuItem = toggle

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit KeepAwake", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateMenuItems()
    }

    func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = manager.isActive ? "sun.max" : "moon.zzz"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "KeepAwake")
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let configured = image?.withSymbolConfiguration(config)
        configured?.isTemplate = true
        button.image = configured
    }

    func refreshMenu() {
        updateMenuItems()
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuItems()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateMenuItems()
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func updateMenuItems() {
        if manager.isActive {
            if manager.isScreenLocked {
                statusMenuItem?.title = "Paused — screen locked"
                statusMenuItem?.image = dotImage(color: .systemOrange)
                statusMenuItem?.isHidden = false
                powerMenuItem?.isHidden = true
                toggleMenuItem?.title = "Disable"
            } else if manager.isSuppressedByBattery {
                let level = manager.batteryLevel.map { "\($0)%" } ?? "low"
                statusMenuItem?.title = "Paused — battery \(level)"
                statusMenuItem?.image = dotImage(color: .systemOrange)
                statusMenuItem?.isHidden = false
                powerMenuItem?.title = "Battery \(level)  ·  \(Int(manager.interval))s interval"
                powerMenuItem?.image = NSImage(
                    systemSymbolName: "battery.25",
                    accessibilityDescription: nil)
                powerMenuItem?.isHidden = false
                toggleMenuItem?.title = "Disable"
            } else {
                statusMenuItem?.title = "Active for \(formatUptime())"
                statusMenuItem?.image = dotImage(color: .systemGreen)
                statusMenuItem?.isHidden = false

                let powerLabel = manager.isOnAC ? "AC Power" : "Battery"
                powerMenuItem?.title = "\(powerLabel)  ·  \(Int(manager.interval))s interval"
                powerMenuItem?.image = NSImage(
                    systemSymbolName: manager.isOnAC ? "bolt.fill" : "battery.50",
                    accessibilityDescription: nil)
                powerMenuItem?.isHidden = false

                toggleMenuItem?.title = "Disable"
            }
        } else {
            statusMenuItem?.title = "Paused"
            statusMenuItem?.image = dotImage(color: .systemGray)
            statusMenuItem?.isHidden = false

            powerMenuItem?.isHidden = true

            toggleMenuItem?.title = "Enable"
        }
    }

    // MARK: - Actions

    @objc private func toggleKeepAwake() {
        manager.toggle()
        updateIcon()
        updateMenuItems()
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
