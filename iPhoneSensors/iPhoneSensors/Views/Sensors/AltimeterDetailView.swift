import SwiftUI

struct AltimeterDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: motion.relativeAltitude, maxValue: 500, title: locManager.t("label.relativeAltitude"), unit: "m", color: .cyan, size: 130)
                    CircularGauge(value: motion.pressure, maxValue: 120, title: locManager.t("label.pressure"), unit: "kPa", color: .orange, size: 130)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.barometricData"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.relativeAltitude"), value: String(format: "%.2f m", motion.relativeAltitude), icon: "altimeter")
                    DataRow(label: locManager.t("label.pressure"), value: String(format: "%.2f kPa", motion.pressure), icon: "barometer")
                    Divider()
                    Text(locManager.t("section.conversions"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.feet"), value: String(format: "%.1f ft", motion.relativeAltitude * 3.28084), icon: "ruler")
                    DataRow(label: locManager.t("label.inchesHg"), value: String(format: "%.2f inHg", motion.pressure * 0.2953), icon: "barometer")
                    DataRow(label: locManager.t("label.millibars"), value: String(format: "%.1f mbar", motion.pressure * 10), icon: "barometer")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.altimeter)
        .showOffEntry(sensorID: "07", accent: SO.altAccent)
        .navigationTitle(locManager.t("sensor.altimeter"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
