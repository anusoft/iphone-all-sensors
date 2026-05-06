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
    func testGPSDefaultsContinuousOn() {
        let cfg = LoggingConfiguration.default(for: .gps)
        if case .on = cfg.continuous {} else { XCTFail("expected continuous on") }
    }
}
