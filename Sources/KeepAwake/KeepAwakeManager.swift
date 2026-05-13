import Foundation
import IOKit.ps
import IOKit.pwr_mgt
import UserNotifications
import CoreGraphics

@Observable
final class KeepAwakeManager {
    private(set) var isActive = false
    private(set) var isOnAC = true
    private(set) var isScreenLocked = false
    private(set) var batteryLevel: Int?
    private(set) var isSuppressedByBattery = false
    private(set) var startTime: Date?

    let policyDetector: PolicyDetector
    let settings: SettingsStore

    var onPowerSourceChanged: (() -> Void)?

    private var timer: Timer?
    private var policyRefreshTimer: Timer?
    private var screenLockTimer: Timer?
    private var didFireFirstTick = false
    private var powerSourceDebounce: DispatchWorkItem?
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private var powerSourceLoop: CFRunLoopSource?
    private var powerSourceContext: UnsafeMutableRawPointer?

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
        startScreenLockPolling()
        schedulePolicyRefresh()

        if settings.pauseWhenLocked && isSessionLocked() {
            isScreenLocked = true
            return
        }

        createDisplayAssertion()
        tick()
        scheduleTimer()
    }

    func stop() {
        isActive = false
        isScreenLocked = false
        startTime = nil
        didFireFirstTick = false
        timer?.invalidate()
        timer = nil
        policyRefreshTimer?.invalidate()
        policyRefreshTimer = nil
        screenLockTimer?.invalidate()
        screenLockTimer = nil
        releaseDisplayAssertion()
    }

    // MARK: - Settings Observation

    private func observeSettingsChanges() {
        withObservationTracking {
            _ = self.settings.useAutoInterval
            _ = self.settings.manualInterval
            _ = self.settings.skipWhenUserActive
            _ = self.settings.pauseWhenLocked
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                guard let self else {
                    self?.observeSettingsChanges()
                    return
                }
                guard self.isActive else {
                    self.observeSettingsChanges()
                    return
                }

                if self.settings.pauseWhenLocked {
                    self.startScreenLockPolling()
                    if self.isScreenLocked { self.pauseForScreenLock() }
                } else {
                    self.stopScreenLockPolling()
                    if self.isScreenLocked { self.resumeFromScreenLock() }
                }

                self.scheduleTimer()
                self.observeSettingsChanges()
            }
        }
    }

    // MARK: - Power Source Monitoring

    private func startPowerSourceMonitoring() {
        let context = Unmanaged.passRetained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let manager = Unmanaged<KeepAwakeManager>.fromOpaque(context).takeUnretainedValue()
            manager.handlePowerSourceChange()
        }, context)?.takeRetainedValue() else {
            // Balance the retain if source creation failed
            Unmanaged<KeepAwakeManager>.fromOpaque(context).release()
            return
        }

        powerSourceContext = context
        powerSourceLoop = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    private func handlePowerSourceChange() {
        powerSourceDebounce?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.handlePowerSourceChangeDebounced()
        }
        powerSourceDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func handlePowerSourceChangeDebounced() {
        let wasOnAC = isOnAC
        updatePowerSource()
        guard wasOnAC != isOnAC else { return }

        if settings.notifyOnPowerChange {
            sendPowerChangeNotification()
        }

        if isActive && !isScreenLocked {
            scheduleTimer()
        }

        onPowerSourceChanged?()
    }

    // MARK: - Timer

    private func tick() {
        let shouldSuppress = shouldSuppressForBattery()

        if shouldSuppress && !isSuppressedByBattery {
            isSuppressedByBattery = true
            releaseDisplayAssertion()
            if settings.notifyOnPowerChange { sendSuppressionNotification(paused: true) }
            return
        }

        if !shouldSuppress && isSuppressedByBattery {
            isSuppressedByBattery = false
            createDisplayAssertion()
            if settings.notifyOnPowerChange { sendSuppressionNotification(paused: false) }
        }

        if isSuppressedByBattery { return }

        if !didFireFirstTick {
            didFireFirstTick = true
            simulateActivity()
            return
        }

        guard settings.skipWhenUserActive else {
            simulateActivity()
            return
        }

        guard isUserIdle() else { return }
        simulateActivity()
    }

    private func shouldSuppressForBattery() -> Bool {
        guard settings.pauseOnLowBattery, let level = batteryLevel else { return false }
        if isSuppressedByBattery {
            return level < settings.batteryThreshold + 5
        }
        return level <= settings.batteryThreshold
    }

    // .combinedSessionState includes our own synthetic events — this is intentional.
    // When skipWhenUserActive is true and the user is genuinely idle, idleSeconds ≈
    // interval (from our last tick), which exceeds the threshold. When the user is
    // active, their input keeps idleSeconds small and we correctly skip.
    internal func isUserIdle() -> Bool {
        let threshold = interval * 0.5
        let src = CGEventSourceStateID.combinedSessionState
        let types: [CGEventType] = [
            .keyDown, .mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel,
        ]
        let idleSeconds = types.map {
            CGEventSource.secondsSinceLastEventType(src, eventType: $0)
        }.min() ?? Double.greatestFiniteMagnitude
        return idleSeconds >= threshold
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
            guard let self, !self.isScreenLocked else { return }
            self.policyDetector.refresh()
            self.scheduleTimer()
        }
    }

    // MARK: - Screen Lock Detection

    private func isSessionLocked() -> Bool {
        guard let info = CGSessionCopyCurrentDictionary() as? [String: Any] else { return false }
        return info["CGSSessionScreenIsLocked"] as? Bool ?? false
    }

    private func startScreenLockPolling() {
        guard settings.pauseWhenLocked else { return }
        screenLockTimer?.invalidate()
        screenLockTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkScreenLock()
        }
    }

    private func stopScreenLockPolling() {
        screenLockTimer?.invalidate()
        screenLockTimer = nil
    }

    private func checkScreenLock() {
        guard settings.pauseWhenLocked else { return }
        let locked = isSessionLocked()
        if locked && !isScreenLocked {
            pauseForScreenLock()
        } else if !locked && isScreenLocked {
            resumeFromScreenLock()
        }
    }

    private func pauseForScreenLock() {
        isScreenLocked = true
        timer?.invalidate()
        timer = nil
        releaseDisplayAssertion()
    }

    private func resumeFromScreenLock() {
        isScreenLocked = false
        createDisplayAssertion()
        tick()
        scheduleTimer()
    }

    // MARK: - Activity Simulation

    private func simulateActivity() {
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x3F, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x3F, keyDown: false) {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
            return
        }
        // Fallback: osascript
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
            batteryLevel = nil
            return
        }
        let type = IOPSGetProvidingPowerSourceType(snapshot)?.takeRetainedValue() as String?
        isOnAC = type == kIOPSACPowerValue
        batteryLevel = readBatteryLevel(from: snapshot, sources: sources)
    }

    // IOPSGetPowerSourceDescription returns +0 ownership — do NOT call .takeRetainedValue()
    private func readBatteryLevel(from snapshot: CFTypeRef, sources: [Any]) -> Int? {
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?
                                .takeUnretainedValue() as? [String: Any],
                  let sourceType = desc[kIOPSTypeKey] as? String,
                  sourceType == kIOPSInternalBatteryType,
                  let capacity = desc[kIOPSCurrentCapacityKey] as? Int else { continue }
            return capacity
        }
        return nil
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

    private func sendSuppressionNotification(paused: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "KeepAwake"
        if paused {
            let level = batteryLevel.map { "\($0)%" } ?? "low"
            content.body = "Paused — battery at \(level) (≤ \(settings.batteryThreshold)%)"
        } else {
            let level = batteryLevel.map { "\($0)%" } ?? "sufficient"
            content.body = "Resumed — battery at \(level)"
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        if let source = powerSourceLoop {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        // Balance the passRetained from startPowerSourceMonitoring
        if let ctx = powerSourceContext {
            Unmanaged<KeepAwakeManager>.fromOpaque(ctx).release()
        }
    }
}
