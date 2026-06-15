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
            appLog("[SensorManager] Already started, skipping")
            return
        }
        appLog("[SensorManager] ▶ Starting all sensors...")
        isStarted = true

        motionManager.startUpdates()
        appLog("[SensorManager] ✓ Motion manager started")

        locationManager.startUpdates()
        appLog("[SensorManager] ✓ Location manager started")

        environmentManager.startUpdates()
        environmentManager.subscribeToMotionAltitude(motionManager)
        appLog("[SensorManager] ✓ Environment manager started")

        systemManager.startUpdates()
        appLog("[SensorManager] ✓ System manager started")

        healthManager.startUpdates()
        appLog("[SensorManager] ✓ Health manager started")

        connectivityManager.startUpdates()
        appLog("[SensorManager] ✓ Connectivity manager started")

        cameraManager.startUpdates()
        appLog("[SensorManager] ✓ Camera manager started")

        updateThrottleState()
        appLog("[SensorManager] ✅ All sensors started")
    }

    func stopAllSensors() {
        appLog("[SensorManager] ■ Stopping all sensors...")
        isStarted = false
        motionManager.stopUpdates()
        locationManager.stopUpdates()
        environmentManager.stopUpdates()
        systemManager.stopUpdates()
        healthManager.stopUpdates()
        connectivityManager.stopUpdates()
        cameraManager.stopUpdates()
        appLog("[SensorManager] ✅ All sensors stopped")
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
                    appLog("[SensorManager] ⏸ Recording paused due to throttling")
                }
                appLog("[SensorManager] 🔒 Throttling activated: \(throttleReason)")
            } else {
                throttleReason = ""
                motionManager.setThrottle(false)
                appLog("[SensorManager] 🔓 Throttling deactivated")
            }
        }
    }

    // MARK: - Live value accessor (used by App Intents / Shortcuts)

    /// A formatted, human-readable snapshot of a single sensor's *current* live
    /// reading. Returns `nil` when the value isn't meaningfully available yet
    /// (e.g. location permission not granted, or no fix), so callers can report
    /// an honest "unavailable" instead of fabricating a number.
    func currentValue(for sensor: SensorType) -> String? {
        switch sensor {
        case .accelerometer:
            let m = (motionManager.accX * motionManager.accX
                     + motionManager.accY * motionManager.accY
                     + motionManager.accZ * motionManager.accZ).squareRoot()
            return String(format: "%.2f G", m)
        case .gyroscope:
            let m = (motionManager.gyroX * motionManager.gyroX
                     + motionManager.gyroY * motionManager.gyroY
                     + motionManager.gyroZ * motionManager.gyroZ).squareRoot()
            return String(format: "%.3f rad/s", m)
        case .magnetometer:
            let m = (motionManager.magX * motionManager.magX
                     + motionManager.magY * motionManager.magY
                     + motionManager.magZ * motionManager.magZ).squareRoot()
            return String(format: "%.1f µT", m)
        case .gps:
            guard locationManager.isAuthorized,
                  locationManager.latitude != 0 || locationManager.longitude != 0 else { return nil }
            return String(format: "%.5f, %.5f", locationManager.latitude, locationManager.longitude)
        case .compass:
            guard locationManager.isAuthorized else { return nil }
            return String(format: "%.0f°", locationManager.trueHeading)
        case .barometer:
            guard environmentManager.isAltimeterAvailable, environmentManager.pressure != 0 else { return nil }
            return String(format: "%.2f kPa", environmentManager.pressure)
        case .battery:
            guard systemManager.isBatteryMonitoringEnabled, systemManager.batteryLevel >= 0 else { return nil }
            return "\(Int((systemManager.batteryLevel * 100).rounded()))%"
        }
    }
}
