import SwiftUI

struct AccelerometerDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        let mag = sqrt(motion.accX * motion.accX + motion.accY * motion.accY + motion.accZ * motion.accZ)
        ScrollView {
            VStack(spacing: 20) {
                ThreeAxisView(x: motion.accX, y: motion.accY, z: motion.accZ, title: "Accelerometer", unit: "G", color: .blue)

                VStack(spacing: 16) {
                    Text("Magnitude")
                        .font(.headline)
                    CircularGauge(value: mag, maxValue: 4, title: "Total G", unit: "G", color: .blue, size: 140)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "X-Axis", value: String(format: "%.4f G", motion.accX), icon: "arrow.left.and.right")
                    DataRow(label: "Y-Axis", value: String(format: "%.4f G", motion.accY), icon: "arrow.up.and.down")
                    DataRow(label: "Z-Axis", value: String(format: "%.4f G", motion.accZ), icon: "arrow.up")
                    Divider()
                    DataRow(label: "Magnitude", value: String(format: "%.4f G", mag), icon: "scope")
                    DataRow(label: "Status", value: motion.isAccelerometerAvailable ? "Active" : "Unavailable", icon: "checkmark.circle")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    Text("Axis Visualization")
                        .font(.headline)
                    AxisVisualization(x: motion.accX, y: motion.accY, z: motion.accZ)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Accelerometer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AxisVisualization: View {
    let x: Double
    let y: Double
    let z: Double

    var body: some View {
        HStack(spacing: 16) {
            AxisBar(label: "X", value: x, color: .red)
            AxisBar(label: "Y", value: y, color: .green)
            AxisBar(label: "Z", value: z, color: .blue)
        }
        .frame(height: 200)
    }
}

struct AxisBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            GeometryReader { geo in
                let height = geo.size.height
                let normalizedValue = min(max(value / 2.0, -1.0), 1.0)
                let barHeight = abs(normalizedValue) * height * 0.5

                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.7))
                        .frame(width: 24, height: barHeight)
                        .position(x: 12, y: normalizedValue >= 0 ? height / 2 - barHeight / 2 : height / 2 + barHeight / 2)
                }
            }
            Text(String(format: "%.3f", value))
                .font(.caption2)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}
