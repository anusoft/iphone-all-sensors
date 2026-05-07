import SwiftUI

struct MemoryDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 50))
                        .foregroundStyle(.indigo)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(locManager.t("section.totalPhysicalMemory"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.physicalMemory"), value: ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory), icon: "memorychip")
                    DataRow(label: locManager.t("label.formatted"), value: String(format: "%.2f GB", Double(sys.physicalMemory) / 1_073_741_824), icon: "memorychip")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(locManager.t("sensor.memory"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
