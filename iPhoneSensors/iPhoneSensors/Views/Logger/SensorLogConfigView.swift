import SwiftUI

struct SensorLogConfigView: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var cfg: LoggingConfiguration = LoggingConfiguration(continuous: .off, session: .off)

    var body: some View {
        Form {
            section(stream: .continuous, binding: $cfg.continuous,
                    title: localization.t("logger.stream.continuous"))
            section(stream: .session, binding: $cfg.session,
                    title: localization.t("logger.stream.session"))
            Section { Text(estimatedRate()).font(.caption).foregroundStyle(.secondary) }
        }
        .navigationTitle(localization.t(sensorID.localizationKey))
        .onAppear { cfg = loggingService.configStore.config(for: sensorID) }
        .onChange(of: cfg) { _, new in loggingService.configStore.set(new, for: sensorID) }
    }

    @ViewBuilder
    private func section(stream: LogStream, binding: Binding<PerStreamConfig>, title: String) -> some View {
        Section(header: Text(title)) {
            Toggle(isOn: Binding(
                get: { binding.wrappedValue.isOn },
                set: { on in
                    if on {
                        binding.wrappedValue = .on(format: .jsonl, intervalMs: max(0, sensorID.minIntervalMs), options: .default)
                    } else {
                        binding.wrappedValue = .off
                    }
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
                        Text($0 == 0 ? localization.t("logger.interval.everySample") : "\($0) ms").tag($0)
                    }
                }
            }
        }
    }

    private var intervalPresets: [Int] {
        let base = [0, 10, 50, 100, 250, 500, 1_000, 2_000, 5_000, 10_000, 30_000, 60_000]
        return base.filter { $0 == 0 || $0 >= sensorID.minIntervalMs }
    }
    private func estimatedRate() -> String {
        let perSample: Double = 200
        var perMin: Double = 0
        if case let .on(_, ms, _) = cfg.continuous { perMin += ms == 0 ? 60.0 : 60_000.0 / Double(ms) }
        if case let .on(_, ms, _) = cfg.session { perMin += ms == 0 ? 60.0 : 60_000.0 / Double(ms) }
        let kbPerMin = (perMin * perSample) / 1024.0
        return String(format: "≈ %.1f KB/min · %.1f MB/day", kbPerMin, kbPerMin * 60 * 24 / 1024)
    }
}
