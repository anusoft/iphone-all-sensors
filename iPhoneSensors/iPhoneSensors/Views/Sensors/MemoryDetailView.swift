import SwiftUI

struct MemoryDetailView: View {
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
                    Text("Total Physical Memory")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Memory Info")
                        .font(.headline)
                    DataRow(label: "Physical Memory", value: ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory), icon: "memorychip")
                    DataRow(label: "Formatted", value: String(format: "%.2f GB", Double(sys.physicalMemory) / 1_073_741_824), icon: "memorychip")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
    }
}
