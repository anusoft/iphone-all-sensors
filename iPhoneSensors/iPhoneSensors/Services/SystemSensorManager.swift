import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
class SystemSensorManager: ObservableObject {
    @Published var batteryLevel: Float = 0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var batteryStateText: String = "Unknown"
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
    @Published var thermalStateText: String = "Nominal"
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

    @Published var orientationText: String = "Unknown"
    @Published var isMultitaskGestureEnabled = true

    private var timer: Timer?

    func startUpdates() {
        print("[System] ── Starting System Sensors ──")

        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        isBatteryMonitoringEnabled = true
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
        batteryStateText = batteryStateString(device.batteryState)

        deviceName = device.name
        deviceModel = device.model
        deviceLocalizedModel = device.localizedModel
        systemName = device.systemName
        systemVersion = device.systemVersion
        deviceIdentifierForVendor = device.identifierForVendor?.uuidString ?? "N/A"

        print("[System] Device: \(deviceName)")
        print("[System] Model: \(deviceModel)")
        print("[System] System: \(systemName) \(systemVersion)")
        print("[System] Battery: \(batteryLevel * 100)% (\(batteryStateText))")
        print("[System] Identifier: \(deviceIdentifierForVendor)")

        screenBounds = UIScreen.main.bounds
        screenScale = UIScreen.main.scale
        screenNativeScale = UIScreen.main.nativeScale
        screenBrightness = UIScreen.main.brightness

        print("[System] Screen: \(Int(screenBounds.width))x\(Int(screenBounds.height)) @\(screenScale)x")

        let processInfo = ProcessInfo.processInfo
        isMultitaskingSupported = true
        thermalState = processInfo.thermalState
        thermalStateText = thermalStateString(processInfo.thermalState)
        processorCount = processInfo.processorCount
        activeProcessorCount = processInfo.activeProcessorCount
        physicalMemory = processInfo.physicalMemory
        systemUptime = processInfo.systemUptime
        isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled

        print("[System] Processor: \(activeProcessorCount)/\(processorCount) cores")
        print("[System] Memory: \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory))")
        print("[System] Thermal: \(thermalStateText)")
        print("[System] Low Power Mode: \(isLowPowerModeEnabled)")
        print("[System] Uptime: \(String(format: "%.0f", systemUptime))s")

        updateDiskSpace()
        updateCameraInfo()
        updateOrientation()

        NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.batteryLevel = UIDevice.current.batteryLevel
                print("[System] 🔋 Battery: \(UIDevice.current.batteryLevel * 100)%")
            }
        }
        NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.batteryState = UIDevice.current.batteryState
                self?.batteryStateText = self?.batteryStateString(UIDevice.current.batteryState) ?? "Unknown"
                print("[System] 🔋 Battery state: \(self?.batteryStateText ?? "Unknown")")
            }
        }
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.updateOrientation()
            }
        }
        NotificationCenter.default.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.thermalState = ProcessInfo.processInfo.thermalState
                self?.thermalStateText = self?.thermalStateString(ProcessInfo.processInfo.thermalState) ?? "Unknown"
                print("[System] 🌡️ Thermal state: \(self?.thermalStateText ?? "Unknown")")
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.systemUptime = ProcessInfo.processInfo.systemUptime
                self?.screenBrightness = UIScreen.main.brightness
                self?.isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                self?.updateDiskSpace()
            }
        }

        print("[System] ✅ System sensors initialization complete")
    }

    func stopUpdates() {
        print("[System] ■ Stopping system sensors")
        timer?.invalidate()
        timer = nil
    }

    private func updateDiskSpace() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.last {
            if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path) {
                totalDiskSpace = (attrs[.systemSize] as? Int64) ?? 0
                freeDiskSpace = (attrs[.systemFreeSize] as? Int64) ?? 0
                usedDiskSpace = totalDiskSpace - freeDiskSpace
                print("[System] 💾 Disk: \(ByteCountFormatter.string(fromByteCount: freeDiskSpace, countStyle: .memory)) free / \(ByteCountFormatter.string(fromByteCount: totalDiskSpace, countStyle: .memory)) total")
            }
        }
    }

    private func updateCameraInfo() {
        isFrontCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        isRearCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        isFlashAvailable = AVCaptureDevice.default(for: .video)?.hasFlash ?? false
        print("[System] 📷 Front camera: \(isFrontCameraAvailable), Rear: \(isRearCameraAvailable), Flash: \(isFlashAvailable)")
    }

    private func updateOrientation() {
        switch UIDevice.current.orientation {
        case .portrait: orientationText = "Portrait"
        case .portraitUpsideDown: orientationText = "Portrait Upside Down"
        case .landscapeLeft: orientationText = "Landscape Left"
        case .landscapeRight: orientationText = "Landscape Right"
        case .faceUp: orientationText = "Face Up"
        case .faceDown: orientationText = "Face Down"
        case .unknown: orientationText = "Unknown"
        @unknown default: orientationText = "Unknown"
        }
    }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }

    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
