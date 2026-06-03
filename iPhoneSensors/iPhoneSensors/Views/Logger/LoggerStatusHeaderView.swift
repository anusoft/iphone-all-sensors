import SwiftUI

struct LoggerStatusHeaderView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    let elapsed: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: loggingService.activeSessionDisplayID != nil ? "record.circle.fill" : "circle")
                    .foregroundStyle(loggingService.activeSessionDisplayID != nil ? .red : .secondary)
                Text(loggingService.activeSessionDisplayID != nil
                     ? localization.t("logger.sessionRecording") + " " + format(elapsed)
                     : localization.t("logger.sessionIdle"))
            }
            ProgressView(value: storageRatio()) {
                Text(localization.t("logger.storage") + ": " + storageDescription())
            }
        }
        .font(.subheadline)
    }

    private func format(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func storageRatio() -> Double {
        let used = Double(loggingService.storage.totalBytes())
        let cap = Double(max(UserDefaults.standard.integer(forKey: "logger.storageCapMB"), 1024))
        return min(1.0, used / (cap * 1024 * 1024))
    }

    private func storageDescription() -> String {
        let used = ByteCountFormatter.string(fromByteCount: loggingService.storage.totalBytes(), countStyle: .file)
        let capMB = max(UserDefaults.standard.integer(forKey: "logger.storageCapMB"), 1024)
        return "\(used) / \(capMB) MB"
    }
}
