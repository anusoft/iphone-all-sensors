import XCTest
@testable import iPhoneSensors

final class SensorIDTests: XCTestCase {
    func testRawValuesStable() {
        XCTAssertEqual(SensorID.accelerometer.rawValue, "motion.accelerometer")
        XCTAssertEqual(SensorID.gps.rawValue, "location.gps")
        XCTAssertEqual(SensorID.battery.rawValue, "system.battery")
    }
    func testCategoryGrouping() {
        XCTAssertEqual(SensorID.accelerometer.category, .motion)
        XCTAssertEqual(SensorID.gps.category, .location)
    }
    func testAllCasesIncludesEverySensor() {
        XCTAssertGreaterThanOrEqual(SensorID.allCases.count, 25)
    }
}
