import XCTest
@testable import iPhoneSensors

final class LogStoragePathsTests: XCTestCase {
    func makeMgr() -> LogStorageManager {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        return LogStorageManager(rootURL: tmp)
    }
    func testRootCreatedOnDemand() throws {
        let m = makeMgr()
        let url = try m.continuousFileURL(for: .battery, format: .jsonl, day: Date())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
        XCTAssertEqual(url.pathExtension, "jsonl")
    }
    func testSessionDirHasUUID() throws {
        let m = makeMgr()
        let id = UUID()
        let url = try m.sessionDir(id)
        XCTAssertTrue(url.path.contains(id.uuidString))
    }
}
