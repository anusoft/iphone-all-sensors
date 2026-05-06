import XCTest
import GRDB
@testable import iPhoneSensors

final class DatabaseSchemaTests: XCTestCase {
    func testMigratorCreatesTablesIdempotently() throws {
        let queue = try DatabaseQueue()
        try DatabaseSchema.migrator.migrate(queue)
        try DatabaseSchema.migrator.migrate(queue)   // idempotent
        try queue.read { db in
            XCTAssertTrue(try db.tableExists("entries"))
            XCTAssertTrue(try db.tableExists("sessions"))
        }
    }

    func testInsertEntryRoundTrip() throws {
        let queue = try DatabaseQueue()
        try DatabaseSchema.migrator.migrate(queue)
        let entry = SensorLogEntry(
            id: UUID(), sessionID: nil,
            sensorID: SensorID.accelerometer.rawValue,
            wallTime: Date().timeIntervalSince1970,
            monotonicNs: 12345,
            payloadKind: "acceleration",
            payloadJSON: "{\"x\":1,\"y\":2,\"z\":3}",
            schemaVersion: 1)
        try queue.write { try entry.insert($0) }
        let count = try queue.read { try SensorLogEntry.fetchCount($0) }
        XCTAssertEqual(count, 1)
    }
}
