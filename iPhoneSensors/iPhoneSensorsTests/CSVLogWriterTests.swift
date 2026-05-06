import XCTest
@testable import iPhoneSensors

final class CSVLogWriterTests: XCTestCase {
    func testHeaderWrittenOnceThenRows() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).csv")
        let w = CSVLogWriter(url: url, options: .default)
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 1, y: 2, z: 3)))
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 4, y: 5, z: 6)))
        await w.flush()
        let lines = try String(contentsOf: url).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].contains("wall_time"))
        XCTAssertTrue(lines[0].contains(",x,y,z"))
    }
}
