import SwiftUI

struct EnvironmentDashboardCards: View {
    @EnvironmentObject var env: EnvironmentSensorManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                BarometerDetailView()
            } label: {
                SensorCard(
                    title: "Barometer",
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
                    title: "Proximity",
                    icon: "sensor.tag.radiowaves.forward",
                    value: env.isProximityMonitoringEnabled ? (env.proximityState ? "Near" : "Far") : "",
                    unit: "",
                    color: .red,
                    isAvailable: env.isProximityMonitoringEnabled
                )
            }
            NavigationLink {
                LightDetailView()
            } label: {
                SensorCard(
                    title: "Screen Brightness",
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
