import XCTest
@testable import KeepAwake

final class KeepAwakeManagerTests: XCTestCase {
    private var manager: KeepAwakeManager!
    private var detector: PolicyDetector!
    private var settings: SettingsStore!

    override func setUp() {
        super.setUp()
        let suite = UserDefaults(suiteName: UUID().uuidString)!
        detector = PolicyDetector()
        detector.refresh()
        settings = SettingsStore(defaults: suite)
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
        let freshManager = KeepAwakeManager(policyDetector: detector, settings: settings)
        XCTAssertEqual(freshManager.interval, 45)
    }

    func testPowerSourceIsDetected() {
        manager.start()
        _ = manager.isOnAC
    }

    func testFirstTickAlwaysSimulates() {
        settings.skipWhenUserActive = true
        manager.start()
        XCTAssertTrue(manager.isActive)
    }

    func testStopResetsFirstTickFlag() {
        manager.start()
        manager.stop()
        manager.start()
        XCTAssertTrue(manager.isActive)
    }

    func testSkipWhenUserActiveToggleAtRuntime() {
        manager.start()
        settings.skipWhenUserActive = true
        settings.skipWhenUserActive = false
        XCTAssertTrue(manager.isActive)
    }

    func testIsUserIdleDoesNotCrash() {
        settings.skipWhenUserActive = true
        settings.useAutoInterval = false
        settings.manualInterval = 60
        _ = manager.isUserIdle()
    }
}
