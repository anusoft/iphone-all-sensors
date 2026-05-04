import SwiftUI

struct GyroscopeDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        let mag = sqrt(motion.gyroX * motion.gyroX + motion.gyroY * motion.gyroY + motion.gyroZ * motion.gyroZ)
        ScrollView {
            VStack(spacing: 20) {
                ThreeAxisView(x: motion.gyroX, y: motion.gyroY, z: motion.gyroZ, title: "Gyroscope", unit: "rad/s", color: .indigo)

                VStack(spacing: 16) {
                    Text("Rotation Rate")
                        .font(.headline)
                    CircularGauge(value: mag, maxValue: 10, title: "Total", unit: "rad/s", color: .indigo, size: 140)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "X (Roll)", value: String(format: "%.4f rad/s", motion.gyroX), icon: "arrow.left.and.right")
                    DataRow(label: "Y (Pitch)", value: String(format: "%.4f rad/s", motion.gyroY), icon: "arrow.up.and.down")
                    DataRow(label: "Z (Yaw)", value: String(format: "%.4f rad/s", motion.gyroZ), icon: "arrow.clockwise")
                    Divider()
                    DataRow(label: "Degrees/s (X)", value: String(format: "%.2f°/s", motion.gyroX * 180 / .pi), icon: "degreesign")
                    DataRow(label: "Degrees/s (Y)", value: String(format: "%.2f°/s", motion.gyroY * 180 / .pi), icon: "degreesign")
                    DataRow(label: "Degrees/s (Z)", value: String(format: "%.2f°/s", motion.gyroZ * 180 / .pi), icon: "degreesign")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    Text("3D Rotation")
                        .font(.headline)
                    RotationCube(roll: motion.gyroX, pitch: motion.gyroY, yaw: motion.gyroZ)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Gyroscope")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RotationCube: View {
    let roll: Double
    let pitch: Double
    let yaw: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.indigo.opacity(0.1))
                .frame(width: 160, height: 160)
            Image(systemName: "cube.transparent")
                .font(.system(size: 80))
                .foregroundStyle(.indigo)
                .rotation3DEffect(.degrees(roll * 180 / .pi), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(pitch * 180 / .pi), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(yaw * 180 / .pi), axis: (x: 0, y: 0, z: 1))
        }
    }
}
