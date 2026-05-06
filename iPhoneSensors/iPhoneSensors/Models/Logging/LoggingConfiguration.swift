import Foundation

enum PerStreamConfig: Codable, Equatable, Sendable {
    case off
    case on(format: LogFormat, intervalMs: Int, options: FormatOptions)

    var isOn: Bool { if case .on = self { return true } else { return false } }
}

struct LoggingConfiguration: Codable, Equatable, Sendable {
    var continuous: PerStreamConfig
    var session: PerStreamConfig
}

extension LoggingConfiguration {
    static func `default`(for id: SensorID) -> LoggingConfiguration {
        switch id {
        case .gps, .heading:
            return .init(continuous: .on(format: .jsonl, intervalMs: 60_000, options: .default),
                         session:    .on(format: .sqlite, intervalMs: 1000, options: .default))
        case .battery, .thermal, .lowPower, .network, .orientation, .pedometer, .motionActivity, .bluetoothState, .cellular:
            return .init(continuous: .on(format: .jsonl, intervalMs: 0, options: .default),
                         session:    .on(format: .sqlite, intervalMs: 0, options: .default))
        case .altimeter:
            return .init(continuous: .off,
                         session:    .on(format: .sqlite, intervalMs: 1000, options: .default))
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion:
            return .init(continuous: .off,
                         session:    .on(format: .sqlite, intervalMs: 100, options: .default))
        case .brightness, .disk, .uptime:
            return .init(continuous: .off,
                         session:    .on(format: .csv, intervalMs: 2000, options: .default))
        case .bluetoothScan:
            return .init(continuous: .off,
                         session:    .on(format: .jsonl, intervalMs: 0, options: .default))
        case .health:
            return .init(continuous: .off,
                         session:    .on(format: .csv, intervalMs: 0, options: .default))
        case .camera, .proximity, .audio, .torch:
            return .init(continuous: .off,
                         session:    .on(format: .jsonl, intervalMs: 0, options: .default))
        }
    }
}
