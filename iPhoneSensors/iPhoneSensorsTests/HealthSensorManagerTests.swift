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

        XCTAssertEqual(status, "status.unavailable")
    }

    func testAuthorizationStatusTextShowsErrorKeyWhenAuthorizationFails() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: true,
            authorizationRequested: true,
            authorizationError: "Denied"
        )

        XCTAssertEqual(status, "status.error")
    }

    func testAuthorizationStatusTextShowsRequestNeededUntilPromptProcessed() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: true,
            authorizationRequested: false,
            authorizationError: nil
        )

        XCTAssertEqual(status, "health.status.needsPermission")
    }

    func testAuthorizationStatusTextShowsRequestProcessedAfterPromptProcessed() {
        let status = HealthSensorManager.authorizationStatusText(
            isHealthDataAvailable: true,
            authorizationRequested: true,
            authorizationError: nil
        )

        XCTAssertEqual(status, "health.status.accessRequested")
    }

    func testHealthReadTypesCanBeBuiltWithoutForceUnwraps() throws {
        let readTypes = try XCTUnwrap(HealthSensorManager.healthReadTypes())

        XCTAssertEqual(readTypes.count, 24)
        XCTAssertTrue(readTypes.contains(HKQuantityType(.heartRate)))
        XCTAssertTrue(readTypes.contains(HKCharacteristicType(.dateOfBirth)))
    }
}
