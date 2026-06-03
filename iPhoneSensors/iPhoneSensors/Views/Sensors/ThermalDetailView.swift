import SwiftUI

struct ThermalDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 60))
                        .foregroundStyle(thermalColor(state: sys.thermalState))
                    Text(locManager.t(sys.thermalStateKey))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    StatusBadge(text: locManager.t(sys.thermalStateKey), color: thermalColor(state: sys.thermalState))
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("sensor.thermal"), value: locManager.t(sys.thermalStateKey), icon: "thermometer.medium")
                    DataRow(label: locManager.t("label.lowPowerMode"), value: sys.isLowPowerModeEnabled ? locManager.t("value.enabled") : locManager.t("value.disabled"), icon: "bolt.circle")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.thermal)
        .showOffEntry(sensorID: "12", accent: SO.thermAccent)
        .navigationTitle(locManager.t("sensor.thermal"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }

    private func thermalColor(state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}
