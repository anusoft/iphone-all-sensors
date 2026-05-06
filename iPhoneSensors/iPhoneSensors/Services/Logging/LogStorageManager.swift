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
