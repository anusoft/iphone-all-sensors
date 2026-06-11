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
            appLog("[Export] Failed to save file: \(error)")
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
