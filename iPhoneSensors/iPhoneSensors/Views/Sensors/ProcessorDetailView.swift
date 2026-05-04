import SwiftUI

struct ProcessorDetailView: View {
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: Double(sys.activeProcessorCount), maxValue: Double(sys.processorCount), title: "Active Cores", unit: "cores", color: .purple, size: 130)
                    CircularGauge(value: Double(sys.processorCount), maxValue: 10, title: "Total Cores", unit: "cores", color: .indigo, size: 130)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Processor Info")
                        .font(.headline)
                    DataRow(label: "Total Cores", value: "\(sys.processorCount)", icon: "cpu")
                    DataRow(label: "Active Cores", value: "\(sys.activeProcessorCount)", icon: "cpu")
                    DataRow(label: "Uptime", value: formatUptime(sys.systemUptime), icon: "clock")
                    DataRow(label: "Low Power Mode", value: sys.isLowPowerModeEnabled ? "Enabled" : "Disabled", icon: "bolt.circle")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Processor")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatUptime(_ uptime: TimeInterval) -> String {
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
