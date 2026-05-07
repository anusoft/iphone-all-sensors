import SwiftUI

struct DiskDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        let totalGB = Double(sys.totalDiskSpace) / 1_073_741_824
        let freeGB = Double(sys.freeDiskSpace) / 1_073_741_824
        let usedGB = Double(sys.usedDiskSpace) / 1_073_741_824
        let usagePercent = totalGB > 0 ? usedGB / totalGB : 0

        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text(String(format: "%.1f GB", freeGB))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text(locManager.t("section.freeSpace"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .glassCard()

                VStack(spacing: 12) {
                    Text(locManager.t("section.storageUsage"))
                        .font(.headline)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)).frame(height: 24)
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)).frame(width: CGFloat(usagePercent) * geo.size.width, height: 24)
                        }
                    }
                    .frame(height: 24)
                    HStack {
                        Text("\(locManager.t("disk.used")): \(String(format: "%.1f GB", usedGB))")
                        Spacer()
                        Text("\(locManager.t("disk.total")): \(String(format: "%.1f GB", totalGB))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: "Total Space", value: ByteCountFormatter.string(fromByteCount: sys.totalDiskSpace, countStyle: .file), icon: "internaldrive")
                    DataRow(label: "Free Space", value: ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .file), icon: "internaldrive")
                    DataRow(label: "Used Space", value: ByteCountFormatter.string(fromByteCount: sys.usedDiskSpace, countStyle: .file), icon: "internaldrive")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(locManager.t("sensor.storage"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
