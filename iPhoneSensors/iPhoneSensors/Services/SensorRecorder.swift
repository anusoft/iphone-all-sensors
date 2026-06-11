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

    func startRecording(sensorName: String, sensorKey: String) {
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

        appLog("[Recorder] Started persistent logger session for \(sensorName)")
    }

    func stopRecording() {
        if let service = AppDelegate.loggingService {
            Task { @MainActor in
                await service.stopSessionFromUI()
            }
        }

        if let recording = activeRecording,
           let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].endTime = Date()
            activeRecording = nil
            appLog("[Recorder] Stopped persistent logger session for \(recording.sensorName). Duration: \(recordings[index].duration)s")
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
