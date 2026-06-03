import Foundation
import Combine

@MainActor
final class LoggingConfigStore: ObservableObject {
    private let defaults: UserDefaults
    private let key = "loggingConfig.v1"
    @Published private(set) var version: Int = 0   // bumped on any mutation

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func config(for id: SensorID) -> LoggingConfiguration {
        guard let dict = decoded(),
              let raw = dict[id.rawValue] else { return sanitized(.default(for: id), id: id) }
        return sanitized(raw, id: id)
    }

    func set(_ cfg: LoggingConfiguration, for id: SensorID) {
        var dict = decoded() ?? [:]
        dict[id.rawValue] = sanitized(cfg, id: id)
        save(dict)
        version &+= 1
    }

    /// Apply configs for many sensors in a single write (one version bump,
    /// so SwiftUI observers refresh once for a batch action).
    func setMany(_ updates: [SensorID: LoggingConfiguration]) {
        guard !updates.isEmpty else { return }
        var dict = decoded() ?? [:]
        for (id, cfg) in updates { dict[id.rawValue] = sanitized(cfg, id: id) }
        save(dict)
        version &+= 1
    }

    /// Restore the curated defaults for the given sensors.
    func resetToDefaults(_ ids: [SensorID]) {
        setMany(Dictionary(uniqueKeysWithValues: ids.map { ($0, .default(for: $0)) }))
    }

    func all() -> [SensorID: LoggingConfiguration] {
        var out: [SensorID: LoggingConfiguration] = [:]
        for id in SensorID.allCases { out[id] = config(for: id) }
        return out
    }

    private func decoded() -> [String: LoggingConfiguration]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([String: LoggingConfiguration].self, from: data)
    }
    /// Force continuous off (continuous streams are not user-exposed) and
    /// clamp the session interval to the sensor's native minimum.
    private func sanitized(_ cfg: LoggingConfiguration, id: SensorID) -> LoggingConfiguration {
        LoggingConfiguration(continuous: .off, session: clampInterval(cfg.session, for: id))
    }
    /// Never allow an interval faster than the sensor's native sampling
    /// minimum. `0` ("every sample") is preserved as-is.
    private func clampInterval(_ stream: PerStreamConfig, for id: SensorID) -> PerStreamConfig {
        guard case let .on(format, ms, options) = stream else { return stream }
        let floor = id.minIntervalMs
        let clamped = (ms > 0 && ms < floor) ? floor : ms
        return .on(format: format, intervalMs: clamped, options: options)
    }
    private func save(_ dict: [String: LoggingConfiguration]) {
        if let data = try? JSONEncoder().encode(dict) { defaults.set(data, forKey: key) }
    }
}
