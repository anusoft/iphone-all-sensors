import SwiftUI

struct SystemDashboardCards: View {
    @EnvironmentObject var sys: SystemSensorManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                BatteryDetailView()
            } label: {
                SensorCard(
                    title: "Battery",
                    icon: batteryIcon(level: sys.batteryLevel),
                    value: String(format: "%.0f%%", sys.batteryLevel * 100),
                    unit: sys.batteryStateText,
                    color: batteryColor(level: sys.batteryLevel),
                    isAvailable: sys.isBatteryMonitoringEnabled
                )
            }
            NavigationLink {
                ProcessorDetailView()
            } label: {
                SensorCard(
                    title: "Processor",
                    icon: "cpu",
                    value: "\(sys.activeProcessorCount)/\(sys.processorCount)",
                    unit: "cores",
                    color: .purple,
                    isAvailable: true
                )
            }
            NavigationLink {
                MemoryDetailView()
            } label: {
                SensorCard(
                    title: "Memory",
                    icon: "memorychip",
                    value: ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory),
                    unit: "",
                    color: .indigo,
                    isAvailable: true
                )
            }
            NavigationLink {
                DiskDetailView()
            } label: {
                SensorCard(
                    title: "Storage",
                    icon: "internaldrive",
                    value: ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .memory),
                    unit: "free",
                    color: .teal,
                    isAvailable: true
                )
            }
            NavigationLink {
                ThermalDetailView()
            } label: {
                SensorCard(
                    title: "Thermal State",
                    icon: "thermometer.medium",
                    value: sys.thermalStateText,
                    unit: "",
                    color: thermalColor(state: sys.thermalState),
                    isAvailable: true
                )
            }
        }
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
