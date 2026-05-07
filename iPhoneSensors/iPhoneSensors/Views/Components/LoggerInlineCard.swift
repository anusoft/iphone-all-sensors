import SwiftUI

/// Reusable inline card showing the current logger configuration for a
/// single sensor. Intended to be embedded near the top of per-sensor
/// detail views; not currently wired in (Phase 5 only ships the component).
struct LoggerInlineCard: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        let cfg = loggingService.configStore.config(for: sensorID)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "record.circle")
                Text(localization.t("logger.title")).font(.subheadline.bold())
                Spacer()
            }
            if cfg.continuous.isOn || cfg.session.isOn {
                if case let .on(format, ms, _) = cfg.continuous {
                    Text("Continuous: \(format.rawValue) @ \(ms)ms").font(.caption)
                }
                if case let .on(format, ms, _) = cfg.session {
                    Text("Session: \(format.rawValue) @ \(ms)ms").font(.caption)
                }
            } else {
                Text(localization.t("logger.inlineCard.notLogging"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            NavigationLink(destination: SensorLogConfigView(sensorID: sensorID)) {
                Text(localization.t("logger.inlineCard.configure")).font(.caption)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
