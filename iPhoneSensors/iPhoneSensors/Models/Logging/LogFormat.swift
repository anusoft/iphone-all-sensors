import Foundation
enum LogFormat: String, Codable, CaseIterable, Sendable, Hashable {
    case sqlite, jsonl, csv
    var fileExtension: String { rawValue }
    var localizationKey: String { "logger.format.\(rawValue)" }
}
