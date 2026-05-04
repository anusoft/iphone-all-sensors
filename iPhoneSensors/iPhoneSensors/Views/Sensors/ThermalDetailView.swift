import SwiftUI

struct ThermalDetailView: View {
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 60))
                        .foregroundStyle(thermalColor(state: sys.thermalState))
                    Text(sys.thermalStateText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    StatusBadge(text: sys.thermalStateText, color: thermalColor(state: sys.thermalState))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Thermal Info")
                        .font(.headline)
                    DataRow(label: "Thermal State", value: sys.thermalStateText, icon: "thermometer.medium")
                    DataRow(label: "Low Power Mode", value: sys.isLowPowerModeEnabled ? "Enabled" : "Disabled", icon: "bolt.circle")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Thermal State")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func thermalColor(state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}
