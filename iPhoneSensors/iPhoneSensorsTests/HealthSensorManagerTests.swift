import HealthKit
import XCTest
@testable import iPhoneSensors

final class HealthSensorManagerTests: XCTestCase {
    func testAuthorizationStatusTextShowsUnavailableBeforePermissionState() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: false,
            authorizationRequested: true,
            authorizationError: nil
        )

        XCTAssertEqual(status, "Unavailable")
    }

    func testAuthorizationStatusTextShowsRequestNeededUntilPromptProcessed() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: true,
            authorizationRequested: false,
            authorizationError: nil
        )

        XCTAssertEqual(status, "Needs Permission")
    }

    func testAuthorizationStatusTextShowsReadyAfterPromptProcessed() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: true,
            authorizationRequested: true,
            authorizationError: nil
        )

        XCTAssertEqual(status, "Ready")
    }
}
