import XCTest
import Combine
@testable import iPhoneSensors

@MainActor
final class LoggingConfigStoreTests: XCTestCase {
    func makeIsolatedDefaults() throws -> UserDefaults {
        let suite = "test.\(UUID().uuidString)"
        let d = try XCTUnwrap(UserDefaults(suiteName: suite))
        d.removePersistentDomain(forName: suite)
        return d
    }
    func testReturnsAllOffForUnconfiguredSensor() throws {
        // Logging is opt-in: a sensor the user has never configured reports
        // fully off (not its curated default, which is only applied on enable).
        let store = LoggingConfigStore(defaults: try makeIsolatedDefaults())
        XCTAssertEqual(store.config(for: .gps), .allOff)
    }

    func testMasterSwitchDefaultsOff() throws {
        let store = LoggingConfigStore(defaults: try makeIsolatedDefaults())
        XCTAssertFalse(store.isLoggingEnabled)
    }
    func testRoundTripPersistence() throws {
        let d = try makeIsolatedDefaults()
        let s1 = LoggingConfigStore(defaults: d)
        var cfg = s1.config(for: .accelerometer)
        cfg.session = .on(format: .csv, intervalMs: 50, options: .default)
        s1.set(cfg, for: .accelerometer)
        let s2 = LoggingConfigStore(defaults: d)
        XCTAssertEqual(s2.config(for: .accelerometer), cfg)
    }
    func testPublishedChangesNotify() throws {
        let store = LoggingConfigStore(defaults: try makeIsolatedDefaults())
        let exp = expectation(description: "publish")
        let c = store.$version.dropFirst().sink { _ in exp.fulfill() }
        store.set(LoggingConfiguration(continuous: .off, session: .off), for: .battery)
        wait(for: [exp], timeout: 1.0)
        c.cancel()
    }
}
