import SwiftUI

import CoreHaptics

struct SurfaceLevelView: View {
    let roll: Double
    let pitch: Double
    @EnvironmentObject var locManager: LocalizationManager
    @State private var hapticEngine: CHHapticEngine?
    @State private var wasLevel = false

    var body: some View {
        let rollDeg = roll * 180 / .pi
        let pitchDeg = pitch * 180 / .pi
        let isLevel = abs(rollDeg) < 0.5 && abs(pitchDeg) < 0.5

        VStack(spacing: 12) {
            Text(locManager.t("level.title"))
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(isLevel ? Color.green.opacity(0.3) : Color.clear)
                    .frame(width: 120, height: 120)

                // Bubble
                let maxOffset: CGFloat = 50
                let xOffset = CGFloat(-pitchDeg / 10.0) * maxOffset
                let yOffset = CGFloat(rollDeg / 10.0) * maxOffset
                Circle()
                    .fill(isLevel ? Color.green : Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(x: max(min(xOffset, maxOffset), -maxOffset),
                            y: max(min(yOffset, maxOffset), -maxOffset))
                    .animation(.easeOut(duration: 0.1), value: roll)
            }
            .frame(width: 120, height: 120)

            HStack(spacing: 20) {
                Text("\(locManager.t("label.roll")): \(String(format: "%.1f°", rollDeg))")
                    .font(.caption)
                Text("\(locManager.t("label.pitch")): \(String(format: "%.1f°", pitchDeg))")
                    .font(.caption)
            }

            if isLevel {
                Text(locManager.t("level.levelAchieved"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .glassCard()
        .onAppear(perform: prepareHaptics)
        .onChange(of: isLevel) { _, level in
            if level && !wasLevel {
                triggerLevelHaptic()
            }
            wasLevel = level
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            appLog("[Haptics] Engine error: \(error)")
        }
    }

    private func triggerLevelHaptic() {
        guard let engine = hapticEngine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            appLog("[Haptics] Play error: \(error)")
        }
    }
}

struct DeviceMotionDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager
    @StateObject private var chartData = SensorChartData()
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
                ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 12) {
                    Text(locManager.t("section.attitude"))

                SensorChartView(chartData: chartData, title: locManager.t("section.attitude"), unit: locManager.t("unit.rad"))
                        .font(.headline)
                    HStack(spacing: 16) {
                        CircularGauge(value: motion.roll * 180 / .pi, maxValue: 180, title: locManager.t("label.roll"), unit: "°", color: .red, size: 100)
                        CircularGauge(value: motion.pitch * 180 / .pi, maxValue: 180, title: locManager.t("label.pitch"), unit: "°", color: .green, size: 100)
                        CircularGauge(value: motion.yaw * 180 / .pi, maxValue: 180, title: locManager.t("label.yaw"), unit: "°", color: .blue, size: 100)
                    }
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                        .rotation3DEffect(.degrees(motion.roll * 180 / .pi), axis: (x: 1, y: 0, z: 0))
                        .rotation3DEffect(.degrees(motion.pitch * 180 / .pi), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(motion.yaw * 180 / .pi), axis: (x: 0, y: 0, z: 1))
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.gravity"))
                        .font(.headline)
                    DataRow(label: "X", value: LocalizedDisplayValue.number("%.4f", motion.gravX, unitKey: "unit.g", localization: locManager), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: LocalizedDisplayValue.number("%.4f", motion.gravY, unitKey: "unit.g", localization: locManager), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: LocalizedDisplayValue.number("%.4f", motion.gravZ, unitKey: "unit.g", localization: locManager), icon: "arrow.up")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.userAcceleration"))
                        .font(.headline)
                    DataRow(label: "X", value: LocalizedDisplayValue.number("%.4f", motion.userAccX, unitKey: "unit.g", localization: locManager), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: LocalizedDisplayValue.number("%.4f", motion.userAccY, unitKey: "unit.g", localization: locManager), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: LocalizedDisplayValue.number("%.4f", motion.userAccZ, unitKey: "unit.g", localization: locManager), icon: "arrow.up")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.rotationRate"))
                        .font(.headline)
                    DataRow(label: "X", value: LocalizedDisplayValue.number("%.4f", motion.rotX, unitKey: "unit.rads", localization: locManager), icon: "arrow.left.and.right")
                    DataRow(label: "Y", value: LocalizedDisplayValue.number("%.4f", motion.rotY, unitKey: "unit.rads", localization: locManager), icon: "arrow.up.and.down")
                    DataRow(label: "Z", value: LocalizedDisplayValue.number("%.4f", motion.rotZ, unitKey: "unit.rads", localization: locManager), icon: "arrow.clockwise")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.quaternion"))
                        .font(.headline)
                    DataRow(label: "W", value: String(format: "%.4f", motion.quatW))
                    DataRow(label: "X", value: String(format: "%.4f", motion.quatX))
                    DataRow(label: "Y", value: String(format: "%.4f", motion.quatY))
                    DataRow(label: "Z", value: String(format: "%.4f", motion.quatZ))
                }
                .glassCard()

                // Surface Level
                SurfaceLevelView(roll: motion.roll, pitch: motion.pitch)
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.deviceMotion)
        .showOffEntry(sensorID: "06", accent: SO.motionAccent)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onChange(of: motion.roll) { _, _ in
            chartData.addPoint(x: motion.roll, y: motion.pitch, z: motion.yaw)
        }
        .navigationTitle(locManager.t("sensor.deviceMotion"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        exportURL = DataExportManager.shared.exportRecording(dataPoints: chartData.dataPoints, sensorName: "DeviceMotion", unit: locManager.t("unit.rad"), format: .csv)
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
