import Foundation
import GRDB

actor LoggingCoordinator {
    struct WriterKey: Hashable { let sensorID: SensorID; let stream: LogStream; let format: LogFormat }

    private let storage: LogStorageManager
    private let configStore: LoggingConfigStore
    private var writers: [WriterKey: any LogWriter] = [:]
    private var lastWritten: [SensorID: [LogStream: UInt64]] = [:]   // monotonicNs
    private var continuousPool: DatabasePool?
    private var activeSessionID: UUID?
    private var sessionPool: DatabasePool?
    private var throttled = false
    private var flushTick = 0
    private let storageCapBytesDefault: Int64 = 1024 * 1024 * 1024  // 1 GB

    init(storage: LogStorageManager, configStore: LoggingConfigStore) {
        self.storage = storage
        self.configStore = configStore
    }

    func setActiveSession(_ id: UUID?, pool: DatabasePool?) {
        self.activeSessionID = id
        self.sessionPool = pool
    }

    func setThrottled(_ value: Bool) {
        self.throttled = value
    }

    private func ensureContinuousPool() throws -> DatabasePool {
        if let p = continuousPool { return p }
        let p = try DatabaseSchema.openPool(at: storage.continuousSQLiteURL())
        continuousPool = p
        return p
    }

    func start() async {
        // Phase 1: nothing to subscribe to yet — bus is wired in Task 1.10.
    }

    func ingest(_ sample: SensorSample) async {
        let cfg = await MainActor.run { configStore.config(for: sample.sensorID) }
        for stream in LogStream.allCases {
            let pcfg: PerStreamConfig = (stream == .continuous) ? cfg.continuous : cfg.session
            guard case let .on(format, intervalMs, _) = pcfg else { continue }
            // Session stream is gated on an active session; otherwise we drop.
            if stream == .session && activeSessionID == nil { continue }
            // When throttled, drop session writes; only continuous proceeds.
            if throttled && stream == .session { continue }
            if !shouldWrite(sample, stream: stream, intervalMs: intervalMs) { continue }
            guard let writer = await writer(for: sample.sensorID, stream: stream, format: format) else { continue }
            await writer.write(sample)
        }
    }

    func flushAll() async {
        for w in writers.values { await w.flush() }
        flushTick &+= 1
        if flushTick % 100 == 0 {
            let capMB = await MainActor.run { UserDefaults.standard.integer(forKey: "logger.storageCapMB") }
            let cap = capMB > 0 ? Int64(capMB) * 1024 * 1024 : storageCapBytesDefault
            _ = storage.enforceCapDeletingContinuousIfOver(targetBytes: cap)
        }
    }

    private func shouldWrite(_ s: SensorSample, stream: LogStream, intervalMs: Int) -> Bool {
        if intervalMs <= 0 {
            lastWritten[s.sensorID, default: [:]][stream] = s.monotonicNs
            return true
        }
        let last = lastWritten[s.sensorID]?[stream]
        let intervalNs = UInt64(intervalMs) * 1_000_000
        if let last, s.monotonicNs - last < intervalNs { return false }
        lastWritten[s.sensorID, default: [:]][stream] = s.monotonicNs
        return true
    }

    private func writer(for id: SensorID, stream: LogStream, format: LogFormat) async -> (any LogWriter)? {
        let key = WriterKey(sensorID: id, stream: stream, format: format)
        if let w = writers[key] { return w }
        let url: URL
        switch stream {
        case .continuous:
            url = (try? storage.continuousFileURL(for: id, format: format, day: Date()))
                ?? storage.rootURL.appendingPathComponent("\(id.rawValue).\(format.fileExtension)")
        case .session:
            guard let sid = activeSessionID,
                  let fileURL = try? storage.sessionFileURL(sid, sensor: id, format: format)
            else { return nil }
            url = fileURL
        }
        let writer: any LogWriter
        switch format {
        case .jsonl: writer = JSONLogWriter(url: url)
        case .csv:   writer = CSVLogWriter(url: url, options: .default)
        case .sqlite:
            if stream == .continuous {
                let p = (try? ensureContinuousPool()) ?? (try! DatabasePool(path: ":memory:"))
                writer = SQLiteLogWriter(pool: p, sensorID: id, sessionID: nil)
            } else {
                // Session-stream SQLite writes route to the active session pool.
                // Ingest gate ensures activeSessionID != nil, but sessionPool may be
                // unset if the caller hasn't wired it — drop in that case.
                guard let p = sessionPool, let sid = activeSessionID else { return nil }
                writer = SQLiteLogWriter(pool: p, sensorID: id, sessionID: sid)
            }
        }
        writers[key] = writer
        return writer
    }
}
