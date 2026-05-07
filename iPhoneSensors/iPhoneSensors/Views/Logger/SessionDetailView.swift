import SwiftUI
import GRDB
import UIKit

struct SessionDetailView: View {
    let item: SessionsListView.SessionListItem
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var perSensor: [PerSensorRow] = []
    @State private var showShare = false

    struct PerSensorRow: Identifiable {
        let id: String   // sensor_id
        let count: Int
    }

    var body: some View {
        Form {
            if let s = item.session {
                Section(header: Text(localization.t("dataviewer.session.metadata"))) {
                    Text("ID: \(s.id.uuidString)")
                        .font(.caption)
                        .textSelection(.enabled)
                    Text("Started: \(Date(timeIntervalSince1970: s.startedAt).description)")
                    if let e = s.endedAt {
                        Text("Ended: \(Date(timeIntervalSince1970: e).description)")
                    }
                    Text("Device: \(s.deviceModel) iOS \(s.osVersion)")
                    Text("App: \(s.appVersion)")
                    if let note = s.note, !note.isEmpty {
                        Text("Note: \(note)")
                    }
                }
            }
            Section(header: Text(localization.t("dataviewer.session.perSensor"))) {
                ForEach(perSensor) { row in
                    HStack {
                        Text(row.id).font(.system(.body, design: .monospaced))
                        Spacer()
                        Text("\(row.count)")
                    }
                }
            }
        }
        .navigationTitle(localization.t("dataviewer.session.title"))
        .toolbar {
            Button(action: { showShare = true }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(items: [item.dirURL])
        }
        .onAppear { loadPerSensor() }
    }

    private func loadPerSensor() {
        let dbURL = item.dirURL.appendingPathComponent("log.sqlite")
        guard FileManager.default.fileExists(atPath: dbURL.path),
              let pool = try? DatabasePool(path: dbURL.path) else { return }
        let rows = (try? pool.read { db in
            try Row.fetchAll(db, sql: "SELECT sensor_id, COUNT(*) AS c FROM entries GROUP BY sensor_id ORDER BY sensor_id")
        }) ?? []
        perSensor = rows.map { PerSensorRow(id: $0["sensor_id"] ?? "?", count: $0["c"] ?? 0) }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
