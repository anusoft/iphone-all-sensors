import SwiftUI

struct LocationDashboardCards: View {
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                LocationDetailView()
            } label: {
                SensorCard(
                    title: "GPS Location",
                    icon: "location.fill",
                    value: formatLocation(),
                    unit: "",
                    color: .green,
                    isAvailable: loc.isAuthorized
                )
            }
            NavigationLink {
                HeadingDetailView()
            } label: {
                SensorCard(
                    title: "Compass Heading",
                    icon: "safari",
                    value: loc.trueHeading > 0 ? String(format: "%.0f°", loc.trueHeading) : "",
                    unit: cardinalDirection(loc.trueHeading),
                    color: .mint,
                    isAvailable: loc.isAuthorized
                )
            }
        }
    }

    private func formatLocation() -> String {
        if loc.latitude == 0 && loc.longitude == 0 { return "" }
        return String(format: "%.4f, %.4f", loc.latitude, loc.longitude)
    }

    private func cardinalDirection(_ heading: Double) -> String {
        switch heading {
        case 0..<22.5, 337.5...360: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return ""
        }
    }
}
