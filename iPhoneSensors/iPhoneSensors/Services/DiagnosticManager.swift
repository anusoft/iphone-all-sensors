import Foundation
import SwiftUI

enum DiagnosticStatus: Equatable {
    case notStarted
    case inProgress
    case active           // Sensor available and responding
    case unavailable      // Hardware physically missing
    case permissionDenied // Hardware present but permission denied
    case skipped
}

enum DiagnosticResult: Equatable {
    case notStarted
    case inProgress
    case passed
    case failed(String)
    case skipped
}

struct DiagnosticTest: Identifiable {
    let id: String
    let nameKey: String
    let descriptionKey: String
    let icon: String
    let color: Color
    var status: DiagnosticStatus = .notStarted
    var duration: TimeInterval = 0
}

@MainActor
class DiagnosticManager: ObservableObject {
    static let shared = DiagnosticManager()

    @Published var tests: [DiagnosticTest] = []
    @Published var isRunning = false
    @Published var overallScore: Double = 0

    private var startTime: Date?

    init() {
        resetTests()
    }

    func resetTests() {
        tests = [
            DiagnosticTest(id: "accelerometer", nameKey: "sensor.accelerometer", descriptionKey: "diagnostic.accelerometer.desc", icon: "gyroscope", color: .blue),
            DiagnosticTest(id: "gyroscope", nameKey: "sensor.gyroscope", descriptionKey: "diagnostic.gyroscope.desc", icon: "gyroscope", color: .indigo),
            DiagnosticTest(id: "magnetometer", nameKey: "sensor.magnetometer", descriptionKey: "diagnostic.magnetometer.desc", icon: "sensor.tag.radiowaves.forward", color: .purple),
            DiagnosticTest(id: "gps", nameKey: "sensor.gps", descriptionKey: "diagnostic.gps.desc", icon: "location.fill", color: .green),
            DiagnosticTest(id: "compass", nameKey: "sensor.compass", descriptionKey: "diagnostic.compass.desc", icon: "safari", color: .mint),
            DiagnosticTest(id: "barometer", nameKey: "sensor.barometer", descriptionKey: "diagnostic.barometer.desc", icon: "barometer", color: .orange),
            DiagnosticTest(id: "proximity", nameKey: "sensor.proximity", descriptionKey: "diagnostic.proximity.desc", icon: "sensor.tag.radiowaves.forward", color: .red),
            DiagnosticTest(id: "brightness", nameKey: "sensor.brightness", descriptionKey: "diagnostic.brightness.desc", icon: "sun.max.fill", color: .yellow),
            DiagnosticTest(id: "battery", nameKey: "sensor.battery", descriptionKey: "diagnostic.battery.desc", icon: "battery.100", color: .green),
            DiagnosticTest(id: "bluetooth", nameKey: "sensor.bluetooth", descriptionKey: "diagnostic.bluetooth.desc", icon: "antenna.radiowaves.left.and.right", color: .blue),
            DiagnosticTest(id: "network", nameKey: "sensor.network", descriptionKey: "diagnostic.network.desc", icon: "network", color: .cyan),
            DiagnosticTest(id: "camera", nameKey: "sensor.camera", descriptionKey: "diagnostic.camera.desc", icon: "camera.fill", color: .yellow),
        ]
        overallScore = 0
    }

    func runAllTests(motion: MotionSensorManager, location: LocationSensorManager, environment: EnvironmentSensorManager, system: SystemSensorManager, connectivity: ConnectivitySensorManager, camera: CameraSensorManager) async {
        isRunning = true
        startTime = Date()

        for i in tests.indices {
            tests[i].status = .inProgress
            let testStart = Date()

            let status = await runTest(
                test: tests[i],
                motion: motion,
                location: location,
                environment: environment,
                system: system,
                connectivity: connectivity,
                camera: camera
            )

            tests[i].status = status
            tests[i].duration = Date().timeIntervalSince(testStart)

            // Small delay between tests for visual feedback
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        calculateOverallScore()
        isRunning = false
    }

    func runSingleTest(index: Int, motion: MotionSensorManager, location: LocationSensorManager, environment: EnvironmentSensorManager, system: SystemSensorManager, connectivity: ConnectivitySensorManager, camera: CameraSensorManager) async {
        guard tests.indices.contains(index) else { return }

        tests[index].status = .inProgress
        let testStart = Date()

        let status = await runTest(
            test: tests[index],
            motion: motion,
            location: location,
            environment: environment,
            system: system,
            connectivity: connectivity,
            camera: camera
        )

        tests[index].status = status
        tests[index].duration = Date().timeIntervalSince(testStart)

        calculateOverallScore()
    }

    private func runTest(test: DiagnosticTest, motion: MotionSensorManager, location: LocationSensorManager, environment: EnvironmentSensorManager, system: SystemSensorManager, connectivity: ConnectivitySensorManager, camera: CameraSensorManager) async -> DiagnosticStatus {
        switch test.id {
        case "accelerometer":
            if !motion.isAccelerometerAvailable { return .unavailable }
            return .active
        case "gyroscope":
            if !motion.isGyroscopeAvailable { return .unavailable }
            return .active
        case "magnetometer":
            if !motion.isMagnetometerAvailable { return .unavailable }
            return .active
        case "gps":
            if !location.isAuthorized {
                return location.authorizationStatus == .denied || location.authorizationStatus == .restricted ? .permissionDenied : .unavailable
            }
            return .active
        case "compass":
            if !location.isAuthorized {
                return location.authorizationStatus == .denied || location.authorizationStatus == .restricted ? .permissionDenied : .unavailable
            }
            return location.trueHeading != 0 ? .active : .unavailable
        case "barometer":
            if !environment.isAltimeterAvailable { return .unavailable }
            return .active
        case "proximity":
            if !environment.isProximityMonitoringEnabled { return .unavailable }
            return .active
        case "brightness":
            return .active // Always available
        case "battery":
            return system.isBatteryMonitoringEnabled ? .active : .unavailable
        case "bluetooth":
            if connectivity.bluetoothState == .unsupported || connectivity.bluetoothState == .unauthorized {
                return .permissionDenied
            }
            if connectivity.bluetoothState == .poweredOn { return .active }
            return .unavailable
        case "network":
            return connectivity.isConnectedToNetwork ? .active : .unavailable
        case "camera":
            if !camera.isRearCameraAvailable { return .unavailable }
            return .active
        default:
            return .skipped
        }
    }

    private func calculateOverallScore() {
        let completedTests = tests.filter { $0.status != .notStarted && $0.status != .inProgress }
        // Exclude unavailable sensors from score calculation
        let scorableTests = completedTests.filter { $0.status != .unavailable }
        guard !scorableTests.isEmpty else { return }

        let activeCount = scorableTests.filter { $0.status == .active }.count
        overallScore = Double(activeCount) / Double(scorableTests.count) * 100
    }

    func generateReport() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        var report = """
        Device Diagnostic Report
        ========================
        Date: \(dateFormatter.string(from: Date()))
        Device: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)

        Overall Score: \(Int(overallScore))%\n\n
        """

        for test in tests {
            let status: String
            switch test.status {
            case .active: status = "✅ ACTIVE"
            case .unavailable: status = "⚙️ UNAVAILABLE"
            case .permissionDenied: status = "🔒 PERMISSION DENIED"
            case .skipped: status = "⏭ SKIPPED"
            case .inProgress: status = "🔄 TESTING"
            case .notStarted: status = "⏳ NOT STARTED"
            }
            report += "\(test.id.uppercased()) - \(status)\n"
        }

        return report
    }
}
