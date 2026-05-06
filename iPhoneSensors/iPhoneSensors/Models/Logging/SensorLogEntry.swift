import Foundation
import GRDB

struct SensorLogEntry: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: UUID
    var sessionID: UUID?
    var sensorID: String
    var wallTime: Double           // Unix seconds
    var monotonicNs: Int64
    var payloadKind: String
    var payloadJSON: String
    var schemaVersion: Int

    static let databaseTableName = "entries"
    enum CodingKeys: String, CodingKey {
        case id, sessionID = "session_id", sensorID = "sensor_id"
        case wallTime = "wall_time", monotonicNs = "monotonic_ns"
        case payloadKind = "payload_kind", payloadJSON = "payload_json"
        case schemaVersion = "schema_version"
    }
}
