import XCTest
@testable import iPhoneSensors

final class LoggingCoordinatorTests: XCTestCase {
    /// The session stream is the only user-exposed stream (continuous is always
    /// sanitized off), so the interval-based downsampling that the UI configures
    /// is verified here on the session path.
    func testIntervalDownsamplesSessionStream() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let store = try await MainActor.run {
            let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
            return LoggingConfigStore(defaults: defaults)
        }
        await MainActor.run {
            store.set(LoggingConfiguration(continuous: .off, session: .on(format: .jsonl, intervalMs: 100, options: .default)), for: .accelerometer)
        }
        let coord = LoggingCoordinator(storage: storage, configStore: store)
        await coord.start()

        // JSONL session writes only need an active session id (no DB pool).
        let sid = UUID()
        await coord.setActiveSession(sid, pool: nil)

        // Fire 50 samples 10ms apart synthetically.
        var t0 = Date()
        for i in 0..<50 {
            let s = SensorSample(sensorID: .accelerometer,
                                 payload: .acceleration(x: Double(i), y: 0, z: 0),
                                 wallTime: t0,
                                 monotonicNs: UInt64(i) * 10_000_000)
            await coord.ingest(s)
            t0 = t0.addingTimeInterval(0.010)
        }
        _ = await coord.flushAll()

        // 50 samples spanning 0-490ms at a 100ms interval => <= 6 written.
        let url = try storage.sessionFileURL(sid, sensor: .accelerometer, format: .jsonl)
        let content = (try? String(contentsOf: url)) ?? ""
        let lineCount = content.split(separator: "\n").count
        XCTAssertGreaterThanOrEqual(lineCount, 1)
        XCTAssertLessThanOrEqual(lineCount, 6)
    }

    func testFlushAllReportsWriterFailure() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let store = try await MainActor.run {
            let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
            return LoggingConfigStore(defaults: defaults)
        }
        await MainActor.run {
            store.set(LoggingConfiguration(continuous: .off, session: .on(format: .jsonl, intervalMs: 0, options: .default)), for: .accelerometer)
        }
        let coord = LoggingCoordinator(storage: storage, configStore: store)
        let sid = UUID()
        let fileURL = try storage.sessionFileURL(sid, sensor: .accelerometer, format: .jsonl)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        await coord.setActiveSession(sid, pool: nil)

        await coord.ingest(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 1, y: 2, z: 3)))
        let error: String? = await coord.flushAll()

        XCTAssertNotNil(error)
    }
}
