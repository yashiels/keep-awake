import Foundation
import IOKit.pwr_mgt
import ServiceManagement

final class KeepAwakeManager {
    private(set) var isActive = false
    private(set) var isOnAC = true
    private(set) var startTime: Date?

    private var timer: Timer?
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)

    var interval: TimeInterval {
        isOnAC ? 240 : 30
    }

    var uptime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
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

    func toggle() {
        isActive ? stop() : start()
    }

    func start() {
        isActive = true
        startTime = Date()
        updatePowerSource()
        createDisplayAssertion()
        tick()
        scheduleTimer()
    }

    func stop() {
        isActive = false
        startTime = nil
        timer?.invalidate()
        timer = nil
        releaseDisplayAssertion()
    }

    private func tick() {
        simulateActivity()
        let wasOnAC = isOnAC
        updatePowerSource()
        if wasOnAC != isOnAC {
            scheduleTimer()
        }
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func simulateActivity() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to key code 63"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    private func updatePowerSource() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        isOnAC = output.contains("AC Power")
    }

    private func createDisplayAssertion() {
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
}
