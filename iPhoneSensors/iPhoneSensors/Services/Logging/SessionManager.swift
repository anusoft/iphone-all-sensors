import Foundation
import GRDB
import UIKit

actor SessionManager {
    private let storage: LogStorageManager
    private(set) var activeSessionID: UUID?
    private(set) var activePool: DatabasePool?

    init(storage: LogStorageManager) { self.storage = storage }

    @discardableResult
    func startSession(note: String?) async throws -> SensorLogSession {
        let id = UUID()
        let url = try storage.sessionSQLiteURL(id)
        let pool = try DatabaseSchema.openPool(at: url)
        let s = SensorLogSession(
            id: id, startedAt: Date().timeIntervalSince1970, endedAt: nil,
            deviceModel: await MainActor.run { UIDevice.current.model },
            osVersion:   await MainActor.run { UIDevice.current.systemVersion },
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            note: note)
        try await pool.write { try s.insert($0) }
        self.activeSessionID = id
        self.activePool = pool
        return s
    }

    func stopSession() async throws {
        guard let id = activeSessionID, let pool = activePool else { return }
        let endedAt = Date().timeIntervalSince1970
        try await pool.write { db in
            try db.execute(sql: "UPDATE sessions SET ended_at = ? WHERE id = ?", arguments: [endedAt, id])
        }
        self.activeSessionID = nil
        self.activePool = nil
        try writeReadme(for: id, endedAt: endedAt)
    }

    func unfinishedSessions() async throws -> [SensorLogSession] {
        let root = try storage.sessionsRoot()
        let dirs = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        var out: [SensorLogSession] = []
        for dir in dirs {
            guard let id = UUID(uuidString: dir.lastPathComponent) else { continue }
            let dbURL = dir.appendingPathComponent("log.sqlite")
            guard FileManager.default.fileExists(atPath: dbURL.path) else { continue }
            do {
                let pool = try DatabasePool(path: dbURL.path)
                if let s = try await pool.read({ try SensorLogSession.fetchOne($0, key: id) }), s.endedAt == nil {
                    out.append(s)
                }
            } catch { continue }
        }
        return out
    }

    private func writeReadme(for id: UUID, endedAt: Double) throws {
        let dir = try storage.sessionDir(id)
        let readme = """
        Session \(id.uuidString)

        ended_at: \(Date(timeIntervalSince1970: endedAt).ISO8601Format())
        time-zone: \(TimeZone.current.identifier)

        FILES
          log.sqlite       — entries + sessions tables (GRDB schema v1)
          *.jsonl / *.csv  — per-sensor flat files

        SCHEMA
          entries(id, session_id, sensor_id, wall_time, monotonic_ns,
                  payload_kind, payload_json, schema_version)

        TIME
          wall_time: Unix seconds (Double); may skew on NTP correction.
          monotonic_ns: CLOCK_MONOTONIC_RAW; use for cross-sensor alignment.

        PRIVACY
          This archive may include precise location and HealthKit metrics.
          Treat as personal data.
        """
        try readme.data(using: .utf8)?.write(to: dir.appendingPathComponent("README.txt"))
    }
}
