import Foundation
import Combine
import UIKit
import GRDB

@MainActor
final class LoggingService: ObservableObject {
    let storage: LogStorageManager
    let configStore: LoggingConfigStore
    let bus: SensorEventBus
    let coordinator: LoggingCoordinator
    let sessionManager: SessionManager

    /// Wall-clock at which the current session was started from the UI.
    /// Drives `sessionElapsed()` for the status header.
    @Published var sessionStartedAt: Date?

    /// Mirror of `sessionManager.activeSessionID` for SwiftUI binding.
    @Published var activeSessionDisplayID: UUID?

    init(storage: LogStorageManager? = nil,
         configStore: LoggingConfigStore? = nil) {
        let s = storage ?? LogStorageManager()
        let c = configStore ?? LoggingConfigStore()
        self.storage = s
        self.configStore = c
        self.bus = SensorEventBus()
        self.coordinator = LoggingCoordinator(storage: s, configStore: c)
        self.sessionManager = SessionManager(storage: s)
    }

    func bootstrap() async {
        AppDelegate.loggingService = self
        let coord = self.coordinator
        await bus.setIngest { sample in await coord.ingest(sample) }
        await coordinator.start()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.flush()
            }
        }
    }

    func attach(_ publisher: AnyPublisher<SensorSample, Never>) {
        bus.attach(publisher)
    }

    /// Wire the `SensorManager`'s throttle state into the coordinator.
    func attachThrottleSource(_ sensorManager: SensorManager) {
        sensorManager.loggingCoordinator = coordinator
    }

    /// Smoke helper for tests / preview.
    func enableContinuousAccelerometer() {
        configStore.set(LoggingConfiguration(
            continuous: .on(format: .jsonl, intervalMs: 100, options: .default),
            session: .off), for: .accelerometer)
    }

    func flush() async { await coordinator.flushAll() }
}

// MARK: - UI helpers (Logger tab)

extension LoggingService {
    /// Number of sensors with a continuous stream currently configured `on`.
    @MainActor
    func continuousActiveCount() -> Int {
        SensorID.allCases.filter { configStore.config(for: $0).continuous.isOn }.count
    }

    /// Seconds elapsed since the current session was started via the UI.
    /// Returns 0 when no session is active.
    @MainActor
    func sessionElapsed() -> TimeInterval {
        _sessionElapsed()
    }

    @MainActor
    func startSessionFromUI(note: String? = nil) async {
        try? await sessionManager.startSession(note: note)
        let id = await sessionManager.activeSessionID
        let pool = await sessionManager.activePool
        await coordinator.setActiveSession(id, pool: pool)
        sessionStartedAt = Date()
        activeSessionDisplayID = id
    }

    @MainActor
    func stopSessionFromUI() async {
        try? await sessionManager.stopSession()
        await coordinator.setActiveSession(nil, pool: nil)
        sessionStartedAt = nil
        activeSessionDisplayID = nil
    }

    @MainActor
    private func _sessionElapsed() -> TimeInterval {
        sessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0
    }

    /// Returns the on-disk folder URL for a session, suitable for sharing
    /// via `UIActivityViewController`. Returns `nil` if the directory cannot
    /// be resolved (e.g., the storage root is not writable).
    @MainActor
    func shareSession(_ id: UUID) -> URL? {
        try? storage.sessionDir(id)
    }

    /// Produce a sanitized copy of a session folder with all location data
    /// removed. The copy lives next to the original in `<sessionsRoot>/`,
    /// suffixed with `-stripped`. Returns the new folder URL on success.
    @MainActor
    func exportSessionStrippingLocation(_ id: UUID) async throws -> URL? {
        guard let src = try? storage.sessionDir(id) else { return nil }
        let dstName = "\(id.uuidString)-stripped"
        let dst = src.deletingLastPathComponent().appendingPathComponent(dstName, isDirectory: true)
        if FileManager.default.fileExists(atPath: dst.path) {
            try FileManager.default.removeItem(at: dst)
        }
        try FileManager.default.copyItem(at: src, to: dst)
        // Remove location-related flat files (jsonl/csv per-sensor outputs).
        if let contents = try? FileManager.default.contentsOfDirectory(at: dst, includingPropertiesForKeys: nil) {
            for url in contents {
                let name = url.lastPathComponent.lowercased()
                if name.contains("gps") || name.contains("heading") || name.contains("location") {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        // Strip location rows from log.sqlite.
        let dbURL = dst.appendingPathComponent("log.sqlite")
        if FileManager.default.fileExists(atPath: dbURL.path) {
            let pool = try DatabasePool(path: dbURL.path)
            try await pool.write { db in
                try db.execute(sql: "DELETE FROM entries WHERE sensor_id LIKE 'location.%'")
                try db.execute(sql: "VACUUM")
            }
        }
        return dst
    }
}
