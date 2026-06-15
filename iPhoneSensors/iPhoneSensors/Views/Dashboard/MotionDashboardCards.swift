import SwiftUI

struct MotionDashboardCards: View {
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        AdaptiveCardGrid(spacing: 10) {
            NavigationLink {
                AccelerometerDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.accelerometer"),
                    icon: "gyroscope",
                    value: formatAcc(),
                    unit: locManager.t("unit.g"),
                    color: .blue,
                    isAvailable: motion.isAccelerometerAvailable
                )
            }
            NavigationLink {
                GyroscopeDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.gyroscope"),
                    icon: "gyroscope",
                    value: formatGyro(),
                    unit: locManager.t("unit.rads"),
                    color: .indigo,
                    isAvailable: motion.isGyroscopeAvailable
                )
            }
            NavigationLink {
                MagnetometerDetailView()
            } label: {
                let total = sqrt(motion.magX * motion.magX + motion.magY * motion.magY + motion.magZ * motion.magZ)
                SensorCard(
                    title: locManager.t("sensor.magnetometer"),
                    icon: "sensor.tag.radiowaves.forward",
                    value: total > 0 ? String(format: "%.1f", total) : "",
                    unit: locManager.t("unit.ut"),
                    color: .purple,
                    isAvailable: motion.isMagnetometerAvailable
                )
            }
            NavigationLink {
                DeviceMotionDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.deviceMotion"),
                    icon: "rotate.3d",
                    value: formatDeviceMotion(),
                    unit: "",
                    color: .teal,
                    isAvailable: motion.isDeviceMotionAvailable
                )
            }
            NavigationLink {
                PedometerDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.pedometer"),
                    icon: "figure.walk",
                    value: motion.steps > 0 ? "\(motion.steps)" : "",
                    unit: locManager.t("unit.steps"),
                    color: .green,
                    isAvailable: motion.isPedometerAvailable
                )
            }
            NavigationLink {
                AltimeterDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.altimeter"),
                    icon: "altimeter",
                    value: motion.relativeAltitude != 0 ? String(format: "%.1f", motion.relativeAltitude) : "",
                    unit: locManager.t("unit.meters"),
                    color: .cyan,
                    isAvailable: motion.isAltimeterAvailable
                )
            }
            NavigationLink {
                ActivityDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.activity"),
                    icon: "figure.run",
                    value: motion.activityState != "activity.unknown" ? motion.activityState.split(separator: ", ").map { locManager.t(String($0)) }.joined(separator: ", ") : "",
                    unit: "",
                    color: .orange,
                    isAvailable: motion.isActivityAvailable
                )
            }
        }
    }

    private func formatAcc() -> String {
        let mag = sqrt(motion.accX * motion.accX + motion.accY * motion.accY + motion.accZ * motion.accZ)
        return mag > 0.01 ? String(format: "%.2f", mag) : ""
    }

    private func formatGyro() -> String {
        let mag = sqrt(motion.gyroX * motion.gyroX + motion.gyroY * motion.gyroY + motion.gyroZ * motion.gyroZ)
        return mag > 0.01 ? String(format: "%.2f", mag) : ""
    }

    private func formatDeviceMotion() -> String {
        if motion.roll == 0 && motion.pitch == 0 && motion.yaw == 0 { return "" }
        return String(format: "%.0f° %.0f° %.0f°", motion.roll * 180 / .pi, motion.pitch * 180 / .pi, motion.yaw * 180 / .pi)
    }
}
