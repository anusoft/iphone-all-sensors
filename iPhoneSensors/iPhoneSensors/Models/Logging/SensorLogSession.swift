import Foundation
import GRDB

struct SensorLogSession: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: UUID
    var startedAt: Double          // Unix seconds
    var endedAt: Double?
    var deviceModel: String
    var osVersion: String
    var appVersion: String
    var note: String?

    static let databaseTableName = "sessions"
    enum CodingKeys: String, CodingKey {
        case id, startedAt = "started_at", endedAt = "ended_at"
        case deviceModel = "device_model", osVersion = "os_version"
        case appVersion = "app_version", note
    }
}
