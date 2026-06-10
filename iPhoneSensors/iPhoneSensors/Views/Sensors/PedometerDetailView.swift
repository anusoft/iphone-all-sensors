import SwiftUI

struct PedometerDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: Double(motion.steps), maxValue: 10000, title: locManager.t("label.steps"), unit: "steps", color: .green, size: 120)
                    CircularGauge(value: motion.distance, maxValue: 10000, title: locManager.t("label.distance"), unit: "m", color: .blue, size: 120)
                }
                .glassCard()

                HStack(spacing: 12) {
                    StatBox(title: locManager.t("label.floorsUp"), value: "\(motion.floorsAscended)", icon: "arrow.up.circle.fill", color: .green)
                    StatBox(title: locManager.t("label.floorsDown"), value: "\(motion.floorsDescended)", icon: "arrow.down.circle.fill", color: .orange)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.stepCount"), value: "\(motion.steps)", icon: "figure.walk")
                    DataRow(label: locManager.t("label.distance"), value: String(format: "%.1f m", motion.distance), icon: "ruler")
                    DataRow(label: locManager.t("label.floorsAscended"), value: "\(motion.floorsAscended)", icon: "arrow.up.circle")
                    DataRow(label: locManager.t("label.floorsDescended"), value: "\(motion.floorsDescended)", icon: "arrow.down.circle")
                    if motion.pace > 0 {
                        DataRow(label: locManager.t("label.currentPace"), value: String(format: "%.2f s/m", motion.pace), icon: "timer")
                    }
                    if motion.cadence > 0 {
                        DataRow(label: locManager.t("label.cadence"), value: String(format: "%.1f steps/s", motion.cadence), icon: "metronome")
                    }
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.pedometer)
        .showOffEntry(sensorID: "09", accent: SO.pedAccent)
        .navigationTitle(locManager.t("sensor.pedometer"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 12)
    }
}
