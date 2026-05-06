import Foundation
struct FormatOptions: Codable, Equatable, Sendable {
    var csvDelimiter: String = ","
    var sqliteBatchSize: Int = 100
    static let `default` = FormatOptions()
}
