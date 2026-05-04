import SwiftUI

struct MagnetometerDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        let totalMag = sqrt(motion.magX * motion.magX + motion.magY * motion.magY + motion.magZ * motion.magZ)
        ScrollView {
            VStack(spacing: 20) {
                ThreeAxisView(x: motion.magX, y: motion.magY, z: motion.magZ, title: "Magnetometer", unit: "µT", color: .purple)

                VStack(spacing: 16) {
                    Text("Field Strength")
                        .font(.headline)
                    CircularGauge(value: totalMag, maxValue: 100, title: "Total Field", unit: "µT", color: .purple, size: 140)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Raw Magnetic Field")
                        .font(.headline)
                    DataRow(label: "X-Axis", value: String(format: "%.2f µT", motion.magX), icon: "arrow.left.and.right")
                    DataRow(label: "Y-Axis", value: String(format: "%.2f µT", motion.magY), icon: "arrow.up.and.down")
                    DataRow(label: "Z-Axis", value: String(format: "%.2f µT", motion.magZ), icon: "arrow.up")
                    Divider()
                    Text("Calibrated Magnetic Field")
                        .font(.headline)
                    DataRow(label: "X-Axis", value: String(format: "%.2f µT", motion.calMagX), icon: "arrow.left.and.right")
                    DataRow(label: "Y-Axis", value: String(format: "%.2f µT", motion.calMagY), icon: "arrow.up.and.down")
                    DataRow(label: "Z-Axis", value: String(format: "%.2f µT", motion.calMagZ), icon: "arrow.up")
                    Divider()
                    DataRow(label: "Calibration", value: motion.calMagAccuracy, icon: "checkmark.shield")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    Text("Compass")
                        .font(.headline)
                    CompassView(heading: loc.trueHeading)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Magnetometer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CompassView: View {
    let heading: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            ZStack {
                ForEach(0..<72, id: \.self) { i in
                    Rectangle()
                        .fill(i % 18 == 0 ? Color.primary : i % 6 == 0 ? Color.gray.opacity(0.6) : Color.gray.opacity(0.3))
                        .frame(width: i % 18 == 0 ? 2 : 1, height: i % 18 == 0 ? 15 : i % 6 == 0 ? 10 : 5)
                        .offset(y: -70)
                }
                Text("N").font(.system(size: 14, weight: .bold)).foregroundStyle(.red).offset(y: -50)
                Text("E").font(.system(size: 12, weight: .semibold)).offset(x: 50)
                Text("S").font(.system(size: 12, weight: .semibold)).offset(y: 50)
                Text("W").font(.system(size: 12, weight: .semibold)).offset(x: -50)
            }
            .rotationEffect(.degrees(-heading))

            VStack(spacing: 0) {
                Image(systemName: "triangle.fill").font(.system(size: 16)).foregroundStyle(.red).rotationEffect(.degrees(180)).offset(y: -2)
                Image(systemName: "triangle.fill").font(.system(size: 16)).foregroundStyle(.gray).offset(y: 2)
            }
            .offset(y: -20)

            Circle().fill(Color.primary).frame(width: 8, height: 8)

            VStack {
                Spacer()
                Text(String(format: "%.0f°", heading)).font(.system(size: 16, weight: .bold, design: .monospaced))
                Text(cardinalDirection(heading)).font(.caption).foregroundStyle(.secondary)
            }
            .offset(y: 10)
        }
        .frame(width: 170, height: 170)
        .animation(.easeOut(duration: 0.2), value: heading)
    }

    private func cardinalDirection(_ h: Double) -> String {
        switch h {
        case 0..<22.5, 337.5...360: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return ""
        }
    }
}
