import SwiftUI

struct PedometerDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: Double(motion.steps), maxValue: 10000, title: "Steps", unit: "steps", color: .green, size: 120)
                    CircularGauge(value: motion.distance, maxValue: 10000, title: "Distance", unit: "m", color: .blue, size: 120)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 12) {
                    StatBox(title: "Floors Up", value: "\(motion.floorsAscended)", icon: "arrow.up.circle.fill", color: .green)
                    StatBox(title: "Floors Down", value: "\(motion.floorsDescended)", icon: "arrow.down.circle.fill", color: .orange)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "Step Count", value: "\(motion.steps)", icon: "figure.walk")
                    DataRow(label: "Distance", value: String(format: "%.1f m", motion.distance), icon: "ruler")
                    DataRow(label: "Floors Ascended", value: "\(motion.floorsAscended)", icon: "arrow.up.circle")
                    DataRow(label: "Floors Descended", value: "\(motion.floorsDescended)", icon: "arrow.down.circle")
                    if motion.pace > 0 {
                        DataRow(label: "Current Pace", value: String(format: "%.2f s/m", motion.pace), icon: "timer")
                    }
                    if motion.cadence > 0 {
                        DataRow(label: "Cadence", value: String(format: "%.1f steps/s", motion.cadence), icon: "metronome")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pedometer")
        .navigationBarTitleDisplayMode(.inline)
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
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
