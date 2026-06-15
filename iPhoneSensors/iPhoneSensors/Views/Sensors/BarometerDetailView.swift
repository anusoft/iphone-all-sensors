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
                    CircularGauge(value: motion.pressure, maxValue: 120, title: locManager.t("label.pressure"), unit: locManager.t("unit.kpa"), color: .orange, size: 130)
                    CircularGauge(value: motion.relativeAltitude, maxValue: 500, title: locManager.t("label.altitude"), unit: locManager.t("unit.meters"), color: .cyan, size: 130)
                }
                .glassCard()

                SingleValueChartView(chartData: chartData, title: locManager.t("sensor.barometer"), unit: locManager.t("unit.kpa"), color: .orange)

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.barometricPressure"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.pressure"), value: LocalizedDisplayValue.number("%.2f", motion.pressure, unitKey: "unit.kpa", localization: locManager), icon: "barometer")
                    DataRow(label: locManager.t("label.hectopascals"), value: LocalizedDisplayValue.number("%.1f", motion.pressure * 10, unitKey: "unit.hpa", localization: locManager), icon: "barometer")
                    DataRow(label: locManager.t("label.inchesHg"), value: LocalizedDisplayValue.number("%.2f", motion.pressure * 0.2953, unitKey: "unit.inhg", localization: locManager), icon: "barometer")
                    DataRow(label: locManager.t("label.millibars"), value: LocalizedDisplayValue.number("%.1f", motion.pressure * 10, unitKey: "unit.mbar", localization: locManager), icon: "barometer")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.altitude"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.relativeAltitude"), value: LocalizedDisplayValue.number("%.2f", motion.relativeAltitude, unitKey: "unit.meters", localization: locManager), icon: "altimeter")
                    DataRow(label: locManager.t("label.feet"), value: LocalizedDisplayValue.number("%.1f", motion.relativeAltitude * 3.28084, unitKey: "unit.feet", localization: locManager), icon: "ruler")
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
                        DataRow(label: locManager.t("barometer.baseline"), value: LocalizedDisplayValue.number("%.2f", motion.barometerBaseline, unitKey: "unit.kpa", localization: locManager), icon: "barometer")
                        DataRow(label: locManager.t("barometer.delta"), value: LocalizedDisplayValue.number("%.3f", motion.pressure - motion.barometerBaseline, unitKey: "unit.kpa", localization: locManager), icon: "arrow.up.arrow.down")
                        DataRow(label: locManager.t("barometer.elevationChange"), value: LocalizedDisplayValue.number("%.1f", motion.barometerElevationChange, unitKey: "unit.meters", localization: locManager), icon: "altimeter")
                        DataRow(label: locManager.t("label.status"), value: locManager.t("barometer.trend.\(motion.barometerTrend)"), icon: "arrow.trending.up")
                        if !motion.barometerWeatherPrediction.isEmpty {
                            DataRow(label: locManager.t("label.weather"), value: locManager.t(motion.barometerWeatherPrediction), icon: "cloud")
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
                        exportURL = DataExportManager.shared.exportRecording(dataPoints: chartData.dataPoints, sensorName: "Barometer", unit: locManager.t("unit.kpa"), format: .csv)
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
