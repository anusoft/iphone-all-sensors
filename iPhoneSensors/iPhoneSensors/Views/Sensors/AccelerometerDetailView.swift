import SwiftUI

struct AccelerometerDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager
    @StateObject private var chartData = SensorChartData()
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showRecordings = false
    @State private var isRecording = false

    var body: some View {
        let mag = sqrt(motion.accX * motion.accX + motion.accY * motion.accY + motion.accZ * motion.accZ)
        
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                ThreeAxisView(x: motion.accX, y: motion.accY, z: motion.accZ, title: locManager.t("sensor.accelerometer"), unit: "G", color: .blue)

                SensorChartView(chartData: chartData, title: locManager.t("sensor.accelerometer"), unit: "G")

                VStack(spacing: 16) {
                    Text(locManager.t("label.magnitude"))
                        .font(.headline)
                    CircularGauge(value: mag, maxValue: 4, title: locManager.t("label.totalG"), unit: "G", color: .blue, size: 140)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.xaxis"), value: String(format: "%.4f G", motion.accX), icon: "arrow.left.and.right")
                    DataRow(label: locManager.t("label.yaxis"), value: String(format: "%.4f G", motion.accY), icon: "arrow.up.and.down")
                    DataRow(label: locManager.t("label.zaxis"), value: String(format: "%.4f G", motion.accZ), icon: "arrow.up")
                    Divider()
                    DataRow(label: locManager.t("label.magnitude"), value: String(format: "%.4f G", mag), icon: "scope")
                    DataRow(label: locManager.t("label.status"), value: motion.isAccelerometerAvailable ? locManager.t("status.active") : locManager.t("status.unavailable"), icon: "checkmark.circle")
                }
                .glassCard()

                VStack(spacing: 12) {
                    Text(locManager.t("section.axisVisualization"))
                        .font(.headline)
                    AxisVisualization(x: motion.accX, y: motion.accY, z: motion.accZ)
                }
                .glassCard()

                SeismometerCard()
            }
        }
        .loggerInlineCard(.accelerometer)
        .showOffEntry(sensorID: "03", accent: SO.accelAccent)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: motion.accX) { _, _ in
            chartData.addPoint(x: motion.accX, y: motion.accY, z: motion.accZ)
        }
    }
}

/// Seismometer monitor card — toggle, threshold slider, and recent alarm history.
/// Extracted so the detail view's adaptive card grid reads as a clean list of cards.
struct SeismometerCard: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(locManager.t("seismometer.title"))
                    .font(.headline)
                Spacer()
                Toggle(locManager.t("seismometer.enable"), isOn: $motion.isSeismometerEnabled)
                    .onChange(of: motion.isSeismometerEnabled) { _, enabled in
                        if enabled {
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
                        }
                    }
            }
            if motion.isSeismometerEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(locManager.t("seismometer.threshold")): \(String(format: "%.1f", motion.seismometerThreshold)) G")
                        .font(.subheadline)
                    Slider(value: $motion.seismometerThreshold, in: 0.5...5.0, step: 0.1)
                    if !motion.seismometerAlarmHistory.isEmpty {
                        Text(locManager.t("seismometer.alarmHistory"))
                            .font(.subheadline)
                            .padding(.top, 4)
                        ForEach(motion.seismometerAlarmHistory.suffix(5).reversed()) { alarm in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("\(String(format: "%.2f", alarm.magnitude))G on \(alarm.axis)")
                                    .font(.caption)
                                Spacer()
                                Text(alarm.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text(locManager.t("seismometer.noAlarms"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .glassCard()
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
import SwiftUI

struct RecordingListView: View {
    @EnvironmentObject var recorder: SensorRecorder
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        List {
            if recorder.recordings.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "recordingtape")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text(locManager.t("record.noRecordings"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(recorder.recordings.sorted(by: { $0.startTime > $1.startTime })) { recording in
                    RecordingRow(recording: recording)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                recorder.deleteRecording(id: recording.id)
                            } label: {
                                Label(locManager.t("dataviewer.delete"), systemImage: "trash")
                            }

                            Button {
                                exportURL = recorder.exportRecording(id: recording.id, format: .csv)
                                showShareSheet = true
                            } label: {
                                Label(locManager.t("button.export"), systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .navigationTitle(locManager.t("label.recordings"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !recorder.recordings.isEmpty {
                    Button(action: {
                        recorder.deleteAllRecordings()
                    }) {
                        Text(locManager.t("button.clearAll"))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }
}

struct RecordingRow: View {
    let recording: SensorRecording
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.sensorName)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                
                Spacer()
                
                if recording.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text(locManager.t("record.recording"))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Label(formatDuration(recording.duration), systemImage: "clock")
                Label("\(recording.dataPoints.count) \(locManager.t("unit.points"))", systemImage: "chart.xyaxis.line")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(recording.startTime, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
