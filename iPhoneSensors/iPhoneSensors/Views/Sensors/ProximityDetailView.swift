import SwiftUI

struct ProximityDetailView: View {
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
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "Proximity State", value: env.proximityState ? "Near" : "Far", icon: "sensor.tag.radiowaves.forward")
                    DataRow(label: "Monitoring", value: env.isProximityMonitoringEnabled ? "Enabled" : "Disabled", icon: "checkmark.circle")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Proximity Sensor")
        .navigationBarTitleDisplayMode(.inline)
    }
}
