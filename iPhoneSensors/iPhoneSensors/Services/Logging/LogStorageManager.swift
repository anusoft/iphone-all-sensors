import Foundation

final class LogStorageManager {
    let rootURL: URL
    private let fm = FileManager.default
    private let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()

    init(rootURL: URL? = nil) {
        if let rootURL { self.rootURL = rootURL }
        else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.rootURL = docs.appendingPathComponent("SensorLogs", isDirectory: true)
        }
    }

    func continuousDayDir(_ day: Date) throws -> URL {
        let url = rootURL
            .appendingPathComponent("continuous", isDirectory: true)
            .appendingPathComponent(dayFmt.string(from: day), isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func continuousFileURL(for id: SensorID, format: LogFormat, day: Date) throws -> URL {
        try continuousDayDir(day).appendingPathComponent("\(filename(for: id)).\(format.fileExtension)")
    }

    func continuousSQLiteURL() throws -> URL {
        let dir = rootURL.appendingPathComponent("continuous", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("continuous.sqlite")
    }

    func sessionsRoot() throws -> URL {
        let url = rootURL.appendingPathComponent("sessions", isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func sessionDir(_ id: UUID) throws -> URL {
        let url = try sessionsRoot().appendingPathComponent(id.uuidString, isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func sessionFileURL(_ id: UUID, sensor: SensorID, format: LogFormat, rotationIndex: Int = 0) throws -> URL {
        let suffix = rotationIndex == 0 ? "" : ".\(rotationIndex)"
        return try sessionDir(id).appendingPathComponent("\(filename(for: sensor))\(suffix).\(format.fileExtension)")
    }

    func sessionSQLiteURL(_ id: UUID) throws -> URL {
        try sessionDir(id).appendingPathComponent("log.sqlite")
    }

    private func filename(for id: SensorID) -> String {
        // "motion.accelerometer" -> "accelerometer"
        id.rawValue.split(separator: ".").last.map(String.init) ?? id.rawValue
    }
}

extension LogStorageManager {
    func totalBytes() -> Int64 {
        guard let it = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in it {
            if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { total += Int64(size) }
        }
        return total
    }

    func dayDir(daysAgo: Int, from now: Date = Date()) -> URL {
        let d = now.addingTimeInterval(TimeInterval(-daysAgo * 86_400))
        return rootURL.appendingPathComponent("continuous", isDirectory: true)
                      .appendingPathComponent(dayFmt.string(from: d), isDirectory: true)
    }

    /// Returns bytes deleted.
    @discardableResult
    func enforceCapDeletingContinuousIfOver(targetBytes: Int64) -> Int64 {
        let contDir = rootURL.appendingPathComponent("continuous", isDirectory: true)
        guard FileManager.default.fileExists(atPath: contDir.path) else { return 0 }
        let dirs = (try? FileManager.default.contentsOfDirectory(at: contDir, includingPropertiesForKeys: nil)) ?? []
        let dayDirs = dirs.filter { $0.hasDirectoryPath && $0.lastPathComponent != "continuous.sqlite" }
                          .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var deleted: Int64 = 0
        for dir in dayDirs {
            if totalBytes() <= targetBytes { break }
            let size = sizeOf(url: dir)
            try? FileManager.default.removeItem(at: dir)
            deleted += size
            // Delete only the oldest day per invocation; caller can re-invoke if still over cap.
            break
        }
        return deleted
    }

    func shouldRotateSessionFile(_ url: URL, atBytes limit: Int64 = 50 * 1024 * 1024) -> Bool {
        guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) else { return false }
        return Int64(size) >= limit
    }

    /// Recursively delete the entire continuous tree (used by "Clear all continuous" UI).
    func deleteContinuous() throws {
        let dir = rootURL.appendingPathComponent("continuous", isDirectory: true)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }

    private func sizeOf(url: URL) -> Int64 {
        if let it = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            var t: Int64 = 0
            for case let u as URL in it {
                if let s = (try? u.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { t += Int64(s) }
            }
            return t
        }
        return 0
    }
}
