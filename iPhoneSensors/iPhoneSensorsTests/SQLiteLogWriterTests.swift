import XCTest
import GRDB
@testable import iPhoneSensors

final class SQLiteLogWriterTests: XCTestCase {
    func testBatchedInsertRoundTrip() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).sqlite")
        let pool = try DatabaseSchema.openPool(at: url)
        let w = SQLiteLogWriter(pool: pool, sensorID: .accelerometer, sessionID: nil, batchSize: 5)
        for i in 0..<12 {
            await w.write(SensorSample(sensorID: .accelerometer,
                                       payload: .acceleration(x: Double(i), y: 0, z: 0)))
        }
        await w.flush()
        let count = try await pool.read { try SensorLogEntry.fetchCount($0) }
        XCTAssertEqual(count, 12)
    }
}
