import SwiftUI

struct AltimeterDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: motion.relativeAltitude, maxValue: 500, title: locManager.t("label.relativeAltitude"), unit: locManager.t("unit.meters"), color: .cyan, size: 130)
                    CircularGauge(value: motion.pressure, maxValue: 120, title: locManager.t("label.pressure"), unit: locManager.t("unit.kpa"), color: .orange, size: 130)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.barometricData"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.relativeAltitude"), value: LocalizedDisplayValue.number("%.2f", motion.relativeAltitude, unitKey: "unit.meters", localization: locManager), icon: "altimeter")
                    DataRow(label: locManager.t("label.pressure"), value: LocalizedDisplayValue.number("%.2f", motion.pressure, unitKey: "unit.kpa", localization: locManager), icon: "barometer")
                    Divider()
                    Text(locManager.t("section.conversions"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.feet"), value: LocalizedDisplayValue.number("%.1f", motion.relativeAltitude * 3.28084, unitKey: "unit.feet", localization: locManager), icon: "ruler")
                    DataRow(label: locManager.t("label.inchesHg"), value: LocalizedDisplayValue.number("%.2f", motion.pressure * 0.2953, unitKey: "unit.inhg", localization: locManager), icon: "barometer")
                    DataRow(label: locManager.t("label.millibars"), value: LocalizedDisplayValue.number("%.1f", motion.pressure * 10, unitKey: "unit.mbar", localization: locManager), icon: "barometer")
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
