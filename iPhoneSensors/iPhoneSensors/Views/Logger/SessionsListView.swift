import SwiftUI
import GRDB

struct SessionsListView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var sessions: [SessionListItem] = []
    @State private var loading = false

    struct SessionListItem: Identifiable {
        let id: UUID
        let session: SensorLogSession?
        let entryCount: Int
        let bytes: Int64
        let dirURL: URL
    }

    var body: some View {
        List {
            if loading { ProgressView() }
            ForEach(sessions) { item in
                NavigationLink(destination: SessionDetailView(item: item)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.session?.note ?? String(item.id.uuidString.prefix(8)))
                            .font(.headline)
                        if let s = item.session {
                            HStack {
                                Text(formatDate(s.startedAt))
                                if let end = s.endedAt {
                                    Text("→")
                                    Text(formatDate(end))
                                } else {
                                    Text(localization.t("dataviewer.session.active"))
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.caption)
                        }
                        Text("\(item.entryCount) entries · \(ByteCountFormatter.string(fromByteCount: item.bytes, countStyle: .file))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        try? FileManager.default.removeItem(at: item.dirURL)
                        loadSessions()
                    } label: {
                        Label(localization.t("dataviewer.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .onAppear { loadSessions() }
    }

    private func formatDate(_ unix: Double) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: Date(timeIntervalSince1970: unix))
    }

    private func loadSessions() {
        loading = true
        let storage = loggingService.storage
        DispatchQueue.global(qos: .userInitiated).async {
            var out: [SessionListItem] = []
            if let root = try? storage.sessionsRoot(),
               let dirs = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
                for dir in dirs {
                    guard let id = UUID(uuidString: dir.lastPathComponent) else { continue }
                    let dbURL = dir.appendingPathComponent("log.sqlite")
                    var session: SensorLogSession?
                    var entryCount = 0
                    if FileManager.default.fileExists(atPath: dbURL.path),
                       let pool = try? DatabasePool(path: dbURL.path) {
                        session = try? pool.read { try SensorLogSession.fetchOne($0, key: id) }
                        entryCount = (try? pool.read { try SensorLogEntry.fetchCount($0) }) ?? 0
                    }
                    let bytes = sizeOfDirectory(dir)
                    out.append(SessionListItem(id: id, session: session, entryCount: entryCount, bytes: bytes, dirURL: dir))
                }
            }
            out.sort { ($0.session?.startedAt ?? 0) > ($1.session?.startedAt ?? 0) }
            DispatchQueue.main.async {
                self.sessions = out
                self.loading = false
            }
        }
    }

    private func sizeOfDirectory(_ url: URL) -> Int64 {
        guard let it = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in it {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
