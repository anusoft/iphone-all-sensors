import SwiftUI

struct HeadingDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Text(locManager.t("section.compass"))
                        .font(.headline)
                    CompassView(heading: loc.trueHeading)
                        .frame(height: 200)
                    HStack(spacing: 24) {
                        VStack {
                            Text(locManager.t("label.trueHeading"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f°", loc.trueHeading))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        VStack {
                            Text(locManager.t("label.magneticHeading"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f°", loc.magneticHeading))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.trueHeading"), value: String(format: "%.1f°", loc.trueHeading), icon: "safari")
                    DataRow(label: locManager.t("label.magneticHeading"), value: String(format: "%.1f°", loc.magneticHeading), icon: "safari")
                    DataRow(label: locManager.t("label.headingAccuracy"), value: String(format: "%.1f°", loc.headingAccuracy), icon: "scope")
                    DataRow(label: locManager.t("label.direction"), value: cardinalDirection(loc.trueHeading), icon: "location.north")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.heading)
        .showOffEntry(sensorID: "02", accent: SO.headingAccent)
        .navigationTitle(locManager.t("sensor.compass"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }

    private func cardinalDirection(_ heading: Double) -> String {
        switch heading {
        case 0..<22.5, 337.5...360: return locManager.t("compass.north")
        case 22.5..<67.5: return locManager.t("compass.northeast")
        case 67.5..<112.5: return locManager.t("compass.east")
        case 112.5..<157.5: return locManager.t("compass.southeast")
        case 157.5..<202.5: return locManager.t("compass.south")
        case 202.5..<247.5: return locManager.t("compass.southwest")
        case 247.5..<292.5: return locManager.t("compass.west")
        case 292.5..<337.5: return locManager.t("compass.northwest")
        default: return locManager.t("compass.unknown")
        }
    }
}
