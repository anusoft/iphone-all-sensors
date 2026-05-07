import SwiftUI

struct DataViewerView: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var tab: DataViewerTab = .sessions

    enum DataViewerTab: String, CaseIterable, Identifiable {
        case sessions, sensor, files
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text(localization.t("dataviewer.tab.sessions")).tag(DataViewerTab.sessions)
                    Text(localization.t("dataviewer.tab.sensor")).tag(DataViewerTab.sensor)
                    Text(localization.t("dataviewer.tab.files")).tag(DataViewerTab.files)
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case .sessions: SessionsListView()
                case .sensor:   SensorDataView()
                case .files:    FilesBrowserView()
                }
            }
            .navigationTitle(localization.t("dataviewer.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.t("logger.settings.done")) { dismiss() }
                }
            }
        }
    }
}
