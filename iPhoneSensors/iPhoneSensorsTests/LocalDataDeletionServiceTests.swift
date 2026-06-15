import XCTest
@testable import iPhoneSensors

final class LocalDataDeletionServiceTests: XCTestCase {
    private func makeTempRoot() throws -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("LocalDataDeletionServiceTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suite = "LocalDataDeletionServiceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return (defaults, suite)
    }

    func testDeletesGeneratedFilesButPreservesUnrelatedDocuments() throws {
        let root = try makeTempRoot()
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        let logRoot = documents.appendingPathComponent("Logging", isDirectory: true)
        let legacyLogRoot = documents.appendingPathComponent("SensorLogs", isDirectory: true)
        try FileManager.default.createDirectory(at: logRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: legacyLogRoot, withIntermediateDirectories: true)

        let exportedSensor = documents.appendingPathComponent("sensor_data_123.csv")
        let signalMap = documents.appendingPathComponent("signal_map_123.kml")
        let userDocument = documents.appendingPathComponent("notes.txt")
        let nestedLog = logRoot.appendingPathComponent("session.sqlite")
        let legacyLog = legacyLogRoot.appendingPathComponent("continuous.sqlite")
        try "sensor".write(to: exportedSensor, atomically: true, encoding: .utf8)
        try "signal".write(to: signalMap, atomically: true, encoding: .utf8)
        try "keep".write(to: userDocument, atomically: true, encoding: .utf8)
        try "log".write(to: nestedLog, atomically: true, encoding: .utf8)
        try "legacy".write(to: legacyLog, atomically: true, encoding: .utf8)

        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = LocalDataDeletionService(documentsURL: documents, defaults: defaults)

        let result = service.deleteLocalData()

        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: exportedSensor.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: signalMap.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: logRoot.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyLogRoot.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: userDocument.path))
    }

    func testClearsAppOwnedStateButPreservesConsentLanguageAndTheme() throws {
        let root = try makeTempRoot()
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(true, forKey: "logger.masterEnabled")
        defaults.set(2048, forKey: "logger.storageCapMB")
        defaults.set(true, forKey: "logger.disableAutoLockDuringSession")
        defaults.set(false, forKey: "logger.showExportWarning")
        defaults.set(Data([1, 2, 3]), forKey: "loggingConfig.v1")
        defaults.set(true, forKey: "healthAuthorizationRequested")
        defaults.set(true, forKey: "hasCompletedPermissionFlow")
        defaults.set(true, forKey: "hasSeenShowOffTutorial")
        defaults.set("hybrid", forKey: "gpsmap.style")
        defaults.set(true, forKey: "gpsmap.realistic")
        defaults.set(["alarm"], forKey: "seismometerAlarmHistory")
        defaults.set(1_234_567.0, forKey: "consentGivenAt")
        defaults.set(true, forKey: "consentAccepted")
        defaults.set("thai", forKey: "appLanguage")
        defaults.set("dark", forKey: "appTheme")

        let service = LocalDataDeletionService(documentsURL: documents, defaults: defaults)

        _ = service.deleteLocalData()

        XCTAssertFalse(defaults.bool(forKey: "logger.masterEnabled"))
        XCTAssertEqual(defaults.integer(forKey: "logger.storageCapMB"), 0)
        XCTAssertNil(defaults.object(forKey: "logger.disableAutoLockDuringSession"))
        XCTAssertNil(defaults.object(forKey: "logger.showExportWarning"))
        XCTAssertNil(defaults.data(forKey: "loggingConfig.v1"))
        XCTAssertFalse(defaults.bool(forKey: "healthAuthorizationRequested"))
        XCTAssertFalse(defaults.bool(forKey: "hasCompletedPermissionFlow"))
        XCTAssertFalse(defaults.bool(forKey: "hasSeenShowOffTutorial"))
        XCTAssertNil(defaults.string(forKey: "gpsmap.style"))
        XCTAssertNil(defaults.object(forKey: "gpsmap.realistic"))
        XCTAssertNil(defaults.object(forKey: "seismometerAlarmHistory"))
        XCTAssertEqual(defaults.double(forKey: "consentGivenAt"), 1_234_567.0)
        XCTAssertTrue(defaults.bool(forKey: "consentAccepted"))
        XCTAssertEqual(defaults.string(forKey: "appLanguage"), "thai")
        XCTAssertEqual(defaults.string(forKey: "appTheme"), "dark")
    }
}
