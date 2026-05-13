import XCTest
@testable import KeepAwake

final class SettingsStoreTests: XCTestCase {
    private var store: SettingsStore!
    private var suite: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.yashiels.KeepAwake.test.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)!
        store = SettingsStore(defaults: suite)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testStartOnLaunchDefaultsToTrue() {
        XCTAssertTrue(store.startOnLaunch)
    }

    func testStartOnLaunchCanBeSet() {
        store.startOnLaunch = false
        XCTAssertFalse(store.startOnLaunch)
    }

    func testNotifyOnPowerChangeDefaultsToTrue() {
        XCTAssertTrue(store.notifyOnPowerChange)
    }

    func testUseAutoIntervalDefaultsToTrue() {
        XCTAssertTrue(store.useAutoInterval)
    }

    func testManualIntervalDefaultsTo120() {
        XCTAssertEqual(store.manualInterval, 120)
    }

    func testManualIntervalCanBeSet() {
        store.manualInterval = 60
        XCTAssertEqual(store.manualInterval, 60)
    }

    func testSkipWhenUserActiveDefaultsToFalse() {
        XCTAssertFalse(store.skipWhenUserActive)
    }

    func testSkipWhenUserActiveCanBeSet() {
        store.skipWhenUserActive = true
        XCTAssertTrue(store.skipWhenUserActive)
        store.skipWhenUserActive = false
        XCTAssertFalse(store.skipWhenUserActive)
    }

    func testSkipWhenUserActivePersistedAcrossInstances() {
        store.skipWhenUserActive = true
        let store2 = SettingsStore(defaults: suite)
        XCTAssertTrue(store2.skipWhenUserActive)
    }

    func testPauseWhenLockedDefaultsToTrue() {
        XCTAssertTrue(store.pauseWhenLocked)
    }

    func testPauseWhenLockedPersists() {
        store.pauseWhenLocked = false
        let store2 = SettingsStore(defaults: suite)
        XCTAssertFalse(store2.pauseWhenLocked)
    }

    func testPauseOnLowBatteryDefaultsToFalse() {
        XCTAssertFalse(store.pauseOnLowBattery)
    }

    func testPauseOnLowBatteryPersists() {
        store.pauseOnLowBattery = true
        let store2 = SettingsStore(defaults: suite)
        XCTAssertTrue(store2.pauseOnLowBattery)
    }

    func testBatteryThresholdDefaultsTo20() {
        XCTAssertEqual(store.batteryThreshold, 20)
    }

    func testBatteryThresholdClampsLow() {
        store.batteryThreshold = 2
        XCTAssertEqual(store.batteryThreshold, 5)
    }

    func testBatteryThresholdClampsHigh() {
        store.batteryThreshold = 100
        XCTAssertEqual(store.batteryThreshold, 50)
    }

    func testBatteryThresholdPersists() {
        store.batteryThreshold = 30
        let store2 = SettingsStore(defaults: suite)
        XCTAssertEqual(store2.batteryThreshold, 30)
    }
}
