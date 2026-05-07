import SwiftUI

struct ProximityDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var env: EnvironmentSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .font(.system(size: 60))
                        .foregroundStyle(env.proximityState ? .red : .green)
                    Text(env.proximityState ? "Object Detected Nearby" : "No Object Nearby")
                        .font(.title2)
                        .fontWeight(.bold)
                    StatusBadge(text: env.proximityState ? "NEAR" : "FAR", color: env.proximityState ? .red : .green)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.proximityState"), value: env.proximityState ? locManager.t("value.near") : locManager.t("value.far"), icon: "sensor.tag.radiowaves.forward")
                    DataRow(label: locManager.t("label.monitoring"), value: env.isProximityMonitoringEnabled ? locManager.t("value.enabled") : locManager.t("value.disabled"), icon: "checkmark.circle")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Proximity Sensor")
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
