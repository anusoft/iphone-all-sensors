import XCTest
@testable import iPhoneSensors

final class LogFormatTests: XCTestCase {
    func testFileExtensions() {
        XCTAssertEqual(LogFormat.jsonl.fileExtension, "jsonl")
        XCTAssertEqual(LogFormat.csv.fileExtension, "csv")
        XCTAssertEqual(LogFormat.sqlite.fileExtension, "sqlite")
    }
    func testFormatOptionsDefaults() {
        let opts = FormatOptions()
        XCTAssertEqual(opts.csvDelimiter, ",")
        XCTAssertEqual(opts.sqliteBatchSize, 100)
    }
    func testStreams() { XCTAssertEqual(Set(LogStream.allCases), [.continuous, .session]) }
}
