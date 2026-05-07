import SwiftUI
import Charts
import GRDB

private struct ChartPoint: Identifiable {
    let id = UUID()
    let time: Date
    let series: String
    let value: Double
}

struct SensorDataView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var sensorFilter: SensorID = .accelerometer
    @State private var sourcePool: SourceChoice = .continuous
    @State private var rows: [SensorLogEntry] = []
    @State private var page: Int = 0
    private let pageSize = 100

    enum SourceChoice: String, CaseIterable, Identifiable {
        case continuous, latestSession
        var id: String { rawValue }
    }

    var body: some View {
        VStack {
            HStack {
                Picker(localization.t("dataviewer.sensor"), selection: $sensorFilter) {
                    ForEach(SensorID.allCases, id: \.self) { id in
                        Text(id.rawValue).tag(id)
                    }
                }
                Picker(localization.t("dataviewer.source"), selection: $sourcePool) {
                    Text(localization.t("dataviewer.source.continuous")).tag(SourceChoice.continuous)
                    Text(localization.t("dataviewer.source.latestSession")).tag(SourceChoice.latestSession)
                }
            }
            .padding(.horizontal)

            List {
                let points = chartPoints(rows)
                if !points.isEmpty {
                    Chart(points) { p in
                        LineMark(x: .value("t", p.time), y: .value("v", p.value))
                            .foregroundStyle(by: .value("series", p.series))
                    }
                    .frame(height: 160)
                    .padding(.horizontal)
                }
                ForEach(rows, id: \.id) { row in
                    NavigationLink(destination: LogEntryDetailView(entry: row)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.payloadKind).font(.caption.bold())
                            Text(Date(timeIntervalSince1970: row.wallTime).description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(row.payloadJSON)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(2)
                        }
                    }
                }
                if !rows.isEmpty {
                    HStack {
                        Button("Prev") {
                            if page > 0 { page -= 1; reload() }
                        }
                        .disabled(page == 0)
                        Spacer()
                        Text("Page \(page + 1)")
                        Spacer()
                        Button("Next") {
                            page += 1
                            reload()
                        }
                        .disabled(rows.count < pageSize)
                    }
                }
            }
        }
        .onAppear { reload() }
        .onChange(of: sensorFilter) { _, _ in page = 0; reload() }
        .onChange(of: sourcePool) { _, _ in page = 0; reload() }
    }

    private func reload() {
        let storage = loggingService.storage
        let url: URL? = {
            switch sourcePool {
            case .continuous:
                return try? storage.continuousSQLiteURL()
            case .latestSession:
                guard let root = try? storage.sessionsRoot(),
                      let dirs = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
                    return nil
                }
                let sorted = dirs.sorted { $0.lastPathComponent > $1.lastPathComponent }
                return sorted.first?.appendingPathComponent("log.sqlite")
            }
        }()
        guard let url, FileManager.default.fileExists(atPath: url.path),
              let pool = try? DatabasePool(path: url.path) else {
            rows = []
            return
        }
        let sensor = sensorFilter.rawValue
        let offset = page * pageSize
        let pageSize = self.pageSize
        let fetched = (try? pool.read { db in
            try SensorLogEntry
                .filter(Column("sensor_id") == sensor)
                .order(Column("wall_time").desc)
                .limit(pageSize, offset: offset)
                .fetchAll(db)
        }) ?? []
        rows = fetched
    }

    private func chartPoints(_ rows: [SensorLogEntry]) -> [ChartPoint] {
        var out: [ChartPoint] = []
        for r in rows {
            guard let data = r.payloadJSON.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            let t = Date(timeIntervalSince1970: r.wallTime)
            // Try x/y/z first
            if let x = obj["x"] as? Double, let y = obj["y"] as? Double, let z = obj["z"] as? Double {
                out.append(.init(time: t, series: "x", value: x))
                out.append(.init(time: t, series: "y", value: y))
                out.append(.init(time: t, series: "z", value: z))
                continue
            }
            // Single-scalar
            for key in ["level", "relative", "pressure", "value", "rssi", "trueHeading", "magneticHeading", "alt"] {
                if let v = obj[key] as? Double {
                    out.append(.init(time: t, series: key, value: v))
                    break
                }
            }
        }
        return out
    }
}
