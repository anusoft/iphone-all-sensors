import XCTest
@testable import iPhoneSensors

final class SensorPayloadTests: XCTestCase {
    func testAccelerationCodableRoundTrip() throws {
        let p = SensorPayload.acceleration(x: 0.1, y: 0.2, z: -9.81)
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(SensorPayload.self, from: data)
        XCTAssertEqual(p, back)
    }
    func testKindString() {
        XCTAssertEqual(SensorPayload.acceleration(x: 0, y: 0, z: 0).kind, "acceleration")
        XCTAssertEqual(SensorPayload.battery(level: 0.8, state: "charging").kind, "battery")
    }
    func testCSVColumns() {
        let cols = SensorPayload.acceleration(x: 0, y: 0, z: 0).csvColumns
        XCTAssertEqual(cols, ["x", "y", "z"])
    }
    func testCSVValues() {
        let p = SensorPayload.acceleration(x: 1, y: 2, z: 3)
        XCTAssertEqual(p.csvValues, ["1.0", "2.0", "3.0"])
    }
}
