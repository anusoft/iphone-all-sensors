import SwiftUI

struct SystemInfoView: View {
    @EnvironmentObject var sensorManager: SensorManager

    var body: some View {
        let sys = sensorManager.systemManager
        return NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        Text(sys.deviceName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(sys.systemName) \(sys.systemVersion)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Device Info")
                            .font(.headline)
                        DataRow(label: "Device Name", value: sys.deviceName, icon: "iphone")
                        DataRow(label: "Model", value: sys.deviceModel, icon: "cube")
                        DataRow(label: "System", value: "\(sys.systemName) \(sys.systemVersion)", icon: "gear")
                        DataRow(label: "Identifier", value: sys.deviceIdentifierForVendor, icon: "number")
                        Divider()
                        DataRow(label: "Screen Size", value: "\(Int(sys.screenBounds.width))×\(Int(sys.screenBounds.height))", icon: "rectangle")
                        DataRow(label: "Screen Scale", value: String(format: "%.0fx", sys.screenScale), icon: "arrow.up.left.and.arrow.down.right")
                        DataRow(label: "Brightness", value: String(format: "%.0f%%", sys.screenBrightness * 100), icon: "sun.max.fill")
                        Divider()
                        DataRow(label: "Orientation", value: sys.orientationText, icon: "rotate.right")
                        DataRow(label: "Multitasking", value: sys.isMultitaskingSupported ? "Supported" : "Not Supported", icon: "square.split.2x2")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    NavigationLink {
                        BatteryDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "battery.100")
                                .foregroundStyle(.green)
                            Text("Battery Details")
                            Spacer()
                            Text(String(format: "%.0f%%", sys.batteryLevel * 100))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        ProcessorDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundStyle(.purple)
                            Text("Processor Details")
                            Spacer()
                            Text("\(sys.activeProcessorCount) cores")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        MemoryDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundStyle(.indigo)
                            Text("Memory Details")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        DiskDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.teal)
                            Text("Storage Details")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .memory) + " free")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        ThermalDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(.orange)
                            Text("Thermal State")
                            Spacer()
                            Text(sys.thermalStateText)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("System Info")
            .onAppear {
                sensorManager.systemManager.startUpdates()
            }
        }
    }
}
