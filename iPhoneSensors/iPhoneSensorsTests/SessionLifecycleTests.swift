import XCTest
import GRDB
@testable import iPhoneSensors

final class SessionLifecycleTests: XCTestCase {
    @MainActor
    func testLoggingServiceStartStopSessionUpdatesPublishedState() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(true, forKey: "logger.masterEnabled")  // logging is opt-in
        let service = LoggingService(storage: storage, configStore: LoggingConfigStore(defaults: defaults))

        await service.bootstrap()
        await service.startSessionFromUI(note: "control")

        XCTAssertNotNil(service.activeSessionDisplayID)
        XCTAssertNotNil(service.sessionStartedAt)

        await service.stopSessionFromUI()

        XCTAssertNil(service.activeSessionDisplayID)
        XCTAssertNil(service.sessionStartedAt)
    }

    @MainActor
    func testScopedSessionTemporarilyRecordsOnlySelectedSensor() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(true, forKey: "logger.masterEnabled")  // logging is opt-in
        let service = LoggingService(storage: storage, configStore: LoggingConfigStore(defaults: defaults))

        // Give gyroscope a known prior state so we can verify it's restored.
        service.configStore.set(LoggingConfiguration.default(for: .gyroscope), for: .gyroscope)
        XCTAssertTrue(service.configStore.config(for: .gyroscope).session.isOn)

        await service.bootstrap()
        await service.startSessionFromUI(note: "accelerometer", only: .accelerometer)

        XCTAssertTrue(service.configStore.config(for: .accelerometer).session.isOn)
        XCTAssertFalse(service.configStore.config(for: .gyroscope).session.isOn)

        await service.stopSessionFromUI()

        // Prior gyroscope state is restored after the scoped session ends.
        XCTAssertTrue(service.configStore.config(for: .gyroscope).session.isOn)
    }

    @MainActor
    func testSessionDoesNotStartWhenLoggingDisabled() async throws {
        // Master switch off (the default) means no session may start.
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let service = LoggingService(storage: storage, configStore: LoggingConfigStore(defaults: defaults))

        await service.bootstrap()
        await service.startSessionFromUI(note: "blocked")

        XCTAssertNil(service.activeSessionDisplayID)
        XCTAssertNil(service.sessionStartedAt)
    }

    @MainActor
    func testStartSessionFailurePublishesLoggingError() async throws {
        let rootFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString)-not-a-directory")
        try? "file".write(to: rootFile, atomically: true, encoding: .utf8)
        let storage = LogStorageManager(rootURL: rootFile)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(true, forKey: "logger.masterEnabled")
        let service = LoggingService(storage: storage, configStore: LoggingConfigStore(defaults: defaults))

        await service.bootstrap()
        await service.startSessionFromUI(note: "unwritable")

        XCTAssertNil(service.activeSessionDisplayID)
        XCTAssertNotNil(service.lastLoggingError)
    }

    func testStartAndStop() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let mgr = SessionManager(storage: storage)
        let session = try await mgr.startSession(note: "trial")
        let active = await mgr.activeSessionID
        XCTAssertNotNil(active)
        try await mgr.stopSession()
        let after = await mgr.activeSessionID
        XCTAssertNil(after)

        // Verify ended_at written.
        let url = try storage.sessionSQLiteURL(session.id)
        let pool = try DatabasePool(path: url.path)
        let s = try await pool.read { try SensorLogSession.fetchOne($0) }
        XCTAssertNotNil(s?.endedAt)
    }

    func testResumeDetectsUnfinished() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let mgr1 = SessionManager(storage: storage)
        let s = try await mgr1.startSession(note: nil)
        // Simulate kill: don't call stop.
        let mgr2 = SessionManager(storage: storage)
        let unfinished = try await mgr2.unfinishedSessions()
        XCTAssertTrue(unfinished.contains { $0.id == s.id })
    }
}
