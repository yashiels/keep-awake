import Foundation
import IOKit.pwr_mgt
import UserNotifications

final class KeepAwakeManager {
    private(set) var isActive = false
    private(set) var isOnAC = true
    private(set) var startTime: Date?

    let policyDetector: PolicyDetector
    let settings: SettingsStore

    private var timer: Timer?
    private var policyRefreshTimer: Timer?
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)

    var interval: TimeInterval {
        if settings.useAutoInterval {
            return policyDetector.recommendedInterval(isOnAC: isOnAC)
        }
        return TimeInterval(settings.manualInterval)
    }

    var uptime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    init(policyDetector: PolicyDetector, settings: SettingsStore) {
        self.policyDetector = policyDetector
        self.settings = settings
    }

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        isActive = true
        startTime = Date()
        updatePowerSource()
        policyDetector.refresh()
        createDisplayAssertion()
        tick()
        scheduleTimer()
        schedulePolicyRefresh()
    }

    func stop() {
        isActive = false
        startTime = nil
        timer?.invalidate()
        timer = nil
        policyRefreshTimer?.invalidate()
        policyRefreshTimer = nil
        releaseDisplayAssertion()
    }

    private func tick() {
        simulateActivity()
        let wasOnAC = isOnAC
        updatePowerSource()
        if wasOnAC != isOnAC {
            if settings.notifyOnPowerChange {
                sendPowerChangeNotification()
            }
            scheduleTimer()
            if isOnAC {
                releaseDisplayAssertion()
            } else {
                createDisplayAssertion()
            }
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func schedulePolicyRefresh() {
        policyRefreshTimer?.invalidate()
        policyRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.policyDetector.refresh()
            self?.scheduleTimer()
        }
    }

    private func simulateActivity() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to key code 63"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            // Silently continue — don't crash the timer loop
        }
    }

    private func updatePowerSource() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        isOnAC = output.contains("AC Power")
    }

    private func createDisplayAssertion() {
        guard displayAssertionID == IOPMAssertionID(kIOPMNullAssertionID) else { return }
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "KeepAwake" as CFString,
            &displayAssertionID
        )
    }

    private func releaseDisplayAssertion() {
        guard displayAssertionID != IOPMAssertionID(kIOPMNullAssertionID) else { return }
        IOPMAssertionRelease(displayAssertionID)
        displayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }

    private func sendPowerChangeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "KeepAwake"
        content.body = isOnAC
            ? "Switched to AC Power — interval \(Int(interval))s"
            : "Switched to Battery — interval \(Int(interval))s"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
