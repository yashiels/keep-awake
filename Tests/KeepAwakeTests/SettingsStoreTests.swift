import XCTest
@testable import KeepAwake

final class SettingsStoreTests: XCTestCase {
    private var store: SettingsStore!
    private let defaults = UserDefaults.standard
    private let prefix = "com.yashiels.KeepAwake."

    override func setUp() {
        super.setUp()
        store = KeepAwake.SettingsStore()
        // Clean test keys
        for key in ["startOnLaunch", "notifyOnPowerChange", "useAutoInterval", "manualInterval"] {
            defaults.removeObject(forKey: prefix + key)
        }
    }

    override func tearDown() {
        for key in ["startOnLaunch", "notifyOnPowerChange", "useAutoInterval", "manualInterval"] {
            defaults.removeObject(forKey: prefix + key)
        }
        super.tearDown()
    }

    func testStartOnLaunchDefaultsToTrue() {
        XCTAssertTrue(store.startOnLaunch)
    }

    func testStartOnLaunchPersists() {
        store.startOnLaunch = false
        XCTAssertFalse(store.startOnLaunch)
        let freshStore = KeepAwake.SettingsStore()
        XCTAssertFalse(freshStore.startOnLaunch)
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

    func testManualIntervalPersists() {
        store.manualInterval = 60
        XCTAssertEqual(store.manualInterval, 60)
        let freshStore = KeepAwake.SettingsStore()
        XCTAssertEqual(freshStore.manualInterval, 60)
    }
}
