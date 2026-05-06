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
              let raw = dict[id.rawValue] else { return .default(for: id) }
        return raw
    }

    func set(_ cfg: LoggingConfiguration, for id: SensorID) {
        var dict = decoded() ?? [:]
        dict[id.rawValue] = cfg
        save(dict)
        version &+= 1
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
    private func save(_ dict: [String: LoggingConfiguration]) {
        if let data = try? JSONEncoder().encode(dict) { defaults.set(data, forKey: key) }
    }
}
