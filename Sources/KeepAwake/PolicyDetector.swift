import Foundation

struct DetectedPolicy: Identifiable {
    let id = UUID()
    let source: String
    let key: String
    let value: String
    let seconds: Int?
}

@Observable
final class PolicyDetector {
    private(set) var policies: [DetectedPolicy] = []
    private(set) var screensaverIdleTime: Int?
    private(set) var batteryDisplaySleep: Int?
    private(set) var batterySleep: Int?
    private(set) var acDisplaySleep: Int?
    private(set) var acSleep: Int?

    func refresh() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            var newPolicies: [DetectedPolicy] = []
            var newScreensaverIdleTime: Int?
            var newBatteryDisplaySleep: Int?
            var newBatterySleep: Int?
            var newAcDisplaySleep: Int?
            var newAcSleep: Int?

            Self.readManagedScreensaver(
                into: &newPolicies,
                screensaverIdleTime: &newScreensaverIdleTime)
            Self.readPmset(
                into: &newPolicies,
                batteryDisplaySleep: &newBatteryDisplaySleep,
                batterySleep: &newBatterySleep,
                acDisplaySleep: &newAcDisplaySleep,
                acSleep: &newAcSleep)

            DispatchQueue.main.async {
                self.policies = newPolicies
                self.screensaverIdleTime = newScreensaverIdleTime
                self.batteryDisplaySleep = newBatteryDisplaySleep
                self.batterySleep = newBatterySleep
                self.acDisplaySleep = newAcDisplaySleep
                self.acSleep = newAcSleep
            }
        }
    }

    func recommendedInterval(isOnAC: Bool) -> TimeInterval {
        var candidates: [Int] = []

        if let t = screensaverIdleTime { candidates.append(t) }

        if isOnAC {
            if let t = acDisplaySleep, t > 0 { candidates.append(t * 60) }
            if let t = acSleep, t > 0 { candidates.append(t * 60) }
        } else {
            if let t = batteryDisplaySleep, t > 0 { candidates.append(t * 60) }
            if let t = batterySleep, t > 0 { candidates.append(t * 60) }
        }

        guard let shortest = candidates.min() else { return 240 }
        let interval = Double(shortest) * 0.8
        return max(10, min(300, interval))
    }

    private static func readManagedScreensaver(
        into policies: inout [DetectedPolicy],
        screensaverIdleTime: inout Int?)
    {
        let path = "/Library/Managed Preferences/com.apple.screensaver"
        guard let prefs = UserDefaults(suiteName: path),
              let idleTime = prefs.object(forKey: "idleTime") as? Int else {
            readManagedScreensaverViaDefaults(into: &policies, screensaverIdleTime: &screensaverIdleTime)
            return
        }

        screensaverIdleTime = idleTime
        policies.append(DetectedPolicy(
            source: "Managed Preferences (screensaver)",
            key: "idleTime",
            value: "\(idleTime)s",
            seconds: idleTime
        ))

        if let askPw = prefs.object(forKey: "askForPassword") as? Int {
            policies.append(DetectedPolicy(
                source: "Managed Preferences (screensaver)",
                key: "askForPassword",
                value: askPw == 1 ? "Yes" : "No",
                seconds: nil
            ))
        }

        if let delay = prefs.object(forKey: "askForPasswordDelay") as? Int {
            policies.append(DetectedPolicy(
                source: "Managed Preferences (screensaver)",
                key: "askForPasswordDelay",
                value: "\(delay)s",
                seconds: nil
            ))
        }
    }

    private static func readManagedScreensaverViaDefaults(
        into policies: inout [DetectedPolicy],
        screensaverIdleTime: inout Int?)
    {
        let output = shell("/usr/bin/defaults", args: ["read", "/Library/Managed Preferences/com.apple.screensaver", "idleTime"])
        if let val = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
            screensaverIdleTime = val
            policies.append(DetectedPolicy(
                source: "Managed Preferences (screensaver)",
                key: "idleTime",
                value: "\(val)s",
                seconds: val
            ))
        }
    }

    private static func readPmset(
        into policies: inout [DetectedPolicy],
        batteryDisplaySleep: inout Int?,
        batterySleep: inout Int?,
        acDisplaySleep: inout Int?,
        acSleep: inout Int?)
    {
        let output = shell("/usr/bin/pmset", args: ["-g", "custom"])
        var inBattery = false
        var inAC = false

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Battery Power:") { inBattery = true; inAC = false; continue }
            if trimmed.hasPrefix("AC Power:") { inAC = true; inBattery = false; continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let rawValue = parts[1].trimmingCharacters(in: .whitespaces)
            guard let value = Int(rawValue) else { continue }

            if key == "displaysleep" {
                let source = inBattery ? "pmset (Battery)" : inAC ? "pmset (AC)" : "pmset"
                if inBattery { batteryDisplaySleep = value }
                if inAC { acDisplaySleep = value }
                policies.append(DetectedPolicy(
                    source: source,
                    key: "displaysleep",
                    value: value == 0 ? "Never" : "\(value) min",
                    seconds: value > 0 ? value * 60 : nil
                ))
            }

            if key == "sleep" {
                let source = inBattery ? "pmset (Battery)" : inAC ? "pmset (AC)" : "pmset"
                if inBattery { batterySleep = value }
                if inAC { acSleep = value }
                policies.append(DetectedPolicy(
                    source: source,
                    key: "sleep",
                    value: value == 0 ? "Never" : "\(value) min",
                    seconds: value > 0 ? value * 60 : nil
                ))
            }
        }
    }

    private static func shell(_ path: String, args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
