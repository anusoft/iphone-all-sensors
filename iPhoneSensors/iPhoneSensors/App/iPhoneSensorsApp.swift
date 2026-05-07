import SwiftUI
import UIKit

@main
struct iPhoneSensorsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var locManager = LocalizationManager()
    @StateObject private var loggingService = LoggingService()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var diagnosticManager = DiagnosticManager()
    @StateObject private var recorder = SensorRecorder()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensorManager)
                .environmentObject(sensorManager.motionManager)
                .environmentObject(sensorManager.locationManager)
                .environmentObject(sensorManager.environmentManager)
                .environmentObject(sensorManager.systemManager)
                .environmentObject(sensorManager.healthManager)
                .environmentObject(sensorManager.connectivityManager)
                .environmentObject(sensorManager.cameraManager)
                .environmentObject(locManager)
                .environmentObject(loggingService)
                .environmentObject(themeManager)
                .environmentObject(diagnosticManager)
                .environmentObject(recorder)
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    await loggingService.bootstrap()
                    // Register publishers for every sensor manager. Per-sensor logging is
                    // driven by LoggingConfiguration.default(for:) (via LoggingConfigStore
                    // falling back to defaults), so no per-sensor smoke helper is needed.
                    loggingService.attach(sensorManager.motionManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.locationManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.environmentManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.systemManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.connectivityManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.cameraManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.healthManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attachThrottleSource(sensorManager)
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var loggingService: LoggingService?

    func applicationWillTerminate(_ application: UIApplication) {
        let sem = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await Self.loggingService?.flush()
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + .milliseconds(200))
    }
}

import AppIntents

enum SensorType: String, AppEnum {
    case accelerometer, gyroscope, magnetometer, gps, compass, barometer, battery

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Sensor")
    }

    static var caseDisplayRepresentations: [SensorType: DisplayRepresentation] = [
        .accelerometer: DisplayRepresentation(title: "Accelerometer"),
        .gyroscope: DisplayRepresentation(title: "Gyroscope"),
        .magnetometer: DisplayRepresentation(title: "Magnetometer"),
        .gps: DisplayRepresentation(title: "GPS"),
        .compass: DisplayRepresentation(title: "Compass"),
        .barometer: DisplayRepresentation(title: "Barometer"),
        .battery: DisplayRepresentation(title: "Battery")
    ]
}

struct GetSensorReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Reading"
    static var description = IntentDescription("Get the current value of a specific sensor.")

    @Parameter(title: "Sensor")
    var sensor: SensorType

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let value = await getSensorValue(sensor: sensor)
        return .result(value: value)
    }

    private func getSensorValue(sensor: SensorType) async -> String {
        // This would normally read from SensorManager
        // For now, return a placeholder that will be replaced with actual data
        switch sensor {
        case .accelerometer: return "0.98 G"
        case .gyroscope: return "0.05 rad/s"
        case .magnetometer: return "45.2 µT"
        case .gps: return "13.7563°N, 100.5018°E"
        case .compass: return "245°"
        case .barometer: return "101.3 kPa"
        case .battery: return "85%"
        }
    }
}

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sensor Recording"
    static var description = IntentDescription("Start recording data from a sensor.")

    @Parameter(title: "Sensor")
    var sensor: SensorType

    func perform() async throws -> some IntentResult {
        // Would integrate with SensorRecorder
        return .result(dialog: "Started recording \(sensor.rawValue) data.")
    }
}

struct ExportSensorDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Sensor Data"
    static var description = IntentDescription("Export current sensor data as CSV.")

    func perform() async throws -> some IntentResult {
        // Would trigger DataExportManager
        return .result(dialog: "Sensor data exported successfully.")
    }
}
