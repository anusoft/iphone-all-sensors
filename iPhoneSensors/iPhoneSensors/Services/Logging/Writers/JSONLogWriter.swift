import Foundation

actor JSONLogWriter: LogWriter {
    private let url: URL
    private var handle: FileHandle?
    private var buffer = Data()
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0
    private(set) var lastErrorMessage: String?
    var pendingBytes: Int { buffer.count }
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(url: URL) { self.url = url }

    func write(_ sample: SensorSample) async {
        do {
            let row = SerializedRow(
                t: sample.wallTime,
                m: sample.monotonicNs,
                s: sample.sensorID.rawValue,
                k: sample.payload.kind,
                p: sample.payload)
            var data = try encoder.encode(row)
            data.append(0x0A)   // newline
            buffer.append(data)
            entriesWritten += 1
            if buffer.count >= 64 * 1024 { await flush() }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func flush() async {
        guard !buffer.isEmpty else { return }
        do {
            if handle == nil {
                let fm = FileManager.default
                if !fm.fileExists(atPath: url.path) {
                    try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    fm.createFile(atPath: url.path, contents: nil)
                }
                handle = try FileHandle(forWritingTo: url)
                try handle?.seekToEnd()
            }
            try handle?.write(contentsOf: buffer)
            try handle?.synchronize()
            bytesWritten += Int64(buffer.count)
            buffer.removeAll(keepingCapacity: true)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func close() async {
        await flush()
        try? handle?.close()
        handle = nil
    }

    private struct SerializedRow: Codable {
        let t: Date; let m: UInt64; let s: String; let k: String; let p: SensorPayload
    }
}
