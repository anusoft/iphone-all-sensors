import Foundation
import GRDB

actor LoggingCoordinator {
    struct WriterKey: Hashable { let sensorID: SensorID; let stream: LogStream; let format: LogFormat }

    private let storage: LogStorageManager
    private let configStore: LoggingConfigStore
    private var writers: [WriterKey: any LogWriter] = [:]
    private var lastWritten: [SensorID: [LogStream: UInt64]] = [:]   // monotonicNs
    private var continuousPool: DatabasePool?

    init(storage: LogStorageManager, configStore: LoggingConfigStore) {
        self.storage = storage
        self.configStore = configStore
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
            // Phase 1: only continuous stream is "live"; sessions still do nothing until SessionManager arrives.
            if stream == .session { continue }
            if !shouldWrite(sample, stream: stream, intervalMs: intervalMs) { continue }
            let writer = await writer(for: sample.sensorID, stream: stream, format: format)
            await writer.write(sample)
        }
    }

    func flushAll() async {
        for w in writers.values { await w.flush() }
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

    private func writer(for id: SensorID, stream: LogStream, format: LogFormat) async -> any LogWriter {
        let key = WriterKey(sensorID: id, stream: stream, format: format)
        if let w = writers[key] { return w }
        let url: URL
        switch stream {
        case .continuous:
            url = (try? storage.continuousFileURL(for: id, format: format, day: Date()))
                ?? storage.rootURL.appendingPathComponent("\(id.rawValue).\(format.fileExtension)")
        case .session:
            url = storage.rootURL.appendingPathComponent("session-placeholder.\(format.fileExtension)")
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
                // session pool will be set in Task 2.4. For now, fall back to in-memory
                // so the coordinator never crashes if a session-stream sqlite write
                // happens before SessionManager is wired.
                let p = (try? ensureContinuousPool()) ?? (try! DatabasePool(path: ":memory:"))
                writer = SQLiteLogWriter(pool: p, sensorID: id, sessionID: nil)
            }
        }
        writers[key] = writer
        return writer
    }
}
