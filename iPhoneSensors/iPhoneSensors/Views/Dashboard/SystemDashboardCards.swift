import SwiftUI

struct SystemDashboardCards: View {
    @EnvironmentObject var sys: SystemSensorManager
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        AdaptiveCardGrid(spacing: 10) {
            NavigationLink {
                BatteryDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.battery"),
                    icon: batteryIcon(level: sys.batteryLevel),
                    value: LocalizedDisplayValue.numberNoSpace("%.0f", Double(sys.batteryLevel) * 100, unitKey: "unit.percent", localization: locManager),
                    unit: locManager.t(sys.batteryStateKey),
                    color: batteryColor(level: sys.batteryLevel),
                    isAvailable: sys.isBatteryMonitoringEnabled
                )
            }
            NavigationLink {
                ProcessorDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.processor"),
                    icon: "cpu",
                    value: "\(sys.activeProcessorCount)/\(sys.processorCount)",
                    unit: locManager.t("unit.cores"),
                    color: .purple,
                    isAvailable: true
                )
            }
            NavigationLink {
                MemoryDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.memory"),
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
                    title: locManager.t("sensor.storage"),
                    icon: "internaldrive",
                    value: ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .memory),
                    unit: locManager.t("unit.free"),
                    color: .teal,
                    isAvailable: true
                )
            }
            NavigationLink {
                ThermalDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.thermal"),
                    icon: "thermometer.medium",
                    value: locManager.t(sys.thermalStateKey),
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
