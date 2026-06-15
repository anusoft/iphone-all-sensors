import SwiftUI

struct DiskDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        let totalSpace = sys.totalDiskSpace
        let freeSpace = sys.freeDiskSpace
        let usedSpace = sys.usedDiskSpace
        let usagePercent = totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) : 0

        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Text(ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file))
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
                        Text("\(locManager.t("disk.used")): \(ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file))")
                        Spacer()
                        Text("\(locManager.t("disk.total")): \(ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.totalSpace"), value: ByteCountFormatter.string(fromByteCount: sys.totalDiskSpace, countStyle: .file), icon: "internaldrive")
                    DataRow(label: locManager.t("label.freeSpace"), value: ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .file), icon: "internaldrive")
                    DataRow(label: locManager.t("label.usedSpace"), value: ByteCountFormatter.string(fromByteCount: sys.usedDiskSpace, countStyle: .file), icon: "internaldrive")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.disk)
        .showOffEntry(sensorID: "13", accent: SO.diskAccent)
        .navigationTitle(locManager.t("sensor.storage"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
