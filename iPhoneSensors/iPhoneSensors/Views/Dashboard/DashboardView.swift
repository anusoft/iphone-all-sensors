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
                LazyVStack(spacing: 18) {
                    DashboardShowOffButton()

                    AllSensorsLogSessionBar()

                    DashboardSensorSummary()

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
                .responsivePage()
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
            AdaptiveCardGrid(spacing: 8) {
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
}

struct DashboardSensorSummary: View {
    @EnvironmentObject private var motion: MotionSensorManager
    @EnvironmentObject private var loc: LocationSensorManager
    @EnvironmentObject private var env: EnvironmentSensorManager
    @EnvironmentObject private var sys: SystemSensorManager
    @EnvironmentObject private var conn: ConnectivitySensorManager
    @EnvironmentObject private var cam: CameraSensorManager
    @EnvironmentObject private var locManager: LocalizationManager

    private var readiness: DashboardReadinessSnapshot {
        DashboardReadinessSnapshot(
            motion: .init(
                available: [
                    motion.isAccelerometerAvailable,
                    motion.isGyroscopeAvailable,
                    motion.isMagnetometerAvailable,
                    motion.isDeviceMotionAvailable,
                    motion.isPedometerAvailable,
                    motion.isAltimeterAvailable,
                    motion.isActivityAvailable
                ].availableCount,
                total: 7
            ),
            location: .init(
                available: loc.isAuthorized ? 2 : 0,
                total: 2
            ),
            environment: .init(
                available: [
                    env.isAltimeterAvailable,
                    env.isProximityMonitoringEnabled,
                    true
                ].availableCount,
                total: 3
            ),
            system: .init(
                available: [
                    sys.isBatteryMonitoringEnabled,
                    true,
                    true,
                    true,
                    true
                ].availableCount,
                total: 5
            ),
            connectivity: .init(
                available: [
                    conn.bluetoothState == .poweredOn,
                    true
                ].availableCount,
                total: 2
            ),
            camera: .init(
                available: [
                    cam.isRearCameraAvailable,
                    cam.isTorchAvailable
                ].availableCount,
                total: 2
            )
        )
    }

    var body: some View {
        ViewThatFits {
            HStack(spacing: 10) { tiles }
            VStack(spacing: 10) { tiles }
        }
    }

    @ViewBuilder
    private var tiles: some View {
        DashboardSummaryTile(
            title: locManager.t("status.available"),
            value: readiness.readinessValue,
            icon: "checkmark.seal.fill",
            color: .green
        )
        DashboardSummaryTile(
            title: locManager.t("dashboard.location"),
            value: loc.isAuthorized ? locManager.t("status.active") : locManager.t("status.waiting"),
            icon: "location.fill",
            color: loc.isAuthorized ? .green : .orange
        )
        DashboardSummaryTile(
            title: locManager.t("sensor.network"),
            value: conn.isConnectedToNetwork ? locManager.t("status.active") : locManager.t("status.unavailable"),
            icon: "network",
            color: conn.isConnectedToNetwork ? .cyan : .gray
        )
    }
}

struct DashboardReadinessSnapshot {
    struct Count {
        let available: Int
        let total: Int
    }

    let motion: Count
    let location: Count
    let environment: Count
    let system: Count
    let connectivity: Count
    let camera: Count

    var availableSensors: Int {
        counts.reduce(0) { $0 + $1.available }
    }

    var totalSensors: Int {
        counts.reduce(0) { $0 + $1.total }
    }

    var readinessValue: String {
        "\(availableSensors)/\(totalSensors)"
    }

    private var counts: [Count] {
        [motion, location, environment, system, connectivity, camera]
    }
}

private extension Array where Element == Bool {
    var availableCount: Int {
        filter { $0 }.count
    }
}

struct DashboardSummaryTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .appMaterialSurface(cornerRadius: 16, material: .thinMaterial)
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
        .appMaterialSurface(cornerRadius: 14, material: .thinMaterial)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.yellow)
                .frame(width: 4)
        }
    }
}

struct SensorSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
                content()
            }
            .padding(10)
            .appMaterialSurface(cornerRadius: 18, material: .ultraThinMaterial)
        }
    }
}
