import Foundation

actor CSVLogWriter: LogWriter {
    private let url: URL
    private let options: FormatOptions
    private var handle: FileHandle?
    private var headerWritten = false
    private var buffer = Data()
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0

    init(url: URL, options: FormatOptions) {
        self.url = url
        self.options = options
    }

    func write(_ sample: SensorSample) async {
        if !headerWritten {
            let cols = ["wall_time","monotonic_ns","sensor_id","payload_kind"] + sample.payload.csvColumns
            appendLine(cols)
            headerWritten = true
        }
        let row = [
            String(sample.wallTime.timeIntervalSince1970),
            String(sample.monotonicNs),
            sample.sensorID.rawValue,
            sample.payload.kind
        ] + sample.payload.csvValues
        appendLine(row)
        entriesWritten += 1
        if buffer.count >= 64 * 1024 { await flush() }
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
        } catch { buffer.removeAll(keepingCapacity: true) }
    }

    func close() async {
        await flush()
        try? handle?.close()
        handle = nil
    }

    private func appendLine(_ fields: [String]) {
        let escaped = fields.map { escape($0) }.joined(separator: options.csvDelimiter)
        buffer.append(Data(escaped.utf8))
        buffer.append(0x0A)
    }

    private func escape(_ s: String) -> String {
        if s.contains(options.csvDelimiter) || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }
}
