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
                    HStack {
                        Button(action: { Task { await loggingService.startSessionFromUI() } }) {
                            Label(localization.t("logger.start"), systemImage: "record.circle.fill")
                        }
                        .disabled(loggingService.activeSessionDisplayID != nil)

                        Button(action: { Task { await loggingService.stopSessionFromUI() } }) {
                            Label(localization.t("logger.stop"), systemImage: "stop.fill")
                        }
                        .disabled(loggingService.activeSessionDisplayID == nil)
                    }
                }

                ForEach(SensorCategory.allCases, id: \.self) { cat in
                    Section(header: Text(localization.t("category.\(cat.rawValue)"))) {
                        ForEach(SensorID.allCases.filter { $0.category == cat }, id: \.self) { id in
                            NavigationLink(destination: Text(id.rawValue)) {
                                SensorRowConfigPreview(sensorID: id)
                            }
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
            .sheet(isPresented: $showingDataViewer) { Text("Data Viewer (Phase 4)") }
            .sheet(isPresented: $showingSettings) { Text("Settings (Phase 3.4)") }
        }
        .onAppear {
            sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
                Task { @MainActor in self.sessionElapsed = self.loggingService.sessionElapsed() }
            }
        }
        .onDisappear { sessionTimer?.cancel() }
    }
}

private struct SensorRowConfigPreview: View {
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
                    pill(stream: .continuous, cfg: cfg.continuous)
                    pill(stream: .session, cfg: cfg.session)
                }
                .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func pill(stream: LogStream, cfg: PerStreamConfig) -> some View {
        switch cfg {
        case .off:
            Text("\(stream.rawValue): off")
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
        case let .on(format, ms, _):
            Text("\(stream.rawValue): \(format.rawValue) @ \(ms == 0 ? "every" : "\(ms)ms")")
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(stream == .continuous ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
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
