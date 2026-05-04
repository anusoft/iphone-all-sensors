import Foundation
import CoreMotion
import Combine

@MainActor
class MotionSensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()
    private let activityManager = CMMotionActivityManager()

    // MARK: - Published Properties
    @Published var accX: Double = 0
    @Published var accY: Double = 0
    @Published var accZ: Double = 0
    @Published var gyroX: Double = 0
    @Published var gyroY: Double = 0
    @Published var gyroZ: Double = 0
    @Published var magX: Double = 0
    @Published var magY: Double = 0
    @Published var magZ: Double = 0
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    @Published var yaw: Double = 0
    @Published var gravX: Double = 0
    @Published var gravY: Double = 0
    @Published var gravZ: Double = 0
    @Published var userAccX: Double = 0
    @Published var userAccY: Double = 0
    @Published var userAccZ: Double = 0
    @Published var rotX: Double = 0
    @Published var rotY: Double = 0
    @Published var rotZ: Double = 0
    @Published var calMagX: Double = 0
    @Published var calMagY: Double = 0
    @Published var calMagZ: Double = 0
    @Published var calMagAccuracy: String = "Unknown"
    @Published var quatW: Double = 1
    @Published var quatX: Double = 0
    @Published var quatY: Double = 0
    @Published var quatZ: Double = 0
    @Published var rotMat: [[Double]] = [[1,0,0],[0,1,0],[0,0,1]]

    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var floorsAscended: Int = 0
    @Published var floorsDescended: Int = 0
    @Published var pace: Double = 0
    @Published var cadence: Double = 0
    @Published var relativeAltitude: Double = 0
    @Published var pressure: Double = 0
    @Published var activityState: String = "Unknown"
    @Published var isWalking = false
    @Published var isRunning = false
    @Published var isCycling = false
    @Published var isAutomotive = false
    @Published var isStationary = false

    @Published var isAccelerometerAvailable = false
    @Published var isGyroscopeAvailable = false
    @Published var isMagnetometerAvailable = false
    @Published var isDeviceMotionAvailable = false
    @Published var isPedometerAvailable = false
    @Published var isAltimeterAvailable = false
    @Published var isActivityAvailable = false

    private var isStarted = false
    private var accUpdateCount = 0
    private var gyroUpdateCount = 0
    private var dmUpdateCount = 0

    func startUpdates() {
        guard !isStarted else {
            print("[Motion] ⚠ Already started")
            return
        }
        isStarted = true
        print("[Motion] ═══════════════════════════════════")
        print("[Motion] STARTING MOTION SENSORS")
        print("[Motion] ═══════════════════════════════════")

        // Check availability
        isAccelerometerAvailable = motionManager.isAccelerometerAvailable
        isGyroscopeAvailable = motionManager.isGyroAvailable
        isMagnetometerAvailable = motionManager.isMagnetometerAvailable
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable

        print("[Motion] Device capabilities:")
        print("[Motion]   Accelerometer: \(isAccelerometerAvailable ? "✅" : "❌")")
        print("[Motion]   Gyroscope: \(isGyroscopeAvailable ? "✅" : "❌")")
        print("[Motion]   Magnetometer: \(isMagnetometerAvailable ? "✅" : "❌")")
        print("[Motion]   DeviceMotion: \(isDeviceMotionAvailable ? "✅" : "❌")")

        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
        startPedometer()
        startAltimeter()
        startActivity()

        print("[Motion] ═══════════════════════════════════")
        print("[Motion] ALL MOTION SENSORS INITIALIZED")
        print("[Motion] ═══════════════════════════════════")
    }

    private func startAccelerometer() {
        guard isAccelerometerAvailable else {
            print("[Motion] ❌ Accelerometer not available")
            return
        }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("[Motion] ❌ Accelerometer error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("[Motion] ⚠ Accelerometer: nil data")
                return
            }
            self.accUpdateCount += 1
            self.accX = data.acceleration.x
            self.accY = data.acceleration.y
            self.accZ = data.acceleration.z
            if self.accUpdateCount <= 3 || self.accUpdateCount % 100 == 0 {
                print("[Motion] 📊 Acc[\(self.accUpdateCount)]: x=\(String(format: "%.3f", data.acceleration.x)) y=\(String(format: "%.3f", data.acceleration.y)) z=\(String(format: "%.3f", data.acceleration.z))")
            }
        }
        print("[Motion] ✓ Accelerometer started (interval: 0.1s)")
    }

    private func startGyroscope() {
        guard isGyroscopeAvailable else {
            print("[Motion] ❌ Gyroscope not available")
            return
        }
        motionManager.gyroUpdateInterval = 0.1
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("[Motion] ❌ Gyroscope error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self.gyroUpdateCount += 1
            self.gyroX = data.rotationRate.x
            self.gyroY = data.rotationRate.y
            self.gyroZ = data.rotationRate.z
            if self.gyroUpdateCount <= 3 || self.gyroUpdateCount % 100 == 0 {
                print("[Motion] 📊 Gyro[\(self.gyroUpdateCount)]: x=\(String(format: "%.3f", data.rotationRate.x)) y=\(String(format: "%.3f", data.rotationRate.y)) z=\(String(format: "%.3f", data.rotationRate.z))")
            }
        }
        print("[Motion] ✓ Gyroscope started")
    }

    private func startMagnetometer() {
        guard isMagnetometerAvailable else {
            print("[Motion] ❌ Magnetometer not available")
            return
        }
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                print("[Motion] ❌ Magnetometer error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self?.magX = data.magneticField.x
            self?.magY = data.magneticField.y
            self?.magZ = data.magneticField.z
        }
        print("[Motion] ✓ Magnetometer started")
    }

    private func startDeviceMotion() {
        guard isDeviceMotionAvailable else {
            print("[Motion] ❌ DeviceMotion not available")
            return
        }
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                print("[Motion] ❌ DeviceMotion error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("[Motion] ⚠ DeviceMotion: nil data")
                return
            }
            self.dmUpdateCount += 1
            self.roll = data.attitude.roll
            self.pitch = data.attitude.pitch
            self.yaw = data.attitude.yaw
            self.gravX = data.gravity.x
            self.gravY = data.gravity.y
            self.gravZ = data.gravity.z
            self.userAccX = data.userAcceleration.x
            self.userAccY = data.userAcceleration.y
            self.userAccZ = data.userAcceleration.z
            self.rotX = data.rotationRate.x
            self.rotY = data.rotationRate.y
            self.rotZ = data.rotationRate.z
            self.calMagX = data.magneticField.field.x
            self.calMagY = data.magneticField.field.y
            self.calMagZ = data.magneticField.field.z
            self.calMagAccuracy = self.calibrationAccuracy(data.magneticField.accuracy)
            self.quatW = data.attitude.quaternion.w
            self.quatX = data.attitude.quaternion.x
            self.quatY = data.attitude.quaternion.y
            self.quatZ = data.attitude.quaternion.z
            let m = data.attitude.rotationMatrix
            self.rotMat = [[m.m11, m.m12, m.m13],[m.m21, m.m22, m.m23],[m.m31, m.m32, m.m33]]
            if self.dmUpdateCount <= 3 || self.dmUpdateCount % 100 == 0 {
                print("[Motion] 📊 DM[\(self.dmUpdateCount)]: roll=\(String(format: "%.2f", data.attitude.roll)) pitch=\(String(format: "%.2f", data.attitude.pitch)) yaw=\(String(format: "%.2f", data.attitude.yaw))")
            }
        }
        print("[Motion] ✓ DeviceMotion started")
    }

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("[Motion] ❌ Pedometer not available")
            return
        }
        isPedometerAvailable = true
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            if let error = error {
                print("[Motion] ❌ Pedometer error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            Task { @MainActor [weak self] in
                self?.steps = data.numberOfSteps.intValue
                self?.distance = data.distance?.doubleValue ?? 0
                self?.floorsAscended = data.floorsAscended?.intValue ?? 0
                self?.floorsDescended = data.floorsDescended?.intValue ?? 0
                self?.pace = data.currentPace?.doubleValue ?? 0
                self?.cadence = data.currentCadence?.doubleValue ?? 0
                print("[Motion] 🚶 Steps: \(data.numberOfSteps.intValue)")
            }
        }
        print("[Motion] ✓ Pedometer started")
    }

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("[Motion] ❌ Altimeter not available")
            return
        }
        isAltimeterAvailable = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                print("[Motion] ❌ Altimeter error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self?.relativeAltitude = data.relativeAltitude.doubleValue
            self?.pressure = data.pressure.doubleValue
        }
        print("[Motion] ✓ Altimeter started")
    }

    private func startActivity() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("[Motion] ❌ Activity not available")
            return
        }
        isActivityAvailable = true
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity = activity else { return }
            self?.activityState = activity.activityTypes
            self?.isWalking = activity.walking
            self?.isRunning = activity.running
            self?.isCycling = activity.cycling
            self?.isAutomotive = activity.automotive
            self?.isStationary = activity.stationary
            print("[Motion] 🏃 Activity: \(activity.activityTypes)")
        }
        print("[Motion] ✓ Activity started")
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        pedometer.stopUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        activityManager.stopActivityUpdates()
        print("[Motion] ■ All stopped")
    }

    private func calibrationAccuracy(_ accuracy: CMMagneticFieldCalibrationAccuracy) -> String {
        switch accuracy {
        case .uncalibrated: return "Uncalibrated"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}

extension CMMotionActivity {
    var activityTypes: String {
        var types: [String] = []
        if stationary { types.append("Stationary") }
        if walking { types.append("Walking") }
        if running { types.append("Running") }
        if cycling { types.append("Cycling") }
        if automotive { types.append("Automotive") }
        if unknown { types.append("Unknown") }
        return types.isEmpty ? "Unknown" : types.joined(separator: ", ")
    }
}
