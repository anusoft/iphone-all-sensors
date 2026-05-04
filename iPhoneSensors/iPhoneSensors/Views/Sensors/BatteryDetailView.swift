import SwiftUI

struct BatteryDetailView: View {
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: batteryIcon(level: sys.batteryLevel))
                        .font(.system(size: 60))
                        .foregroundStyle(batteryColor(level: sys.batteryLevel))
                    Text(String(format: "%.0f%%", sys.batteryLevel * 100))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    StatusBadge(text: sys.batteryStateText, color: batteryColor(level: sys.batteryLevel))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Battery Info")
                        .font(.headline)
                    DataRow(label: "Level", value: String(format: "%.0f%%", sys.batteryLevel * 100), icon: batteryIcon(level: sys.batteryLevel))
                    DataRow(label: "State", value: sys.batteryStateText, icon: "bolt.fill")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Battery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func batteryIcon(level: Float) -> String {
        switch level {
        case ..<0.1: return "battery.0"
        case ..<0.25: return "battery.25"
        case ..<0.5: return "battery.50"
        case ..<0.75: return "battery.75"
        default: return "battery.100"
        }
    }

    private func batteryColor(level: Float) -> Color {
        switch level {
        case ..<0.2: return .red
        case ..<0.5: return .orange
        default: return .green
        }
    }
}
