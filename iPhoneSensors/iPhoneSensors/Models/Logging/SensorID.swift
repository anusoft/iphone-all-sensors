import Foundation

enum SensorCategory: String, Codable, CaseIterable {
    case motion, location, environment, system, connectivity, camera, health
}

enum SensorID: String, Codable, CaseIterable, Hashable, Sendable {
    case accelerometer   = "motion.accelerometer"
    case gyroscope       = "motion.gyroscope"
    case magnetometer    = "motion.magnetometer"
    case deviceMotion    = "motion.deviceMotion"
    case altimeter       = "motion.altimeter"
    case pedometer       = "motion.pedometer"
    case motionActivity  = "motion.activity"

    case gps             = "location.gps"
    case heading         = "location.heading"

    case proximity       = "environment.proximity"
    case brightness      = "environment.brightness"
    case torch           = "environment.torch"
    case audio           = "environment.audio"

    case battery         = "system.battery"
    case thermal         = "system.thermal"
    case lowPower        = "system.lowPower"
    case orientation     = "system.orientation"
    case disk            = "system.disk"
    case uptime          = "system.uptime"

    case bluetoothState  = "connectivity.bluetoothState"
    case bluetoothScan   = "connectivity.bluetoothScan"
    case network         = "connectivity.network"
    case cellular        = "connectivity.cellular"

    case camera          = "camera.snapshot"

    case health          = "health.metric"

    var category: SensorCategory {
        switch self {
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion,
             .altimeter, .pedometer, .motionActivity:                  return .motion
        case .gps, .heading:                                           return .location
        case .proximity, .brightness, .torch, .audio:                  return .environment
        case .battery, .thermal, .lowPower, .orientation, .disk, .uptime: return .system
        case .bluetoothState, .bluetoothScan, .network, .cellular:     return .connectivity
        case .camera:                                                  return .camera
        case .health:                                                  return .health
        }
    }

    /// Display name shown in the UI. Localized via key `sensor.<rawValue>`.
    var localizationKey: String { "sensor.\(rawValue)" }

    /// Best-known native interval in milliseconds. Used to clamp the
    /// user-configured interval (we never upsample).
    var minIntervalMs: Int {
        switch self {
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion: return 10  // 100 Hz hardware max
        case .altimeter:                                               return 1000
        case .gps, .heading:                                           return 1000
        case .disk, .uptime, .brightness:                              return 1000
        default:                                                       return 0   // event-driven
        }
    }
}
