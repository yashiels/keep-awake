import XCTest
@testable import KeepAwake

final class PolicyDetectorTests: XCTestCase {

    func testRefreshPopulatesPolicies() {
        let detector = PolicyDetector()
        detector.refresh()
        // On a Jamf-managed machine this should find the screensaver idle time
        // On unmanaged machines, at minimum pmset values are read
        XCTAssertFalse(detector.policies.isEmpty, "Should detect at least pmset power policies")
    }

    func testRecommendedIntervalOnAC() {
        let detector = PolicyDetector()
        detector.refresh()
        let interval = detector.recommendedInterval(isOnAC: true)
        XCTAssertGreaterThanOrEqual(interval, 10, "Interval should be at least 10s")
        XCTAssertLessThanOrEqual(interval, 300, "Interval should be at most 300s")
    }

    func testRecommendedIntervalOnBattery() {
        let detector = PolicyDetector()
        detector.refresh()
        let interval = detector.recommendedInterval(isOnAC: false)
        XCTAssertGreaterThanOrEqual(interval, 10, "Interval should be at least 10s")
        XCTAssertLessThanOrEqual(interval, 300, "Interval should be at most 300s")
    }

    func testBatteryIntervalShorterThanAC() {
        let detector = PolicyDetector()
        detector.refresh()
        let acInterval = detector.recommendedInterval(isOnAC: true)
        let batteryInterval = detector.recommendedInterval(isOnAC: false)
        // Battery typically has shorter sleep timers, so the interval should be <= AC
        XCTAssertLessThanOrEqual(batteryInterval, acInterval,
            "Battery interval should be <= AC interval")
    }

    func testPmsetValuesDetected() {
        let detector = PolicyDetector()
        detector.refresh()
        // pmset should always return battery and AC sleep/displaysleep
        let hasPmsetPolicy = detector.policies.contains { $0.source.hasPrefix("pmset") }
        XCTAssertTrue(hasPmsetPolicy, "Should detect pmset power management settings")
    }
}
