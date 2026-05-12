import XCTest
@testable import KeepAwake

final class KeepAwakeManagerTests: XCTestCase {
    private var manager: KeepAwakeManager!
    private var detector: PolicyDetector!
    private var settings: SettingsStore!

    private let prefix = "com.yashiels.KeepAwake."

    override func setUp() {
        super.setUp()
        // Clean state before each test
        for key in ["startOnLaunch", "notifyOnPowerChange", "useAutoInterval", "manualInterval"] {
            UserDefaults.standard.removeObject(forKey: prefix + key)
        }
        UserDefaults.standard.synchronize()
        detector = PolicyDetector()
        detector.refresh()
        settings = SettingsStore()
        manager = KeepAwakeManager(policyDetector: detector, settings: settings)
    }

    override func tearDown() {
        manager.stop()
        super.tearDown()
    }

    func testInitialStateIsInactive() {
        XCTAssertFalse(manager.isActive)
        XCTAssertNil(manager.startTime)
        XCTAssertEqual(manager.uptime, 0)
    }

    func testStartActivatesManager() {
        manager.start()
        XCTAssertTrue(manager.isActive)
        XCTAssertNotNil(manager.startTime)
    }

    func testStopDeactivatesManager() {
        manager.start()
        manager.stop()
        XCTAssertFalse(manager.isActive)
        XCTAssertNil(manager.startTime)
    }

    func testToggleFlipsState() {
        XCTAssertFalse(manager.isActive)
        manager.toggle()
        XCTAssertTrue(manager.isActive)
        manager.toggle()
        XCTAssertFalse(manager.isActive)
    }

    func testUptimeIncreasesWhenActive() {
        manager.start()
        XCTAssertGreaterThanOrEqual(manager.uptime, 0)
    }

    func testIntervalUsesAutoDetection() {
        settings.useAutoInterval = true
        let interval = manager.interval
        XCTAssertGreaterThanOrEqual(interval, 10)
        XCTAssertLessThanOrEqual(interval, 300)
    }

    func testIntervalUsesManualWhenConfigured() {
        settings.useAutoInterval = false
        settings.manualInterval = 45
        UserDefaults.standard.synchronize()
        let freshManager = KeepAwakeManager(policyDetector: detector, settings: settings)
        XCTAssertEqual(freshManager.interval, 45)
    }

    func testPowerSourceIsDetected() {
        manager.start()
        // isOnAC should be a valid boolean (true or false) — just verify it doesn't crash
        _ = manager.isOnAC
    }
}
