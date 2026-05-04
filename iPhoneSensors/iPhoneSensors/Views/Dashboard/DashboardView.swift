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
    @State private var searchText = ""
    @State private var showLanguagePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle(locManager.t("dashboard.title"))
            .searchable(text: $searchText, prompt: locManager.t("dashboard.search"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showLanguagePicker = true }) {
                        Text(locManager.currentLanguage.flag)
                            .font(.title2)
                    }
                }
            }
            .confirmationDialog(locManager.t("language.title"), isPresented: $showLanguagePicker) {
                ForEach(AppLanguage.allCases) { lang in
                    Button(action: { locManager.currentLanguage = lang }) {
                        HStack {
                            Text(lang.flag)
                            Text(lang.displayName)
                            if locManager.currentLanguage == lang {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .onAppear {
                sensorManager.startAllSensors()
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
                Text("No sensors found")
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

struct SensorSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
