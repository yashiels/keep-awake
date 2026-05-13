import Foundation
import ServiceManagement

@Observable
final class SettingsStore {
    private let defaults: UserDefaults
    private let prefix = "com.yashiels.KeepAwake."

    var startOnLaunch: Bool {
        didSet { defaults.set(startOnLaunch, forKey: key("startOnLaunch")) }
    }

    var notifyOnPowerChange: Bool {
        didSet { defaults.set(notifyOnPowerChange, forKey: key("notifyOnPowerChange")) }
    }

    var useAutoInterval: Bool {
        didSet { defaults.set(useAutoInterval, forKey: key("useAutoInterval")) }
    }

    var manualInterval: Int {
        didSet {
            let clamped = max(10, min(300, manualInterval))
            if clamped != manualInterval { manualInterval = clamped }
            defaults.set(manualInterval, forKey: key("manualInterval"))
        }
    }

    var skipWhenUserActive: Bool {
        didSet { defaults.set(skipWhenUserActive, forKey: key("skipWhenUserActive")) }
    }

    private var isUpdatingLaunchAtLogin = false

    var launchAtLogin: Bool {
        didSet {
            guard !isUpdatingLaunchAtLogin else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                isUpdatingLaunchAtLogin = true
                launchAtLogin = SMAppService.mainApp.status == .enabled
                isUpdatingLaunchAtLogin = false
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.startOnLaunch = defaults.object(forKey: prefix + "startOnLaunch") as? Bool ?? true
        self.notifyOnPowerChange = defaults.object(forKey: prefix + "notifyOnPowerChange") as? Bool ?? true
        self.useAutoInterval = defaults.object(forKey: prefix + "useAutoInterval") as? Bool ?? true
        let manual = defaults.integer(forKey: prefix + "manualInterval")
        let rawManual = manual > 0 ? manual : 120
        self.manualInterval = max(10, min(300, rawManual))
        self.skipWhenUserActive = defaults.object(forKey: prefix + "skipWhenUserActive") as? Bool ?? false
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func key(_ name: String) -> String {
        prefix + name
    }
}
