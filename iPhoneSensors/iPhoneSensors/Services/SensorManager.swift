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

    let healthKitEnabled = false
    @Published var isStarted = false
    @Published var isThrottled: Bool = false {
        didSet {
            guard oldValue != isThrottled else { return }
            let value = isThrottled
            let coord = loggingCoordinator
            Task { await coord?.setThrottled(value) }
        }
    }

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
        print("[SensorManager] ✓ Environment manager started")

        systemManager.startUpdates()
        print("[SensorManager] ✓ System manager started")

        if healthKitEnabled {
            healthManager.startUpdates()
            print("[SensorManager] ✓ Health manager started")
        } else {
            print("[SensorManager] ⏭ Health manager skipped (disabled)")
        }

        connectivityManager.startUpdates()
        print("[SensorManager] ✓ Connectivity manager started")

        cameraManager.startUpdates()
        print("[SensorManager] ✓ Camera manager started")

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
}
