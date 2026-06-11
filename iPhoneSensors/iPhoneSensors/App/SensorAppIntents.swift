import AppIntents
import Foundation

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

    var sensorID: SensorID {
        switch self {
        case .accelerometer: return .accelerometer
        case .gyroscope: return .gyroscope
        case .magnetometer: return .magnetometer
        case .gps: return .gps
        case .compass: return .heading
        case .barometer: return .altimeter
        case .battery: return .battery
        }
    }
}

struct GetSensorReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Reading"
    static var description = IntentDescription("Get the current value of a specific sensor.")

    @Parameter(title: "Sensor")
    var sensor: SensorType

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let manager = AppDelegate.sensorManager else {
            let message = "Open All Sensors and keep it in the foreground to read live \(sensor.rawValue) data."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }
        // Ensure sensors are streaming so we return a live value, not a stale zero.
        manager.startAllSensors()
        guard let value = manager.currentValue(for: sensor) else {
            let message = "\(sensor.rawValue.capitalized) is currently unavailable (sensor missing or permission not granted)."
            return .result(value: message, dialog: IntentDialog(stringLiteral: message))
        }
        return .result(value: value, dialog: IntentDialog(stringLiteral: "\(sensor.rawValue.capitalized): \(value)"))
    }
}

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sensor Recording"
    static var description = IntentDescription("Start recording data from a sensor.")

    @Parameter(title: "Sensor")
    var sensor: SensorType

    @MainActor
    func perform() async throws -> some IntentResult {
        await AppDelegate.loggingService?.startSessionFromUI(note: "Siri", only: sensor.sensorID)
        return .result(dialog: "Started recording \(sensor.rawValue) data.")
    }
}

struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Sensor Recording"
    static var description = IntentDescription("Stop the active sensor logging session.")

    @MainActor
    func perform() async throws -> some IntentResult {
        await AppDelegate.loggingService?.stopSessionFromUI()
        return .result(dialog: "Stopped sensor recording.")
    }
}

struct ExportSensorDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Sensor Data"
    static var description = IntentDescription("Export a snapshot of all current sensor readings as a CSV file.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> & ProvidesDialog {
        guard let manager = AppDelegate.sensorManager else {
            throw AppIntentError.appNotRunning
        }
        manager.startAllSensors()
        guard let url = DataExportManager.shared.exportCurrentSensors(
            motion: manager.motionManager,
            location: manager.locationManager,
            environment: manager.environmentManager,
            system: manager.systemManager,
            connectivity: manager.connectivityManager,
            camera: manager.cameraManager,
            format: .csv
        ) else {
            throw AppIntentError.exportFailed
        }
        let file = IntentFile(fileURL: url, filename: url.lastPathComponent)
        return .result(value: file, dialog: "Exported a snapshot of current sensor readings.")
    }
}

enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case appNotRunning
    case exportFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .appNotRunning: return "Open All Sensors and keep it in the foreground, then try again."
        case .exportFailed: return "Could not write the export file. Check available storage and try again."
        }
    }
}
