import SwiftUI

struct BarometerDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager
    @StateObject private var chartData = SensorChartData()
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
                ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                HStack(spacing: 24) {
                    CircularGauge(value: motion.pressure, maxValue: 120, title: locManager.t("label.pressure"), unit: "kPa", color: .orange, size: 130)
                    CircularGauge(value: motion.relativeAltitude, maxValue: 500, title: locManager.t("label.altitude"), unit: "m", color: .cyan, size: 130)
                }
                .glassCard()

                SingleValueChartView(chartData: chartData, title: locManager.t("sensor.barometer"), unit: "kPa", color: .orange)

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.barometricPressure"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.pressure"), value: String(format: "%.2f kPa", motion.pressure), icon: "barometer")
                    DataRow(label: locManager.t("label.hectopascals"), value: String(format: "%.1f hPa", motion.pressure * 10), icon: "barometer")
                    DataRow(label: locManager.t("label.inchesHg"), value: String(format: "%.2f inHg", motion.pressure * 0.2953), icon: "barometer")
                    DataRow(label: locManager.t("label.millibars"), value: String(format: "%.1f mbar", motion.pressure * 10), icon: "barometer")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.altitude"))
                        .font(.headline)
                    DataRow(label: "Relative Altitude", value: String(format: "%.2f m", motion.relativeAltitude), icon: "altimeter")
                    DataRow(label: locManager.t("label.feet"), value: String(format: "%.1f ft", motion.relativeAltitude * 3.28084), icon: "ruler")
                }
                .glassCard()

                // Environmental Delta Tracking
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(locManager.t("barometer.trackSession"))
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            if motion.isBarometerTracking {
                                motion.stopBarometerTracking()
                            } else {
                                motion.startBarometerTracking()
                            }
                        }) {
                            Text(motion.isBarometerTracking ? locManager.t("barometer.stopSession") : locManager.t("barometer.trackSession"))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(motion.isBarometerTracking ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundStyle(motion.isBarometerTracking ? .red : .blue)
                                .clipShape(Capsule())
                        }
                    }
                    if motion.isBarometerTracking {
                        DataRow(label: locManager.t("barometer.baseline"), value: String(format: "%.2f kPa", motion.barometerBaseline), icon: "barometer")
                        DataRow(label: locManager.t("barometer.delta"), value: String(format: "%.3f kPa", motion.pressure - motion.barometerBaseline), icon: "arrow.up.arrow.down")
                        DataRow(label: locManager.t("barometer.elevationChange"), value: String(format: "%.1f m", motion.barometerElevationChange), icon: "altimeter")
                        DataRow(label: locManager.t("label.status"), value: locManager.t("barometer.trend.\(motion.barometerTrend)"), icon: "arrow.trending.up")
                        if !motion.barometerWeatherPrediction.isEmpty {
                            DataRow(label: "Weather", value: motion.barometerWeatherPrediction, icon: "cloud")
                        }
                    }
                }
                .padding()
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.altimeter)
        .showOffEntry(sensorID: "08", accent: SO.baroAccent)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: motion.pressure) { _, _ in
            chartData.addPoint(x: motion.pressure, y: motion.relativeAltitude, z: 0)
        }
        .navigationTitle(locManager.t("sensor.barometer"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        exportURL = DataExportManager.shared.exportRecording(dataPoints: chartData.dataPoints, sensorName: "Barometer", unit: "kPa", format: .csv)
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
