import XCTest
@testable import iPhoneSensors

final class LoggingCoordinatorTests: XCTestCase {
    func testThrottleDownsamples() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let store = await MainActor.run { LoggingConfigStore(defaults: UserDefaults(suiteName: UUID().uuidString)!) }
        await MainActor.run {
            store.set(LoggingConfiguration(continuous: .on(format: .jsonl, intervalMs: 100, options: .default), session: .off), for: .accelerometer)
        }
        let coord = LoggingCoordinator(storage: storage, configStore: store)
        await coord.start()

        // Fire 50 samples 10ms apart synthetically
        var t0 = Date()
        for i in 0..<50 {
            let s = SensorSample(sensorID: .accelerometer,
                                 payload: .acceleration(x: Double(i), y: 0, z: 0),
                                 wallTime: t0,
                                 monotonicNs: UInt64(i) * 10_000_000)
            await coord.ingest(s)
            t0 = t0.addingTimeInterval(0.010)
        }
        await coord.flushAll()

        // 50 samples spanning 0–500ms at 100ms throttle ⇒ ≤ 6 written
        let day = Date()
        let url = try storage.continuousFileURL(for: .accelerometer, format: .jsonl, day: day)
        let content = (try? String(contentsOf: url)) ?? ""
        let lineCount = content.split(separator: "\n").count
        XCTAssertGreaterThanOrEqual(lineCount, 1)
        XCTAssertLessThanOrEqual(lineCount, 6)
    }
}
