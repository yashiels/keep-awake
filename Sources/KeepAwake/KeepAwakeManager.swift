import Foundation
import IOKit.ps
import IOKit.pwr_mgt
import UserNotifications

@Observable
final class KeepAwakeManager {
    private(set) var isActive = false
    private(set) var isOnAC = true
    private(set) var startTime: Date?

    let policyDetector: PolicyDetector
    let settings: SettingsStore

    var onPowerSourceChanged: (() -> Void)?

    private var timer: Timer?
    private var policyRefreshTimer: Timer?
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private var powerSourceLoop: CFRunLoopSource?

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
        updatePowerSource()
        startPowerSourceMonitoring()
        observeSettingsChanges()
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

    // MARK: - Settings Observation

    private func observeSettingsChanges() {
        withObservationTracking {
            _ = self.settings.useAutoInterval
            _ = self.settings.manualInterval
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.isActive {
                    self.scheduleTimer()
                }
                self.observeSettingsChanges()
            }
        }
    }

    // MARK: - Power Source Monitoring

    private func startPowerSourceMonitoring() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let manager = Unmanaged<KeepAwakeManager>.fromOpaque(context).takeUnretainedValue()
            manager.handlePowerSourceChange()
        }, context)?.takeRetainedValue() else { return }

        powerSourceLoop = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    private func handlePowerSourceChange() {
        let wasOnAC = isOnAC
        updatePowerSource()
        guard wasOnAC != isOnAC else { return }

        if settings.notifyOnPowerChange {
            sendPowerChangeNotification()
        }

        if isActive {
            scheduleTimer()
            if isOnAC {
                releaseDisplayAssertion()
            } else {
                createDisplayAssertion()
            }
        }

        onPowerSourceChanged?()
    }

    // MARK: - Timer

    private func tick() {
        simulateActivity()
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

    // MARK: - Activity Simulation

    private func simulateActivity() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to key code 63"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            // Silently continue
        }
    }

    // MARK: - Power Source Detection

    private func updatePowerSource() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              !sources.isEmpty else {
            isOnAC = true
            return
        }
        let type = IOPSGetProvidingPowerSourceType(snapshot)?.takeRetainedValue() as String?
        isOnAC = type == kIOPSACPowerValue
    }

    // MARK: - Display Assertion

    private func createDisplayAssertion() {
        guard displayAssertionID == IOPMAssertionID(kIOPMNullAssertionID) else { return }
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "KeepAwake" as CFString,
            &displayAssertionID)
    }

    private func releaseDisplayAssertion() {
        guard displayAssertionID != IOPMAssertionID(kIOPMNullAssertionID) else { return }
        IOPMAssertionRelease(displayAssertionID)
        displayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }

    // MARK: - Notifications

    private func sendPowerChangeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "KeepAwake"
        content.body = isOnAC
            ? "Switched to AC Power — interval \(Int(interval))s"
            : "Switched to Battery — interval \(Int(interval))s"
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        if let source = powerSourceLoop {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }
}
