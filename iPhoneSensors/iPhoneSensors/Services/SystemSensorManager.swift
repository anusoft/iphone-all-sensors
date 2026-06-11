import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
class SystemSensorManager: ObservableObject {
    @Published var batteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var batteryStateKey: String = "battery.unknown"
    @Published var isBatteryMonitoringEnabled = false

    @Published var deviceName: String = ""
    @Published var deviceModel: String = ""
    @Published var deviceLocalizedModel: String = ""
    @Published var systemName: String = ""
    @Published var systemVersion: String = ""
    @Published var deviceUniqueId: String = ""
    @Published var deviceIdentifierForVendor: String = ""

    @Published var screenBounds: CGRect = .zero
    @Published var screenScale: CGFloat = 0
    @Published var screenNativeScale: CGFloat = 0
    @Published var screenBrightness: Double = 0
    @Published var isScreenCaptured = false

    @Published var isMultitaskingSupported = false
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var thermalStateKey: String = "thermal.nominal"
    @Published var processorCount: Int = 0
    @Published var activeProcessorCount: Int = 0
    @Published var physicalMemory: UInt64 = 0
    @Published var systemUptime: TimeInterval = 0
    @Published var isLowPowerModeEnabled = false

    @Published var totalDiskSpace: Int64 = 0
    @Published var freeDiskSpace: Int64 = 0
    @Published var usedDiskSpace: Int64 = 0

    @Published var isFrontCameraAvailable = false
    @Published var isRearCameraAvailable = false
    @Published var isFlashAvailable = false
    @Published var isCameraAccessAuthorized = false

    @Published var isNFCAvailable = false

    @Published var orientationKey: String = "orientation.unknown"
    @Published var isMultitaskGestureEnabled = true

    /// Stream of sensor samples for the logging pipeline.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    private var timer: Timer?
    private var isStarted = false
    private var observers: [NSObjectProtocol] = []

    func startUpdates() {
        guard !isStarted else {
            appLog("[System] ⚠ Already started")
            return
        }
        isStarted = true
        appLog("[System] ── Starting System Sensors ──")

        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        isBatteryMonitoringEnabled = true
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
        batteryStateKey = batteryStateString(device.batteryState)

        deviceName = device.name
        deviceModel = device.model
        deviceLocalizedModel = device.localizedModel
        systemName = device.systemName
        systemVersion = device.systemVersion
        deviceIdentifierForVendor = device.identifierForVendor?.uuidString ?? "N/A"

        appLog("[System] Device: \(deviceName)")
        appLog("[System] Model: \(deviceModel)")
        appLog("[System] System: \(systemName) \(systemVersion)")
        appLog("[System] Battery: \(batteryLevel * 100)% (\(batteryStateKey))")
        appLog("[System] Identifier: \(deviceIdentifierForVendor)")

        screenBounds = UIScreen.main.bounds
        screenScale = UIScreen.main.scale
        screenNativeScale = UIScreen.main.nativeScale
        screenBrightness = UIScreen.main.brightness

        appLog("[System] Screen: \(Int(screenBounds.width))x\(Int(screenBounds.height)) @\(screenScale)x")

        let processInfo = ProcessInfo.processInfo
        isMultitaskingSupported = true
        thermalState = processInfo.thermalState
        thermalStateKey = thermalStateString(processInfo.thermalState)
        processorCount = processInfo.processorCount
        activeProcessorCount = processInfo.activeProcessorCount
        physicalMemory = processInfo.physicalMemory
        systemUptime = processInfo.systemUptime
        isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled

        appLog("[System] Processor: \(activeProcessorCount)/\(processorCount) cores")
        appLog("[System] Memory: \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory))")
        appLog("[System] Thermal: \(thermalStateKey)")
        appLog("[System] Low Power Mode: \(isLowPowerModeEnabled)")
        appLog("[System] Uptime: \(String(format: "%.0f", systemUptime))s")

        updateDiskSpace()
        updateCameraInfo()
        updateOrientation()

        let obs1 = NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let level = UIDevice.current.batteryLevel
                self.batteryLevel = level
                self.samplePublisher.send(SensorSample(
                    sensorID: .battery,
                    payload: .battery(level: Double(level),
                                      state: self.batteryStateLowercase(UIDevice.current.batteryState))))
                appLog("[System] 🔋 Battery: \(level * 100)%")
            }
        }
        let obs2 = NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let state = UIDevice.current.batteryState
                self.batteryState = state
                self.batteryStateKey = self.batteryStateString(state)
                self.samplePublisher.send(SensorSample(
                    sensorID: .battery,
                    payload: .battery(level: Double(UIDevice.current.batteryLevel),
                                      state: self.batteryStateLowercase(state))))
                appLog("[System] 🔋 Battery state: \(self.batteryStateKey)")
            }
        }
        let obs3 = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.updateOrientation()
                self.samplePublisher.send(SensorSample(
                    sensorID: .orientation,
                    payload: .orientation(name: self.orientationLowercase(UIDevice.current.orientation))))
            }
        }
        let obs4 = NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let state = ProcessInfo.processInfo.thermalState
                self.thermalState = state
                self.thermalStateKey = self.thermalStateString(state)
                self.samplePublisher.send(SensorSample(
                    sensorID: .thermal,
                    payload: .thermal(state: self.thermalStateLowercase(state))))
                appLog("[System] 🌡️ Thermal state: \(self.thermalStateKey)")
            }
        }

        observers = [obs1, obs2, obs3, obs4]

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let uptime = ProcessInfo.processInfo.systemUptime
                self.systemUptime = uptime
                self.screenBrightness = UIScreen.main.brightness
                let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
                self.isLowPowerModeEnabled = lowPower
                self.updateDiskSpace()
                self.samplePublisher.send(SensorSample(
                    sensorID: .disk,
                    payload: .disk(total: self.totalDiskSpace, free: self.freeDiskSpace)))
                self.samplePublisher.send(SensorSample(
                    sensorID: .uptime,
                    payload: .uptime(seconds: uptime)))
                self.samplePublisher.send(SensorSample(
                    sensorID: .lowPower,
                    payload: .lowPower(enabled: lowPower)))
            }
        }

        appLog("[System] ✅ System sensors initialization complete")
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        appLog("[System] ■ Stopping system sensors")
        timer?.invalidate()
        timer = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    private func updateDiskSpace() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.last {
            if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path) {
                totalDiskSpace = (attrs[.systemSize] as? Int64) ?? 0
                freeDiskSpace = (attrs[.systemFreeSize] as? Int64) ?? 0
                usedDiskSpace = totalDiskSpace - freeDiskSpace
                appLog("[System] 💾 Disk: \(ByteCountFormatter.string(fromByteCount: freeDiskSpace, countStyle: .memory)) free / \(ByteCountFormatter.string(fromByteCount: totalDiskSpace, countStyle: .memory)) total")
            }
        }
    }

    private func updateCameraInfo() {
        isFrontCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        isRearCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        isFlashAvailable = AVCaptureDevice.default(for: .video)?.hasFlash ?? false
        appLog("[System] 📷 Front camera: \(isFrontCameraAvailable), Rear: \(isRearCameraAvailable), Flash: \(isFlashAvailable)")
    }

    private func updateOrientation() {
        switch UIDevice.current.orientation {
        case .portrait: orientationKey = "orientation.portrait"
        case .portraitUpsideDown: orientationKey = "orientation.portraitupsidedown"
        case .landscapeLeft: orientationKey = "orientation.landscapeleft"
        case .landscapeRight: orientationKey = "orientation.landscaperight"
        case .faceUp: orientationKey = "orientation.faceup"
        case .faceDown: orientationKey = "orientation.facedown"
        case .unknown: orientationKey = "orientation.unknown"
        @unknown default: orientationKey = "orientation.unknown"
        }
    }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "battery.unknown"
        case .unplugged: return "battery.unplugged"
        case .charging: return "battery.charging"
        case .full: return "battery.full"
        @unknown default: return "battery.unknown"
        }
    }

    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "thermal.nominal"
        case .fair: return "thermal.fair"
        case .serious: return "thermal.serious"
        case .critical: return "thermal.critical"
        @unknown default: return "thermal.unknown"
        }
    }

    private func batteryStateLowercase(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }

    private func thermalStateLowercase(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "nominal"
        }
    }

    private func orientationLowercase(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
}
