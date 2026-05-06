import XCTest
@testable import iPhoneSensors

final class JSONLogWriterTests: XCTestCase {
    func testWritesOneJSONPerLine() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).jsonl")
        let w = JSONLogWriter(url: tmp)
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 1, y: 2, z: 3)))
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 4, y: 5, z: 6)))
        await w.flush()
        let txt = try String(contentsOf: tmp, encoding: .utf8)
        let lines = txt.split(separator: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            _ = try JSONSerialization.jsonObject(with: Data(line.utf8))
        }
    }
}
