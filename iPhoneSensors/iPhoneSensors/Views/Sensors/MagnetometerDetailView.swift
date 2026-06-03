import SwiftUI

struct MagnetometerDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var loc: LocationSensorManager
    @StateObject private var chartData = SensorChartData()
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        let totalMag = sqrt(motion.magX * motion.magX + motion.magY * motion.magY + motion.magZ * motion.magZ)
                ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                ThreeAxisView(x: motion.magX, y: motion.magY, z: motion.magZ, title: locManager.t("sensor.magnetometer"), unit: "µT", color: .purple)

                SensorChartView(chartData: chartData, title: locManager.t("sensor.magnetometer"), unit: "µT")

                VStack(spacing: 16) {
                    Text(locManager.t("section.fieldStrength"))
                        .font(.headline)
                    CircularGauge(value: totalMag, maxValue: 100, title: "Total Field", unit: "µT", color: .purple, size: 140)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.rawMagneticField"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.xaxis"), value: String(format: "%.2f µT", motion.magX), icon: "arrow.left.and.right")
                    DataRow(label: locManager.t("label.yaxis"), value: String(format: "%.2f µT", motion.magY), icon: "arrow.up.and.down")
                    DataRow(label: locManager.t("label.zaxis"), value: String(format: "%.2f µT", motion.magZ), icon: "arrow.up")
                    Divider()
                    Text(locManager.t("section.calibratedMagneticField"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.xaxis"), value: String(format: "%.2f µT", motion.calMagX), icon: "arrow.left.and.right")
                    DataRow(label: locManager.t("label.yaxis"), value: String(format: "%.2f µT", motion.calMagY), icon: "arrow.up.and.down")
                    DataRow(label: locManager.t("label.zaxis"), value: String(format: "%.2f µT", motion.calMagZ), icon: "arrow.up")
                    Divider()
                    DataRow(label: locManager.t("label.calibration"), value: locManager.t(motion.calMagAccuracy), icon: "checkmark.shield")
                }
                .glassCard()

                VStack(spacing: 12) {
                    Text(locManager.t("section.compass"))
                        .font(.headline)
                    CompassView(heading: loc.trueHeading)
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.magnetometer)
        .showOffEntry(sensorID: "05", accent: SO.magAccent)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: motion.magX) { _, _ in
            chartData.addPoint(x: motion.magX, y: motion.magY, z: motion.magZ)
        }
        .navigationTitle(locManager.t("sensor.magnetometer"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        exportURL = DataExportManager.shared.exportRecording(dataPoints: chartData.dataPoints, sensorName: "Magnetometer", unit: "µT", format: .csv)
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

struct CompassView: View {
    @EnvironmentObject var locManager: LocalizationManager
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
                Text(locManager.t("compass.n")).font(.system(size: 14, weight: .bold)).foregroundStyle(.red).offset(y: -50)
                Text(locManager.t("compass.e")).font(.system(size: 12, weight: .semibold)).offset(x: 50)
                Text(locManager.t("compass.s")).font(.system(size: 12, weight: .semibold)).offset(y: 50)
                Text(locManager.t("compass.w")).font(.system(size: 12, weight: .semibold)).offset(x: -50)
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
