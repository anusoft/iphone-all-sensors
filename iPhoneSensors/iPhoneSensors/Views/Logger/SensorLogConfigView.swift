import SwiftUI

struct SensorLogConfigView: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var cfg: LoggingConfiguration = LoggingConfiguration(continuous: .off, session: .off)

    var body: some View {
        Form {
            section(binding: $cfg.session, title: localization.t("logger.stream.session"))
            Section { Text(estimatedRate()).font(.caption).foregroundStyle(.secondary) }
            Section {
                Button(role: .destructive) {
                    let def = sanitized(LoggingConfiguration.default(for: sensorID))
                    cfg = def
                    loggingService.configStore.set(def, for: sensorID)
                } label: {
                    Label(localization.t("logger.resetSensor"), systemImage: "arrow.counterclockwise")
                }
                .disabled(cfg == sanitized(LoggingConfiguration.default(for: sensorID)))
            }
        }
        .navigationTitle(localization.t(sensorID.localizationKey))
        .onAppear {
            cfg = sanitized(loggingService.configStore.config(for: sensorID))
            loggingService.configStore.set(cfg, for: sensorID)
        }
        .onChange(of: cfg) { _, new in
            loggingService.configStore.set(sanitized(new), for: sensorID)
        }
    }

    @ViewBuilder
    private func section(binding: Binding<PerStreamConfig>, title: String) -> some View {
        Section(header: Text(title)) {
            Toggle(isOn: Binding(
                get: { binding.wrappedValue.isOn },
                set: { on in
                    // Enabling uses the sensor's curated default (format + interval),
                    // matching the inline card — not a hard-coded format.
                    binding.wrappedValue = on ? defaultSessionConfig() : .off
                })) { Text(localization.t("logger.enabled")) }

            if case let .on(format, ms, options) = binding.wrappedValue {
                Picker(localization.t("logger.format"),
                       selection: Binding(
                        get: { format },
                        set: { binding.wrappedValue = .on(format: $0, intervalMs: ms, options: options) })) {
                    ForEach(LogFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker(localization.t("logger.interval"),
                       selection: Binding(
                        get: { ms },
                        set: { binding.wrappedValue = .on(format: format, intervalMs: $0, options: options) })) {
                    ForEach(intervalPresets, id: \.self) {
                        Text(intervalLabel($0)).tag($0)
                    }
                }
            }
        }
    }

    private func defaultSessionConfig() -> PerStreamConfig {
        let session = LoggingConfiguration.default(for: sensorID).session
        // Defaults are all `.on`, but fall back defensively to a sane stream.
        if case .on = session { return session }
        return .on(format: .jsonl, intervalMs: sensorID.minIntervalMs, options: .default)
    }

    private func intervalLabel(_ ms: Int) -> String {
        ms == 0 ? localization.t("logger.interval.everySample") : LocalizedDisplayValue.number("%.0f", Double(ms), unitKey: "unit.ms", localization: localization)
    }

    private var intervalPresets: [Int] {
        let base = [0, 10, 50, 100, 250, 500, 1_000, 2_000, 5_000, 10_000, 30_000, 60_000]
        return base.filter { $0 == 0 || $0 >= sensorID.minIntervalMs }
    }
    private func sanitized(_ value: LoggingConfiguration) -> LoggingConfiguration {
        LoggingConfiguration(continuous: .off, session: value.session)
    }

    private func estimatedRate() -> String {
        let perSample: Double = 200
        var perMin: Double = 0
        if case let .on(_, ms, _) = cfg.session { perMin += ms == 0 ? 60.0 : 60_000.0 / Double(ms) }
        let kbPerMin = (perMin * perSample) / 1024.0
        return "≈ \(LocalizedDisplayValue.number("%.1f", kbPerMin, unitKey: "unit.kbPerMin", localization: localization)) · \(LocalizedDisplayValue.number("%.1f", kbPerMin * 60 * 24 / 1024, unitKey: "unit.mbPerDay", localization: localization))"
    }
}
