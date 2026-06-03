import XCTest
@testable import iPhoneSensors

final class LoggingConfigurationTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let cfg = LoggingConfiguration(
            continuous: .on(format: .jsonl, intervalMs: 1000, options: .default),
            session: .on(format: .sqlite, intervalMs: 100, options: .default))
        let data = try JSONEncoder().encode(cfg)
        let back = try JSONDecoder().decode(LoggingConfiguration.self, from: data)
        XCTAssertEqual(cfg, back)
    }
    func testDefaultsForEverySensorReturnsNonNil() {
        for s in SensorID.allCases {
            _ = LoggingConfiguration.default(for: s)
        }
    }
    func testAccelerometerDefaultsContinuousOff() {
        let cfg = LoggingConfiguration.default(for: .accelerometer)
        if case .off = cfg.continuous {} else { XCTFail("expected continuous off") }
    }
    func testGPSDefaultsSessionSQLiteAt1Hz() {
        // Continuous streams are disabled across the app; GPS logs to the
        // session stream as SQLite at a 1s interval by default.
        let cfg = LoggingConfiguration.default(for: .gps)
        if case .off = cfg.continuous {} else { XCTFail("expected continuous off") }
        guard case let .on(format, intervalMs, _) = cfg.session else {
            return XCTFail("expected session on")
        }
        XCTAssertEqual(format, .sqlite)
        XCTAssertEqual(intervalMs, 1000)
    }

    func testDefaultIntervalsRespectSensorMinimum() {
        // No curated default may sample faster than the sensor's native floor.
        for s in SensorID.allCases {
            if case let .on(_, intervalMs, _) = LoggingConfiguration.default(for: s).session,
               intervalMs > 0 {
                XCTAssertGreaterThanOrEqual(intervalMs, s.minIntervalMs,
                    "\(s) default interval \(intervalMs)ms is below its minimum \(s.minIntervalMs)ms")
            }
        }
    }
}
