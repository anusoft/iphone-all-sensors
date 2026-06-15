import SwiftUI

struct GyroscopeDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager
    @StateObject private var chartData = SensorChartData()
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        let mag = sqrt(motion.gyroX * motion.gyroX + motion.gyroY * motion.gyroY + motion.gyroZ * motion.gyroZ)
                ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                ThreeAxisView(x: motion.gyroX, y: motion.gyroY, z: motion.gyroZ, title: locManager.t("sensor.gyroscope"), unit: locManager.t("unit.rads"), color: .indigo)

                SensorChartView(chartData: chartData, title: locManager.t("sensor.gyroscope"), unit: locManager.t("unit.rads"))

                VStack(spacing: 16) {
                    Text(locManager.t("section.rotationRate"))
                        .font(.headline)
                    CircularGauge(value: mag, maxValue: 10, title: locManager.t("label.total"), unit: locManager.t("unit.rads"), color: .indigo, size: 140)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.xroll"), value: LocalizedDisplayValue.number("%.4f", motion.gyroX, unitKey: "unit.rads", localization: locManager), icon: "arrow.left.and.right")
                    DataRow(label: locManager.t("label.ypitch"), value: LocalizedDisplayValue.number("%.4f", motion.gyroY, unitKey: "unit.rads", localization: locManager), icon: "arrow.up.and.down")
                    DataRow(label: locManager.t("label.zyaw"), value: LocalizedDisplayValue.number("%.4f", motion.gyroZ, unitKey: "unit.rads", localization: locManager), icon: "arrow.clockwise")
                    Divider()
                    DataRow(label: locManager.t("label.degreesPerSecondX"), value: LocalizedDisplayValue.numberNoSpace("%.2f", motion.gyroX * 180 / .pi, unitKey: "unit.degreesPerSecond", localization: locManager), icon: "degreesign")
                    DataRow(label: locManager.t("label.degreesPerSecondY"), value: LocalizedDisplayValue.numberNoSpace("%.2f", motion.gyroY * 180 / .pi, unitKey: "unit.degreesPerSecond", localization: locManager), icon: "degreesign")
                    DataRow(label: locManager.t("label.degreesPerSecondZ"), value: LocalizedDisplayValue.numberNoSpace("%.2f", motion.gyroZ * 180 / .pi, unitKey: "unit.degreesPerSecond", localization: locManager), icon: "degreesign")
                }
                .glassCard()

                VStack(spacing: 12) {
                    Text(locManager.t("section.3dRotation"))
                        .font(.headline)
                    RotationCube(roll: motion.gyroX, pitch: motion.gyroY, yaw: motion.gyroZ)
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.gyroscope)
        .showOffEntry(sensorID: "04", accent: SO.gyroAccent)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: motion.gyroX) { _, _ in
            chartData.addPoint(x: motion.gyroX, y: motion.gyroY, z: motion.gyroZ)
        }
        .navigationTitle(locManager.t("sensor.gyroscope"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        exportURL = DataExportManager.shared.exportRecording(dataPoints: chartData.dataPoints, sensorName: "Gyroscope", unit: locManager.t("unit.rads"), format: .csv)
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    SettingsToolbarButton()
                }
                }
            }
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
