import XCTest
import Foundation
@testable import iPhoneSensors

/// Smoke coverage for the non-logging core (sensor managers, live-value
/// accessor, data export, diagnostics). These guard the App-Intent / export
/// surfaces the audit found shipping placeholder data — they assert real,
/// formatted, non-fabricated output rather than exact readings.
@MainActor
final class CoreSensorSmokeTests: XCTestCase {

    // MARK: - Live value accessor (backs GetSensorReadingIntent)

    func testCurrentValueReturnsFormattedMotionReadingsNotPlaceholders() throws {
        let manager = SensorManager()

        // Accelerometer / gyroscope / magnetometer always yield a formatted
        // magnitude string (derived from live @Published values, 0 at rest).
        let acc = try XCTUnwrap(manager.currentValue(for: .accelerometer))
        XCTAssertTrue(acc.hasSuffix(" G"), "accelerometer should be formatted in G, got \(acc)")

        let gyro = manager.currentValue(for: .gyroscope)
        XCTAssertEqual(gyro?.hasSuffix(" rad/s"), true)

        let mag = manager.currentValue(for: .magnetometer)
        XCTAssertEqual(mag?.hasSuffix(" µT"), true)

        // Regression guard: the old intent hardcoded a Bangkok GPS coordinate.
        XCTAssertNotEqual(manager.currentValue(for: .gps), "13.7563°N, 100.5018°E")
    }

    func testCurrentValueReturnsNilForUnauthorizedLocation() {
        let manager = SensorManager()
        // In the test host location is not authorized → honest nil, not a fake fix.
        XCTAssertNil(manager.currentValue(for: .gps))
    }

    func testStopAllSensorsStopsSystemMonitoring() {
        let manager = SensorManager()

        manager.startAllSensors()
        XCTAssertTrue(manager.systemManager.isBatteryMonitoringEnabled)

        manager.stopAllSensors()

        XCTAssertFalse(manager.isStarted)
        XCTAssertFalse(manager.systemManager.isBatteryMonitoringEnabled)
    }

    // MARK: - Data export (backs ExportSensorDataIntent + in-app export)

    func testExportCurrentSensorsProducesNonEmptyCSV() throws {
        let manager = SensorManager()
        let url = DataExportManager.shared.exportCurrentSensors(
            motion: manager.motionManager,
            location: manager.locationManager,
            environment: manager.environmentManager,
            system: manager.systemManager,
            connectivity: manager.connectivityManager,
            camera: manager.cameraManager,
            format: .csv
        )
        let csvURL = try XCTUnwrap(url, "CSV export should return a file URL")
        let contents = try String(contentsOf: csvURL, encoding: .utf8)
        XCTAssertTrue(contents.hasPrefix("Timestamp,Sensor,Values,Unit"), "CSV header missing")
        // Header + one row per sensor snapshot.
        XCTAssertGreaterThan(contents.split(separator: "\n").count, 5)
        try? FileManager.default.removeItem(at: csvURL)
    }

    func testExportCurrentSensorsProducesParseableJSON() throws {
        let manager = SensorManager()
        let url = DataExportManager.shared.exportCurrentSensors(
            motion: manager.motionManager,
            location: manager.locationManager,
            environment: manager.environmentManager,
            system: manager.systemManager,
            connectivity: manager.connectivityManager,
            camera: manager.cameraManager,
            format: .json
        )
        let jsonURL = try XCTUnwrap(url)
        let data = try Data(contentsOf: jsonURL)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let sensors = obj?["sensors"] as? [[String: Any]]
        let unwrappedSensors = try XCTUnwrap(sensors)
        XCTAssertGreaterThan(unwrappedSensors.count, 0)
        try? FileManager.default.removeItem(at: jsonURL)
    }

    // MARK: - Diagnostics

    func testDiagnosticManagerResetPopulatesTests() {
        let dm = DiagnosticManager()
        XCTAssertEqual(dm.tests.count, 12)
        XCTAssertEqual(dm.overallScore, 0)
    }

    // MARK: - Model invariants used by location-stripping export

    func testLocationCategoryDerivation() {
        let locationIDs = Set(SensorID.allCases.filter { $0.category == .location })
        XCTAssertEqual(locationIDs, [.gps, .heading])
        // Every location id is namespaced under the "location." prefix, which the
        // strip-export relies on for both file and DB matching.
        for id in locationIDs {
            XCTAssertTrue(id.rawValue.hasPrefix("location."), "\(id.rawValue) lost its location prefix")
        }
    }
}
