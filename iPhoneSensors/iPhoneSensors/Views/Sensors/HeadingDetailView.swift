import SwiftUI

struct HeadingDetailView: View {
    @EnvironmentObject var loc: LocationSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Compass")
                        .font(.headline)
                    CompassView(heading: loc.trueHeading)
                        .frame(height: 200)
                    HStack(spacing: 24) {
                        VStack {
                            Text("True Heading")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f°", loc.trueHeading))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        VStack {
                            Text("Magnetic Heading")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f°", loc.magneticHeading))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "True Heading", value: String(format: "%.1f°", loc.trueHeading), icon: "safari")
                    DataRow(label: "Magnetic Heading", value: String(format: "%.1f°", loc.magneticHeading), icon: "safari")
                    DataRow(label: "Heading Accuracy", value: String(format: "%.1f°", loc.headingAccuracy), icon: "scope")
                    DataRow(label: "Direction", value: cardinalDirection(loc.trueHeading), icon: "location.north")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cardinalDirection(_ heading: Double) -> String {
        switch heading {
        case 0..<22.5, 337.5...360: return "North"
        case 22.5..<67.5: return "Northeast"
        case 67.5..<112.5: return "East"
        case 112.5..<157.5: return "Southeast"
        case 157.5..<202.5: return "South"
        case 202.5..<247.5: return "Southwest"
        case 247.5..<292.5: return "West"
        case 292.5..<337.5: return "Northwest"
        default: return "Unknown"
        }
    }
}
