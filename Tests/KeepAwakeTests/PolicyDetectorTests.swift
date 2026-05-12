import XCTest
@testable import KeepAwake

final class PolicyDetectorTests: XCTestCase {

    /// Helper: call refresh() and wait for the async result to be dispatched back to main.
    private func refreshAndWait(_ detector: PolicyDetector) {
        let expectation = expectation(description: "refresh completes")
        detector.refresh()
        // Refresh dispatches results back to DispatchQueue.main.async; enqueue a follow-up
        // work item on main after the refresh enqueue to catch the result.
        DispatchQueue.main.async {
            // Give the background work time to finish, then check on main again.
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2) {
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }

    func testRefreshPopulatesPolicies() {
        let detector = PolicyDetector()
        refreshAndWait(detector)
        // On a Jamf-managed machine this should find the screensaver idle time
        // On unmanaged machines, at minimum pmset values are read
        XCTAssertFalse(detector.policies.isEmpty, "Should detect at least pmset power policies")
    }

    func testRecommendedIntervalOnAC() {
        let detector = PolicyDetector()
        refreshAndWait(detector)
        let interval = detector.recommendedInterval(isOnAC: true)
        XCTAssertGreaterThanOrEqual(interval, 10, "Interval should be at least 10s")
        XCTAssertLessThanOrEqual(interval, 300, "Interval should be at most 300s")
    }

    func testRecommendedIntervalOnBattery() {
        let detector = PolicyDetector()
        refreshAndWait(detector)
        let interval = detector.recommendedInterval(isOnAC: false)
        XCTAssertGreaterThanOrEqual(interval, 10, "Interval should be at least 10s")
        XCTAssertLessThanOrEqual(interval, 300, "Interval should be at most 300s")
    }

    func testBatteryIntervalShorterThanAC() {
        let detector = PolicyDetector()
        refreshAndWait(detector)
        let acInterval = detector.recommendedInterval(isOnAC: true)
        let batteryInterval = detector.recommendedInterval(isOnAC: false)
        // Battery typically has shorter sleep timers, so the interval should be <= AC
        XCTAssertLessThanOrEqual(batteryInterval, acInterval,
            "Battery interval should be <= AC interval")
    }

    func testPmsetValuesDetected() {
        let detector = PolicyDetector()
        refreshAndWait(detector)
        // pmset should always return battery and AC sleep/displaysleep
        let hasPmsetPolicy = detector.policies.contains { $0.source.hasPrefix("pmset") }
        XCTAssertTrue(hasPmsetPolicy, "Should detect pmset power management settings")
    }
}
