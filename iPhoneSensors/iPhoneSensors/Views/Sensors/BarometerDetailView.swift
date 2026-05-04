import SwiftUI

struct BarometerDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: motion.pressure, maxValue: 120, title: "Pressure", unit: "kPa", color: .orange, size: 130)
                    CircularGauge(value: motion.relativeAltitude, maxValue: 100, title: "Altitude", unit: "m", color: .cyan, size: 130)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Barometric Pressure")
                        .font(.headline)
                    DataRow(label: "Pressure", value: String(format: "%.2f kPa", motion.pressure), icon: "barometer")
                    DataRow(label: "Hectopascals", value: String(format: "%.1f hPa", motion.pressure * 10), icon: "barometer")
                    DataRow(label: "Inches of Mercury", value: String(format: "%.2f inHg", motion.pressure * 0.2953), icon: "barometer")
                    DataRow(label: "Millibars", value: String(format: "%.1f mbar", motion.pressure * 10), icon: "barometer")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Altitude")
                        .font(.headline)
                    DataRow(label: "Relative Altitude", value: String(format: "%.2f m", motion.relativeAltitude), icon: "altimeter")
                    DataRow(label: "Feet", value: String(format: "%.1f ft", motion.relativeAltitude * 3.28084), icon: "ruler")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Barometer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
