import SwiftUI
import Combine

struct LoggerOverviewView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var sessionElapsed: TimeInterval = 0
    @State private var sessionTimer: AnyCancellable?
    @State private var showingDataViewer = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LoggerStatusHeaderView(elapsed: sessionElapsed)
                    LoggerSessionControl(style: .fullWidth)
                }

                Section(header: Text(localization.t("logger.bulk.section"))) {
                    HStack {
                        Label(localization.t("logger.bulk.allSensors"), systemImage: "square.stack.3d.up.fill")
                        Spacer()
                        Text("\(loggingService.sessionEnabledCount(in: SensorID.allCases))/\(SensorID.allCases.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        LoggerBulkActionMenu(ids: SensorID.allCases)
                    }
                }

                ForEach(SensorCategory.allCases, id: \.self) { cat in
                    let ids = SensorID.allCases.filter { $0.category == cat }
                    Section {
                        ForEach(ids, id: \.self) { id in
                            NavigationLink(destination: SensorLogConfigView(sensorID: id)) {
                                SensorRowConfigPreview(sensorID: id)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    loggingService.resetToDefaults([id])
                                } label: {
                                    Label(localization.t("logger.resetSensor"), systemImage: "arrow.counterclockwise")
                                }
                                .tint(.orange)
                            }
                        }
                    } header: {
                        HStack {
                            Text(localization.t("category.\(cat.rawValue)"))
                            Spacer()
                            LoggerBulkActionMenu(ids: ids)
                        }
                    }
                }
            }
            .navigationTitle(localization.t("logger.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingDataViewer = true }) {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingDataViewer) { DataViewerView() }
            .sheet(isPresented: $showingSettings) { LoggerSettingsView() }
        }
        .onAppear {
            sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
                Task { @MainActor in self.sessionElapsed = self.loggingService.sessionElapsed() }
            }
        }
        .onDisappear { sessionTimer?.cancel() }
    }
}

/// Bulk-action menu applied to a set of sensors (all sensors, or one
/// category). Enables/disables, sets format/interval, or resets to defaults
/// in a single store write.
struct LoggerBulkActionMenu: View {
    let ids: [SensorID]
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager

    private let bulkIntervals = [0, 100, 250, 500, 1_000, 2_000, 5_000]

    var body: some View {
        Menu {
            Button {
                loggingService.setSessionEnabled(true, for: ids)
            } label: {
                Label(localization.t("logger.bulk.enableAll"), systemImage: "checkmark.circle")
            }
            Button {
                loggingService.setSessionEnabled(false, for: ids)
            } label: {
                Label(localization.t("logger.bulk.disableAll"), systemImage: "xmark.circle")
            }

            Menu {
                ForEach(LogFormat.allCases, id: \.self) { fmt in
                    Button(localization.t(fmt.localizationKey)) {
                        loggingService.setSessionFormat(fmt, for: ids)
                    }
                }
            } label: {
                Label(localization.t("logger.bulk.setFormat"), systemImage: "doc.badge.gearshape")
            }

            Menu {
                ForEach(bulkIntervals, id: \.self) { ms in
                    Button(ms == 0 ? localization.t("logger.interval.everySample") : "\(ms) ms") {
                        loggingService.setSessionInterval(ms, for: ids)
                    }
                }
            } label: {
                Label(localization.t("logger.bulk.setInterval"), systemImage: "timer")
            }

            Divider()

            Button(role: .destructive) {
                loggingService.resetToDefaults(ids)
            } label: {
                Label(localization.t("logger.bulk.reset"), systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
        }
        .accessibilityLabel(localization.t("logger.bulk.section"))
    }
}

struct SensorRowConfigPreview: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack {
            Image(systemName: iconName(for: sensorID))
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.t(sensorID.localizationKey))
                let cfg = loggingService.configStore.config(for: sensorID)
                HStack(spacing: 6) {
                    pill(cfg: cfg.session)
                }
                .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func pill(cfg: PerStreamConfig) -> some View {
        switch cfg {
        case .off:
            Text(localization.t("logger.sessionOff"))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        case let .on(format, ms, _):
            Text("\(format.rawValue) @ \(ms == 0 ? localization.t("logger.interval.everySample") : "\(ms)ms")")
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .clipShape(Capsule())
        }
    }

    private func iconName(for id: SensorID) -> String {
        switch id.category {
        case .motion:       return "gyroscope"
        case .location:     return "location"
        case .environment:  return "leaf"
        case .system:       return "cpu"
        case .connectivity: return "wifi"
        case .camera:       return "camera"
        case .health:       return "heart"
        }
    }
}
