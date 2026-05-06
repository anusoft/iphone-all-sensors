import XCTest
@testable import iPhoneSensors

final class LogStorageRotationTests: XCTestCase {
    func testTotalBytesCountsRecursively() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let m = LogStorageManager(rootURL: tmp)
        let f = try m.continuousFileURL(for: .battery, format: .jsonl, day: Date())
        try Data(repeating: 0x41, count: 1024).write(to: f)
        XCTAssertEqual(m.totalBytes(), 1024)
    }
    func testEnforceCapDeletesOldestContinuousDay() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let m = LogStorageManager(rootURL: tmp)
        let day1 = m.dayDir(daysAgo: 5)
        let day2 = m.dayDir(daysAgo: 1)
        try? FileManager.default.createDirectory(at: day1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: day2, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 1000).write(to: day1.appendingPathComponent("a.jsonl"))
        try Data(repeating: 0, count: 1000).write(to: day2.appendingPathComponent("b.jsonl"))
        let _ = m.enforceCapDeletingContinuousIfOver(targetBytes: 500)
        XCTAssertFalse(FileManager.default.fileExists(atPath: day1.path))   // oldest gone
        XCTAssertTrue(FileManager.default.fileExists(atPath: day2.path))    // newer kept
    }
}
