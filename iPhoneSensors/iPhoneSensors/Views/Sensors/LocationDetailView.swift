import SwiftUI

struct LocationDetailView: View {
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Coordinates")
                        .font(.headline)
                    HStack(spacing: 16) {
                        VStack {
                            Text("Latitude")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.latitude))
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        VStack {
                            Text("Longitude")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.longitude))
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Position")
                        .font(.headline)
                    DataRow(label: "Latitude", value: String(format: "%.6f°", loc.latitude), icon: "location")
                    DataRow(label: "Longitude", value: String(format: "%.6f°", loc.longitude), icon: "location")
                    DataRow(label: "Altitude", value: String(format: "%.1f m", loc.altitude), icon: "altimeter")
                    DataRow(label: "Speed", value: String(format: "%.1f m/s", loc.speed), icon: "speedometer")
                    DataRow(label: "Course", value: String(format: "%.1f°", loc.course), icon: "safari")
                    Divider()
                    Text("Accuracy")
                        .font(.headline)
                    DataRow(label: "Horizontal", value: String(format: "%.1f m", loc.horizontalAccuracy), icon: "scope")
                    DataRow(label: "Vertical", value: String(format: "%.1f m", loc.verticalAccuracy), icon: "scope")
                    Divider()
                    DataRow(label: "Authorization", value: loc.authorizationDescription, icon: "lock.shield")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("GPS Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}
