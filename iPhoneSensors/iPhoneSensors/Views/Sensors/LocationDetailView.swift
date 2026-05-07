import SwiftUI

struct LocationDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(locManager.t("section.coordinates"))
                        .font(.headline)
                    HStack(spacing: 16) {
                        VStack {
                            Text(locManager.t("label.latitude"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.latitude))
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        VStack {
                            Text(locManager.t("label.longitude"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.longitude))
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.position"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.latitude"), value: String(format: "%.6f°", loc.latitude), icon: "location")
                    DataRow(label: locManager.t("label.longitude"), value: String(format: "%.6f°", loc.longitude), icon: "location")
                    DataRow(label: locManager.t("label.altitude"), value: String(format: "%.1f m", loc.altitude), icon: "altimeter")
                    DataRow(label: locManager.t("label.speed"), value: String(format: "%.1f m/s", loc.speed), icon: "speedometer")
                    DataRow(label: locManager.t("label.course"), value: String(format: "%.1f°", loc.course), icon: "safari")
                    Divider()
                    Text(locManager.t("section.accuracy"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.horizontal"), value: String(format: "%.1f m", loc.horizontalAccuracy), icon: "scope")
                    DataRow(label: locManager.t("label.vertical"), value: String(format: "%.1f m", loc.verticalAccuracy), icon: "scope")
                    Divider()
                    DataRow(label: locManager.t("label.authorization"), value: loc.authorizationDescription, icon: "lock.shield")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("GPS Location")
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
