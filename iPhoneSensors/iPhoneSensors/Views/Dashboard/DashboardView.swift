import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var loc: LocationSensorManager
    @EnvironmentObject var env: EnvironmentSensorManager
    @EnvironmentObject var sys: SystemSensorManager
    @EnvironmentObject var conn: ConnectivitySensorManager
    @EnvironmentObject var cam: CameraSensorManager
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if sensorManager.isThrottled {
                        ThrottleBanner(reason: sensorManager.throttleReason)
                    }
                    if searchText.isEmpty {
                        SensorSection(title: locManager.t("dashboard.motion"), icon: "gyroscope", color: .blue) {
                            MotionDashboardCards()
                        }
                        SensorSection(title: locManager.t("dashboard.location"), icon: "location.fill", color: .green) {
                            LocationDashboardCards()
                        }
                        SensorSection(title: locManager.t("dashboard.environment"), icon: "thermometer.medium", color: .orange) {
                            EnvironmentDashboardCards()
                        }
                        SensorSection(title: locManager.t("dashboard.system"), icon: "cpu", color: .purple) {
                            SystemDashboardCards()
                        }
                        SensorSection(title: locManager.t("dashboard.connectivity"), icon: "wifi", color: .cyan) {
                            ConnectivityDashboardCards()
                        }
                        SensorSection(title: locManager.t("dashboard.camera"), icon: "camera.fill", color: .yellow) {
                            CameraDashboardCards()
                        }
                    } else {
                        searchResults
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(locManager.t("dashboard.title"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: locManager.t("dashboard.search"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let allSensors: [(String, String, Color, Bool)] = [
            (locManager.t("sensor.accelerometer"), "gyroscope", .blue, motion.isAccelerometerAvailable),
            (locManager.t("sensor.gyroscope"), "gyroscope", .indigo, motion.isGyroscopeAvailable),
            (locManager.t("sensor.magnetometer"), "sensor.tag.radiowaves.forward", .purple, motion.isMagnetometerAvailable),
            (locManager.t("sensor.deviceMotion"), "rotate.3d", .teal, motion.isDeviceMotionAvailable),
            (locManager.t("sensor.pedometer"), "figure.walk", .green, motion.isPedometerAvailable),
            (locManager.t("sensor.altimeter"), "altimeter", .cyan, motion.isAltimeterAvailable),
            (locManager.t("sensor.activity"), "figure.run", .orange, motion.isActivityAvailable),
            (locManager.t("sensor.gps"), "location.fill", .green, loc.isAuthorized),
            (locManager.t("sensor.compass"), "safari", .mint, loc.isAuthorized),
            (locManager.t("sensor.barometer"), "barometer", .orange, env.isAltimeterAvailable),
            (locManager.t("sensor.proximity"), "sensor.tag.radiowaves.forward", .red, env.isProximityMonitoringEnabled),
            (locManager.t("sensor.brightness"), "sun.max.fill", .yellow, true),
            (locManager.t("sensor.battery"), "battery.100", .green, sys.isBatteryMonitoringEnabled),
            (locManager.t("sensor.processor"), "cpu", .purple, true),
            (locManager.t("sensor.memory"), "memorychip", .indigo, true),
            (locManager.t("sensor.storage"), "internaldrive", .teal, true),
            (locManager.t("sensor.thermal"), "thermometer.medium", .orange, true),
            (locManager.t("sensor.bluetooth"), "antenna.radiowaves.left.and.right", .blue, conn.bluetoothState == .poweredOn),
            (locManager.t("sensor.network"), "network", .cyan, true),
            (locManager.t("sensor.camera"), "camera.fill", .yellow, cam.isRearCameraAvailable),
            (locManager.t("sensor.torch"), "flashlight.on.fill", .orange, cam.isTorchAvailable),
        ]

        let filtered = allSensors.filter {
            searchText.isEmpty || $0.0.localizedCaseInsensitiveContains(searchText)
        }

        if filtered.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(locManager.t("search.noResults"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            ForEach(filtered, id: \.0) { sensor in
                SensorCard(
                    title: sensor.0,
                    icon: sensor.1,
                    value: "",
                    unit: "",
                    color: sensor.2,
                    isAvailable: sensor.3
                )
            }
        }
    }
}

struct ThrottleBanner: View {
    let reason: String
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.yellow)
            Text(locManager.t(reason))
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SensorSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 8) {
                content()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark 
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06),
                            lineWidth: 0.5)
            }
        }
    }
}
