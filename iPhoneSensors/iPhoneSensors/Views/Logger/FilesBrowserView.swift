import SwiftUI
import UIKit

struct FilesBrowserView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var files: [FileItem] = []

    struct FileItem: Identifiable {
        let id: URL
        let url: URL
        let size: Int64
        let modified: Date
        var isDirectory: Bool { url.hasDirectoryPath }
    }

    var body: some View {
        List {
            ForEach(files) { item in
                HStack {
                    Image(systemName: item.isDirectory ? "folder" : "doc")
                    VStack(alignment: .leading) {
                        Text(item.url.lastPathComponent)
                            .font(.system(.body, design: .monospaced))
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button {
                        presentShare(for: item.url)
                    } label: {
                        Label(localization.t("button.share"), systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                    Button(role: .destructive) {
                        try? FileManager.default.removeItem(at: item.url)
                        load()
                    } label: {
                        Label(localization.t("dataviewer.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .onAppear { load() }
    }

    private func presentShare(for url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }

    private func load() {
        let root = loggingService.storage.rootURL
        guard let it = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else {
            files = []
            return
        }
        var out: [FileItem] = []
        for case let url as URL in it {
            let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            let mod = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            out.append(FileItem(id: url, url: url, size: size, modified: mod))
        }
        files = out.sorted { $0.modified > $1.modified }
    }
}
