import SwiftUI

struct ProcessorDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: Double(sys.activeProcessorCount), maxValue: Double(sys.processorCount), title: locManager.t("label.activeCores"), unit: locManager.t("unit.cores"), color: .purple, size: 130)
                    CircularGauge(value: Double(sys.processorCount), maxValue: 10, title: locManager.t("label.totalCores"), unit: locManager.t("unit.cores"), color: .indigo, size: 130)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.totalCores"), value: "\(sys.processorCount)", icon: "cpu")
                    DataRow(label: locManager.t("label.activeCores"), value: "\(sys.activeProcessorCount)", icon: "cpu")
                    DataRow(label: locManager.t("label.uptime"), value: formatUptime(sys.systemUptime), icon: "clock")
                    DataRow(label: locManager.t("label.lowPowerMode"), value: sys.isLowPowerModeEnabled ? locManager.t("value.enabled") : locManager.t("value.disabled"), icon: "bolt.circle")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.uptime)
        .showOffEntry(sensorID: "15", accent: SO.cpuAccent)
        .navigationTitle(locManager.t("sensor.processor"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
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
