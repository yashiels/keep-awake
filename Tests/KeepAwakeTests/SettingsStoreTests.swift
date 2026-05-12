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
}
