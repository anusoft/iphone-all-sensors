import Foundation
import GRDB

actor SQLiteLogWriter: LogWriter {
    private let pool: DatabasePool
    private let sensorID: SensorID
    private let sessionID: UUID?
    private let batchSize: Int
    private var pending: [SensorLogEntry] = []
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0

    init(pool: DatabasePool, sensorID: SensorID, sessionID: UUID?, batchSize: Int = 100) {
        self.pool = pool
        self.sensorID = sensorID
        self.sessionID = sessionID
        self.batchSize = max(1, batchSize)
    }

    func write(_ sample: SensorSample) async {
        do {
            let json = try JSONEncoder().encode(sample.payload)
            let entry = SensorLogEntry(
                id: UUID(), sessionID: sessionID,
                sensorID: sample.sensorID.rawValue,
                wallTime: sample.wallTime.timeIntervalSince1970,
                monotonicNs: Int64(bitPattern: sample.monotonicNs),
                payloadKind: sample.payload.kind,
                payloadJSON: String(data: json, encoding: .utf8) ?? "",
                schemaVersion: 1)
            pending.append(entry)
            entriesWritten += 1
            if pending.count >= batchSize { await flush() }
        } catch { /* drop */ }
    }

    func flush() async {
        guard !pending.isEmpty else { return }
        let batch = pending
        pending.removeAll(keepingCapacity: true)
        do {
            try await pool.write { db in
                for e in batch { try e.insert(db) }
            }
            bytesWritten += Int64(batch.reduce(0) { $0 + $1.payloadJSON.utf8.count + 80 })
        } catch { /* drop */ }
    }

    func close() async { await flush() }
}
