import SwiftUI
import UIKit

struct LogEntryDetailView: View {
    let entry: SensorLogEntry

    var body: some View {
        Form {
            Section {
                Text("Sensor: \(entry.sensorID)")
                Text("Kind: \(entry.payloadKind)")
                Text("Time: \(Date(timeIntervalSince1970: entry.wallTime).description)")
                Text("Mono ns: \(entry.monotonicNs)")
            }
            Section(header: Text("Payload")) {
                Text(prettyPrintJSON(entry.payloadJSON))
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            Section {
                Button("Copy JSON") {
                    UIPasteboard.general.string = entry.payloadJSON
                }
            }
        }
        .navigationTitle("Entry")
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
