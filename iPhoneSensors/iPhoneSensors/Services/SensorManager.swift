import Foundation
import Combine

@MainActor
class SensorManager: ObservableObject {
    let motionManager = MotionSensorManager()
    let locationManager = LocationSensorManager()
    let environmentManager = EnvironmentSensorManager()
    let systemManager = SystemSensorManager()
    let healthManager = HealthSensorManager()
    let connectivityManager = ConnectivitySensorManager()
    let cameraManager = CameraSensorManager()

    @Published var isStarted = false
    @Published var isThrottled: Bool = false {
        didSet {
            guard oldValue != isThrottled else { return }
            let value = isThrottled
            let coord = loggingCoordinator
            Task { await coord?.setThrottled(value) }
        }
    }
    @Published var throttleReason = ""

    /// Strong reference (actor weak refs are awkward; both objects live for app lifetime).
    var loggingCoordinator: LoggingCoordinator?

    /// Update the throttle state. Forwards changes to the logging coordinator.
    func updateThrottleState(_ value: Bool) {
        self.isThrottled = value
    }

    func startAllSensors() {
        guard !isStarted else {
            print("[SensorManager] Already started, skipping")
            return
        }
        print("[SensorManager] ▶ Starting all sensors...")
        isStarted = true

        motionManager.startUpdates()
        print("[SensorManager] ✓ Motion manager started")

        locationManager.startUpdates()
        print("[SensorManager] ✓ Location manager started")

        environmentManager.startUpdates()
        environmentManager.subscribeToMotionAltitude(motionManager)
        print("[SensorManager] ✓ Environment manager started")

        systemManager.startUpdates()
        print("[SensorManager] ✓ System manager started")

        healthManager.startUpdates()
        print("[SensorManager] ✓ Health manager started")

        connectivityManager.startUpdates()
        print("[SensorManager] ✓ Connectivity manager started")

        cameraManager.startUpdates()
        print("[SensorManager] ✓ Camera manager started")

        updateThrottleState()
        print("[SensorManager] ✅ All sensors started")
    }

    func stopAllSensors() {
        print("[SensorManager] ■ Stopping all sensors...")
        isStarted = false
        motionManager.stopUpdates()
        locationManager.stopUpdates()
        environmentManager.stopUpdates()
        connectivityManager.stopUpdates()
        print("[SensorManager] ✅ All sensors stopped")
    }

    func updateThrottleState() {
        let thermal = systemManager.thermalState
        let lowPower = systemManager.isLowPowerModeEnabled
        let shouldThrottle = thermal == .critical || thermal == .serious || lowPower

        if shouldThrottle != isThrottled {
            isThrottled = shouldThrottle
            if isThrottled {
                throttleReason = thermal == .critical || thermal == .serious ? "power.thermalThrottling" : "power.lowPowerMode"
                motionManager.setThrottle(true)
                if SensorRecorder.shared.activeRecording != nil {
                    SensorRecorder.shared.stopRecording()
                    print("[SensorManager] ⏸ Recording paused due to throttling")
                }
                print("[SensorManager] 🔒 Throttling activated: \(throttleReason)")
            } else {
                throttleReason = ""
                motionManager.setThrottle(false)
                print("[SensorManager] 🔓 Throttling deactivated")
            }
        }
    }
}
import Foundation
import UIKit
import SwiftUI

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
}

struct SensorSnapshot {
    let timestamp: Date
    let sensorName: String
    let values: [String: Any]
    let unit: String
}

@MainActor
class DataExportManager: ObservableObject {
    static let shared = DataExportManager()
    
    func exportCurrentSensors(
        motion: MotionSensorManager,
        location: LocationSensorManager,
        environment: EnvironmentSensorManager,
        system: SystemSensorManager,
        connectivity: ConnectivitySensorManager,
        camera: CameraSensorManager,
        format: ExportFormat
    ) -> URL? {
        let snapshots = createSnapshots(
            motion: motion,
            location: location,
            environment: environment,
            system: system,
            connectivity: connectivity,
            camera: camera
        )
        
        switch format {
        case .csv:
            return exportCSV(snapshots: snapshots)
        case .json:
            return exportJSON(snapshots: snapshots)
        }
    }
    
    func exportRecording(dataPoints: [ChartDataPoint], sensorName: String, unit: String, format: ExportFormat) -> URL? {
        let snapshots = dataPoints.map { point in
            SensorSnapshot(
                timestamp: point.timestamp,
                sensorName: sensorName,
                values: ["x": point.x, "y": point.y, "z": point.z],
                unit: unit
            )
        }
        
        switch format {
        case .csv:
            return exportCSV(snapshots: snapshots)
        case .json:
            return exportJSON(snapshots: snapshots)
        }
    }
    
    private func createSnapshots(
        motion: MotionSensorManager,
        location: LocationSensorManager,
        environment: EnvironmentSensorManager,
        system: SystemSensorManager,
        connectivity: ConnectivitySensorManager,
        camera: CameraSensorManager
    ) -> [SensorSnapshot] {
        var snapshots: [SensorSnapshot] = []
        let now = Date()
        
        // Motion sensors
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Accelerometer", values: ["x": motion.accX, "y": motion.accY, "z": motion.accZ], unit: "G"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Gyroscope", values: ["x": motion.gyroX, "y": motion.gyroY, "z": motion.gyroZ], unit: "rad/s"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Magnetometer", values: ["x": motion.magX, "y": motion.magY, "z": motion.magZ], unit: "µT"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Pedometer", values: ["steps": motion.steps], unit: "steps"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Altimeter", values: ["altitude": motion.relativeAltitude, "pressure": motion.pressure], unit: "m"))
        
        // Location
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "GPS", values: ["latitude": location.latitude, "longitude": location.longitude, "altitude": location.altitude], unit: "°"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Compass", values: ["heading": location.trueHeading], unit: "°"))
        
        // Environment
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Barometer", values: ["pressure": environment.pressure], unit: "kPa"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Proximity", values: ["state": environment.proximityState], unit: ""))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Brightness", values: ["level": environment.screenBrightness], unit: "%"))
        
        // System
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Battery", values: ["level": system.batteryLevel], unit: "%"))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Thermal", values: ["state": system.thermalState.rawValue], unit: ""))
        
        // Connectivity
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Bluetooth", values: ["state": connectivity.bluetoothStateText], unit: ""))
        snapshots.append(SensorSnapshot(timestamp: now, sensorName: "Network", values: ["type": connectivity.networkType], unit: ""))
        
        return snapshots
    }
    
    private func exportCSV(snapshots: [SensorSnapshot]) -> URL? {
        var csv = "Timestamp,Sensor,Values,Unit\n"
        
        for snapshot in snapshots {
            let valuesString = snapshot.values.map { "\($0.key):\($0.value)" }.joined(separator: "; ")
            let dateFormatter = ISO8601DateFormatter()
            csv += "\(dateFormatter.string(from: snapshot.timestamp)),\(snapshot.sensorName),\"\(valuesString)\",\(snapshot.unit)\n"
        }
        
        return saveToFile(content: csv, filename: "sensor_data_\(Int(Date().timeIntervalSince1970)).csv")
    }
    
    private func exportJSON(snapshots: [SensorSnapshot]) -> URL? {
        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "sensorCount": snapshots.count,
            "sensors": snapshots.map { snapshot in
                [
                    "name": snapshot.sensorName,
                    "timestamp": ISO8601DateFormatter().string(from: snapshot.timestamp),
                    "values": snapshot.values,
                    "unit": snapshot.unit
                ] as [String: Any]
            }
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return saveToFile(content: jsonString, filename: "sensor_data_\(Int(Date().timeIntervalSince1970)).json")
    }
    
    private func saveToFile(content: String, filename: String) -> URL? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename) else {
            return nil
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("[Export] Failed to save file: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
import Foundation
import Combine

struct RecordingDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let values: [String: Double]
}

struct SensorRecording: Identifiable {
    let id = UUID()
    let sensorName: String
    let sensorKey: String
    let startTime: Date
    var endTime: Date?
    var dataPoints: [RecordingDataPoint]
    
    var duration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
}

@MainActor
class SensorRecorder: ObservableObject {
    static let shared = SensorRecorder()
    
    @Published var recordings: [SensorRecording] = []
    @Published var activeRecording: SensorRecording?
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    func startRecording(sensorName: String, sensorKey: String, valueProvider: @escaping () -> [String: Double]) {
        _ = valueProvider
        let recording = SensorRecording(
            sensorName: sensorName,
            sensorKey: sensorKey,
            startTime: Date(),
            endTime: nil,
            dataPoints: []
        )
        
        activeRecording = recording
        recordings.append(recording)

        if let service = AppDelegate.loggingService {
            Task { @MainActor in
                await service.startSessionFromUI(
                    note: sensorName,
                    only: SensorID(legacyRecorderKey: sensorKey, sensorName: sensorName)
                )
            }
        }
        
        print("[Recorder] Started persistent logger session for \(sensorName)")
    }
    
    func stopRecording() {
        timer?.invalidate()
        timer = nil

        if let service = AppDelegate.loggingService {
            Task { @MainActor in
                await service.stopSessionFromUI()
            }
        }
        
        if let recording = activeRecording,
           let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].endTime = Date()
            activeRecording = nil
            print("[Recorder] Stopped persistent logger session for \(recording.sensorName). Duration: \(recordings[index].duration)s")
        }
    }
    
    func deleteRecording(id: UUID) {
        if activeRecording?.id == id {
            stopRecording()
        }
        recordings.removeAll { $0.id == id }
    }
    
    func deleteAllRecordings() {
        stopRecording()
        recordings.removeAll()
    }
    
    func exportRecording(id: UUID, format: ExportFormat) -> URL? {
        guard let recording = recordings.first(where: { $0.id == id }) else { return nil }
        
        let chartPoints = recording.dataPoints.map { point in
            ChartDataPoint(
                timestamp: point.timestamp,
                x: point.values["x"] ?? 0,
                y: point.values["y"] ?? 0,
                z: point.values["z"] ?? 0
            )
        }
        
        return DataExportManager.shared.exportRecording(
            dataPoints: chartPoints,
            sensorName: recording.sensorName,
            unit: "",
            format: format
        )
    }
}

private extension SensorID {
    init?(legacyRecorderKey: String, sensorName: String) {
        let key = legacyRecorderKey.lowercased()
        let name = sensorName.lowercased()

        if key.contains("accelerometer") || name.contains("accelerometer") {
            self = .accelerometer
        } else if key.contains("gyro") || name.contains("gyro") {
            self = .gyroscope
        } else if key.contains("magnet") || name.contains("magnet") {
            self = .magnetometer
        } else if key.contains("motion") || name.contains("motion") {
            self = .deviceMotion
        } else if key.contains("location") || key.contains("gps") || name.contains("location") || name.contains("gps") {
            self = .gps
        } else if key.contains("heading") || name.contains("heading") || name.contains("compass") {
            self = .heading
        } else if key.contains("altimeter") || key.contains("barometer") || name.contains("altimeter") || name.contains("barometer") {
            self = .altimeter
        } else if key.contains("step") || key.contains("pedometer") || name.contains("step") || name.contains("pedometer") {
            self = .pedometer
        } else if key.contains("battery") || name.contains("battery") {
            self = .battery
        } else if key.contains("thermal") || name.contains("thermal") {
            self = .thermal
        } else if key.contains("bluetooth") || name.contains("bluetooth") {
            self = .bluetoothState
        } else if key.contains("network") || key.contains("wifi") || name.contains("network") || name.contains("wi-fi") {
            self = .network
        } else if key.contains("camera") || name.contains("camera") {
            self = .camera
        } else if key.contains("torch") || name.contains("torch") {
            self = .torch
        } else if key.contains("proximity") || name.contains("proximity") {
            self = .proximity
        } else if key.contains("brightness") || key.contains("light") || name.contains("brightness") || name.contains("light") {
            self = .brightness
        } else {
            return nil
        }
    }
}
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
