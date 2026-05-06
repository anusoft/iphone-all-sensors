import Foundation
import GRDB

enum DatabaseSchema {
    static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "sessions", ifNotExists: true) { t in
                t.column("id", .blob).primaryKey()
                t.column("started_at", .double).notNull()
                t.column("ended_at", .double)
                t.column("device_model", .text)
                t.column("os_version", .text)
                t.column("app_version", .text)
                t.column("note", .text)
            }
            try db.create(table: "entries", ifNotExists: true) { t in
                t.column("id", .blob).primaryKey()
                t.column("session_id", .blob)
                t.column("sensor_id", .text).notNull()
                t.column("wall_time", .double).notNull()
                t.column("monotonic_ns", .integer).notNull()
                t.column("payload_kind", .text).notNull()
                t.column("payload_json", .text).notNull()
                t.column("schema_version", .integer).notNull().defaults(to: 1)
            }
            try db.create(index: "idx_entries_sensor_time", on: "entries", columns: ["sensor_id", "wall_time"])
            try db.create(index: "idx_entries_time", on: "entries", columns: ["wall_time"])
        }
        return m
    }

    static func openPool(at url: URL) throws -> DatabasePool {
        var config = Configuration()
        config.prepareDatabase { db in try db.execute(sql: "PRAGMA journal_mode=WAL") }
        let pool = try DatabasePool(path: url.path, configuration: config)
        try migrator.migrate(pool)
        return pool
    }
}
