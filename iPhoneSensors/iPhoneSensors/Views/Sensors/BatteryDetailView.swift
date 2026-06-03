import SwiftUI

struct BatteryDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: batteryIcon(level: sys.batteryLevel))
                        .font(.system(size: 60))
                        .foregroundStyle(batteryColor(level: sys.batteryLevel))
                    Text(String(format: "%.0f%%", sys.batteryLevel * 100))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    StatusBadge(text: locManager.t(sys.batteryStateKey), color: batteryColor(level: sys.batteryLevel))
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.level"), value: String(format: "%.0f%%", sys.batteryLevel * 100), icon: batteryIcon(level: sys.batteryLevel))
                    DataRow(label: locManager.t("label.state"), value: locManager.t(sys.batteryStateKey), icon: "bolt.fill")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.battery)
        .showOffEntry(sensorID: "11", accent: SO.battAccent)
        .navigationTitle(locManager.t("sensor.battery"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }

    private func batteryIcon(level: Float) -> String {
        switch level {
        case ..<0.1: return "battery.0"
        case ..<0.25: return "battery.25"
        case ..<0.5: return "battery.50"
        case ..<0.75: return "battery.75"
        default: return "battery.100"
        }
    }

    private func batteryColor(level: Float) -> Color {
        switch level {
        case ..<0.2: return .red
        case ..<0.5: return .orange
        default: return .green
        }
    }
}
