import SwiftUI
import UIKit

struct LogEntryDetailView: View {
    let entry: SensorLogEntry
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        Form {
            Section {
                Text("\(localization.t("dataviewer.sensor")): \(entry.sensorID)")
                Text("\(localization.t("dataviewer.entry.kind")): \(entry.payloadKind)")
                Text("\(localization.t("dataviewer.entry.time")): \(Date(timeIntervalSince1970: entry.wallTime).description)")
                Text("\(localization.t("dataviewer.entry.monotonicNs")): \(entry.monotonicNs)")
            }
            Section(header: Text(localization.t("dataviewer.entry.payload"))) {
                Text(prettyPrintJSON(entry.payloadJSON))
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            Section {
                Button(localization.t("dataviewer.entry.copyJSON")) {
                    UIPasteboard.general.string = entry.payloadJSON
                }
            }
        }
        .navigationTitle(localization.t("dataviewer.entry.title"))
    }

    private func prettyPrintJSON(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: pretty, encoding: .utf8) else {
            return raw
        }
        return s
    }
}
