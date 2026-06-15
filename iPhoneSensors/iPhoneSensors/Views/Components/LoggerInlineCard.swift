import SwiftUI

struct LoggerSessionControl: View {
    enum Style {
        case compact
        case fullWidth
    }

    var style: Style = .compact
    var startTitleKey = "logger.start"
    var stopTitleKey = "logger.stop"
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage(LoggingService.masterEnabledKey) private var masterEnabled = false

    private var isRecording: Bool {
        loggingService.activeSessionDisplayID != nil
    }

    var body: some View {
        Button {
            Task {
                if isRecording {
                    await loggingService.stopSessionFromUI()
                } else {
                    await loggingService.startSessionFromUI()
                }
            }
        } label: {
            Label(
                isRecording ? localization.t(stopTitleKey) : localization.t(startTitleKey),
                systemImage: isRecording ? "stop.fill" : "record.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: style == .fullWidth ? .infinity : nil)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(style == .fullWidth ? .large : .regular)
        .tint(isRecording ? .red : .blue)
        .disabled(!masterEnabled)
        .accessibilityHint(isRecording ? localization.t("logger.sessionControl.stopHint") : localization.t("logger.sessionControl.startHint"))
    }
}

struct AllSensorsLogSessionBar: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage(LoggingService.masterEnabledKey) private var masterEnabled = false

    private var isRecording: Bool {
        loggingService.activeSessionDisplayID != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRecording ? "waveform.circle.fill" : "record.circle")
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isRecording ? .red : (masterEnabled ? .blue : .secondary))
                .frame(width: 42, height: 42)
                .background(
                    (isRecording ? Color.red : Color.blue).opacity(masterEnabled ? 0.14 : 0.08),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(localization.t("tab.logger"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            LoggerSessionControl(
                startTitleKey: "logger.start",
                stopTitleKey: "logger.stop"
            )
        }
        .padding(12)
        .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)
    }

    private var statusText: String {
        if !masterEnabled { return localization.t("logger.master.disabledNote") }
        return isRecording ? localization.t("logger.sessionRecording") : localization.t("logger.sessionIdle")
    }
}

/// Reusable inline card showing the current logger configuration for a
/// single sensor. Intended to be embedded near the top of per-sensor
/// detail views.
struct LoggerInlineCard: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage(LoggingService.masterEnabledKey) private var masterEnabled = false
    @State private var cfg: LoggingConfiguration = LoggingConfiguration(continuous: .off, session: .off)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "record.circle")
                Text(localization.t("logger.inlineCard.title")).font(.subheadline.bold())
                Spacer()
            }

            if !masterEnabled {
                Text(localization.t("logger.master.disabledNote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
            Toggle(isOn: Binding(
                get: { cfg.session.isOn },
                set: { on in
                    cfg.session = on ? defaultSessionConfig() : .off
                    save()
                }
            )) {
                Text(localization.t("logger.enabled"))
                    .font(.subheadline)
            }

            if case let .on(format, ms, options) = cfg.session {
                Picker(localization.t("logger.format"), selection: Binding(
                    get: { format },
                    set: {
                        cfg.session = .on(format: $0, intervalMs: ms, options: options)
                        save()
                    }
                )) {
                    ForEach(LogFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                Picker(localization.t("logger.interval"), selection: Binding(
                    get: { ms },
                    set: {
                        cfg.session = .on(format: format, intervalMs: $0, options: options)
                        save()
                    }
                )) {
                    ForEach(intervalPresets, id: \.self) {
                        Text(intervalLabel($0)).tag($0)
                    }
                }
            } else {
                Text(localization.t("logger.inlineCard.notLogging"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            } // end master-enabled branch
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            cfg = sanitized(loggingService.configStore.config(for: sensorID))
            save()
        }
    }

    private var intervalPresets: [Int] {
        let base = [0, 10, 50, 100, 250, 500, 1_000, 2_000, 5_000, 10_000, 30_000, 60_000]
        return base.filter { $0 == 0 || $0 >= sensorID.minIntervalMs }
    }

    private func defaultSessionConfig() -> PerStreamConfig {
        LoggingConfiguration.default(for: sensorID).session
    }

    private func sanitized(_ value: LoggingConfiguration) -> LoggingConfiguration {
        LoggingConfiguration(continuous: .off, session: value.session)
    }

    private func save() {
        cfg.continuous = .off
        loggingService.configStore.set(cfg, for: sensorID)
    }

    private func intervalLabel(_ ms: Int) -> String {
        ms == 0 ? localization.t("logger.interval.everySample") : LocalizedDisplayValue.number("%.0f", Double(ms), unitKey: "unit.ms", localization: localization)
    }
}

private struct LoggerInlineCardModifier: ViewModifier {
    let sensorID: SensorID

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                LoggerInlineCard(sensorID: sensorID)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(.thinMaterial)
            }
    }
}

extension View {
    func loggerInlineCard(_ sensorID: SensorID) -> some View {
        modifier(LoggerInlineCardModifier(sensorID: sensorID))
    }
}
