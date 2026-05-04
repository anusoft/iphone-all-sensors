import SwiftUI

struct DeviceMotionDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Attitude")
                        .font(.headline)
                    HStack(spacing: 16) {
                        CircularGauge(value: abs(motion.roll * 180 / .pi), maxValue: 180, title: "Roll", unit: "°", color: .red, size: 100)
                        CircularGauge(value: abs(motion.pitch * 180 / .pi), maxValue: 180, title: "Pitch", unit: "°", color: .green, size: 100)
                        CircularGauge(value: abs(motion.yaw * 180 / .pi), maxValue: 180, title: "Yaw", unit: "°", color: .blue, size: 100)
                    }
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .rotation3DEffect(.degrees(motion.roll * 180 / .pi), axis: (x: 1, y: 0, z: 0))
                        .rotation3DEffect(.degrees(motion.pitch * 180 / .pi), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(motion.yaw * 180 / .pi), axis: (x: 0, y: 0, z: 1))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Gravity")
                        .font(.headline)
                    DataRow(label: "X", value: String(format: "%.4f G", motion.gravX), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: String(format: "%.4f G", motion.gravY), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: String(format: "%.4f G", motion.gravZ), icon: "arrow.up")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("User Acceleration")
                        .font(.headline)
                    DataRow(label: "X", value: String(format: "%.4f G", motion.userAccX), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: String(format: "%.4f G", motion.userAccY), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: String(format: "%.4f G", motion.userAccZ), icon: "arrow.up")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Rotation Rate")
                        .font(.headline)
                    DataRow(label: "X", value: String(format: "%.4f rad/s", motion.rotX), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: String(format: "%.4f rad/s", motion.rotY), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: String(format: "%.4f rad/s", motion.rotZ), icon: "arrow.clockwise")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quaternion")
                        .font(.headline)
                    DataRow(label: "W", value: String(format: "%.4f", motion.quatW))
                    DataRow(label: "X", value: String(format: "%.4f", motion.quatX))
                    DataRow(label: "Y", value: String(format: "%.4f", motion.quatY))
                    DataRow(label: "Z", value: String(format: "%.4f", motion.quatZ))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Device Motion")
        .navigationBarTitleDisplayMode(.inline)
    }
}
