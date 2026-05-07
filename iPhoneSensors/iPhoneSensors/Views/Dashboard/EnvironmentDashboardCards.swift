import SwiftUI

struct EnvironmentDashboardCards: View {
    @EnvironmentObject var env: EnvironmentSensorManager
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                BarometerDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.barometer"),
                    icon: "barometer",
                    value: env.pressure > 0 ? String(format: "%.1f", env.pressure) : "",
                    unit: "kPa",
                    color: .orange,
                    isAvailable: env.isAltimeterAvailable
                )
            }
            NavigationLink {
                ProximityDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.proximity"),
                    icon: "sensor.tag.radiowaves.forward",
                    value: env.isProximityMonitoringEnabled ? (env.proximityState ? locManager.t("value.near") : locManager.t("value.far")) : "",
                    unit: "",
                    color: .red,
                    isAvailable: env.isProximityMonitoringEnabled
                )
            }
            NavigationLink {
                LightDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.brightness"),
                    icon: "sun.max.fill",
                    value: String(format: "%.0f%%", env.screenBrightness * 100),
                    unit: "",
                    color: .yellow,
                    isAvailable: true
                )
            }
        }
    }
}
