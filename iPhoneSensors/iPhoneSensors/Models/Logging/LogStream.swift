import Foundation
enum LogStream: String, Codable, CaseIterable, Sendable, Hashable {
    case continuous, session
    var localizationKey: String { "logger.stream.\(rawValue)" }
}
