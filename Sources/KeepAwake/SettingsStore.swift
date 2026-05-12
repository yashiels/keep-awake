import Foundation
import ServiceManagement

@Observable
final class SettingsStore {
    private let defaults: UserDefaults
    private let prefix = "com.yashiels.KeepAwake."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var startOnLaunch: Bool {
        get { defaults.object(forKey: key("startOnLaunch")) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key("startOnLaunch")) }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    var notifyOnPowerChange: Bool {
        get { defaults.object(forKey: key("notifyOnPowerChange")) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key("notifyOnPowerChange")) }
    }

    var useAutoInterval: Bool {
        get { defaults.object(forKey: key("useAutoInterval")) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key("useAutoInterval")) }
    }

    var manualInterval: Int {
        get {
            let val = defaults.integer(forKey: key("manualInterval"))
            return val > 0 ? val : 120
        }
        set { defaults.set(newValue, forKey: key("manualInterval")) }
    }

    private func key(_ name: String) -> String {
        prefix + name
    }
}
