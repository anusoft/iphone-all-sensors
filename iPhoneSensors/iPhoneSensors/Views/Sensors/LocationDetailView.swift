import SwiftUI
import MapKit

struct LocationDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 8) {
                    LocationMapView(
                        coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                        horizontalAccuracy: loc.horizontalAccuracy,
                        course: loc.course
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text(locManager.t("label.latitude"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.latitude))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 28)

                        VStack(spacing: 2) {
                            Text(locManager.t("label.longitude"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.6f°", loc.longitude))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.position"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.latitude"), value: String(format: "%.6f°", loc.latitude), icon: "location")
                    DataRow(label: locManager.t("label.longitude"), value: String(format: "%.6f°", loc.longitude), icon: "location")
                    DataRow(label: locManager.t("label.altitude"), value: LocalizedDisplayValue.number("%.1f", loc.altitude, unitKey: "unit.meters", localization: locManager), icon: "altimeter")
                    DataRow(label: locManager.t("label.speed"), value: LocalizedDisplayValue.number("%.1f", loc.speed, unitKey: "unit.metersPerSecond", localization: locManager), icon: "speedometer")
                    DataRow(label: locManager.t("label.course"), value: String(format: "%.1f°", loc.course), icon: "safari")
                    Divider()
                    Text(locManager.t("section.accuracy"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.horizontal"), value: LocalizedDisplayValue.number("%.1f", loc.horizontalAccuracy, unitKey: "unit.meters", localization: locManager), icon: "scope")
                    DataRow(label: locManager.t("label.vertical"), value: LocalizedDisplayValue.number("%.1f", loc.verticalAccuracy, unitKey: "unit.meters", localization: locManager), icon: "scope")
                    Divider()
                    DataRow(label: locManager.t("label.authorization"), value: locManager.t(loc.authorizationDescriptionKey), icon: "lock.shield")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.gps)
        .showOffEntry(sensorID: "01", accent: SO.gpsAccent)
        .navigationTitle(locManager.t("sensor.gps"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
