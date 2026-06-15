import Foundation
import CoreMotion
import Combine
import UserNotifications

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
    @Published var calMagAccuracy: String = "magaccuracy.unknown"
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
    @Published var activityState: String = "activity.unknown"
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

    /// Stream of sensor samples for the logging pipeline.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    // Seismometer
    @Published var isSeismometerEnabled = false
    @Published var seismometerThreshold: Double = 1.5
    @Published var seismometerAlarmHistory: [SeismometerAlarm] = []
    private var lastAlarmTime: Date = .distantPast

    // Barometer Session Tracking
    @Published var isBarometerTracking = false
    @Published var barometerBaseline: Double = 0
    @Published var barometerMaxDelta: Double = 0
    @Published var barometerElevationChange: Double = 0
    @Published var barometerTrend: String = "stable"
    @Published var barometerWeatherPrediction: String = ""
    private var barometerTrackingStartTime: Date?
    private var barometerSessionValues: [Double] = []

    struct SeismometerAlarm: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let magnitude: Double
        let axis: String
    }

    private var isStarted = false
    private var accUpdateCount = 0
    private var gyroUpdateCount = 0
    private var dmUpdateCount = 0

    func startUpdates() {
        guard !isStarted else {
            appLog("[Motion] ⚠ Already started")
            return
        }
        isStarted = true
        appLog("[Motion] ═══════════════════════════════════")
        appLog("[Motion] STARTING MOTION SENSORS")
        appLog("[Motion] ═══════════════════════════════════")

        // Check availability
        isAccelerometerAvailable = motionManager.isAccelerometerAvailable
        isGyroscopeAvailable = motionManager.isGyroAvailable
        isMagnetometerAvailable = motionManager.isMagnetometerAvailable
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable

        appLog("[Motion] Device capabilities:")
        appLog("[Motion]   Accelerometer: \(isAccelerometerAvailable ? "✅" : "❌")")
        appLog("[Motion]   Gyroscope: \(isGyroscopeAvailable ? "✅" : "❌")")
        appLog("[Motion]   Magnetometer: \(isMagnetometerAvailable ? "✅" : "❌")")
        appLog("[Motion]   DeviceMotion: \(isDeviceMotionAvailable ? "✅" : "❌")")

        startAccelerometer()
        startGyroscope()
        startMagnetometer()
        startDeviceMotion()
        startPedometer()
        startAltimeter()
        startActivity()

        appLog("[Motion] ═══════════════════════════════════")
        appLog("[Motion] ALL MOTION SENSORS INITIALIZED")
        appLog("[Motion] ═══════════════════════════════════")
    }

    private func startAccelerometer() {
        guard isAccelerometerAvailable else {
            appLog("[Motion] ❌ Accelerometer not available")
            return
        }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                appLog("[Motion] ❌ Accelerometer error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                appLog("[Motion] ⚠ Accelerometer: nil data")
                return
            }
            self.accUpdateCount += 1
            self.accX = data.acceleration.x
            self.accY = data.acceleration.y
            self.accZ = data.acceleration.z
            self.samplePublisher.send(SensorSample(
                sensorID: .accelerometer,
                payload: .acceleration(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)))
            self.checkSeismometer()
            if self.accUpdateCount <= 3 || self.accUpdateCount % 100 == 0 {
                appLog("[Motion] 📊 Acc[\(self.accUpdateCount)]: x=\(String(format: "%.3f", data.acceleration.x)) y=\(String(format: "%.3f", data.acceleration.y)) z=\(String(format: "%.3f", data.acceleration.z))")
            }
        }
        appLog("[Motion] ✓ Accelerometer started (interval: 0.1s)")
    }

    private func checkSeismometer() {
        guard isSeismometerEnabled else { return }
        let mag = sqrt(accX * accX + accY * accY + accZ * accZ)
        guard mag >= seismometerThreshold else { return }
        // Debounce: minimum 2 seconds between alarms
        guard Date().timeIntervalSince(lastAlarmTime) >= 2.0 else { return }
        lastAlarmTime = Date()
        let axis: String
        if abs(accX) >= abs(accY) && abs(accX) >= abs(accZ) { axis = "X" }
        else if abs(accY) >= abs(accX) && abs(accY) >= abs(accZ) { axis = "Y" }
        else { axis = "Z" }
        let alarm = SeismometerAlarm(timestamp: Date(), magnitude: mag, axis: axis)
        seismometerAlarmHistory.append(alarm)
        // Keep only last 50 alarms
        if seismometerAlarmHistory.count > 50 {
            seismometerAlarmHistory.removeFirst(seismometerAlarmHistory.count - 50)
        }
        // Send local notification
        let content = UNMutableNotificationContent()
        let language = UserDefaults.standard.string(forKey: "appLanguage").flatMap(AppLanguage.init(rawValue:)) ?? .english
        content.title = Translations.get("seismometer.notificationTitle", language: language)
        content.body = String(format: Translations.get("seismometer.notificationBody", language: language), mag, axis)
        content.sound = .default
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        appLog("[Motion] 🚨 Seismometer alarm: \(String(format: "%.3f", mag))G on \(axis) axis")
    }

    func startBarometerTracking() {
        isBarometerTracking = true
        barometerBaseline = pressure
        barometerMaxDelta = 0
        barometerElevationChange = 0
        barometerTrend = "stable"
        barometerWeatherPrediction = ""
        barometerTrackingStartTime = Date()
        barometerSessionValues = [pressure]
        appLog("[Motion] 📊 Barometer tracking started. Baseline: \(String(format: "%.2f", pressure)) kPa")
    }

    func stopBarometerTracking() {
        isBarometerTracking = false
        barometerTrackingStartTime = nil
        barometerSessionValues = []
        appLog("[Motion] 📊 Barometer tracking stopped")
    }

    private func updateBarometerTracking() {
        guard isBarometerTracking else { return }
        let delta = pressure - barometerBaseline
        barometerMaxDelta = max(barometerMaxDelta, abs(delta))
        // Elevation formula: h = 44330 * (1 - (P/P0)^(1/5.255))
        barometerElevationChange = 44330 * (1 - pow(pressure / barometerBaseline, 1.0 / 5.255))
        barometerSessionValues.append(pressure)
        // Trend analysis (last 10 values, min 5 min)
        if barometerSessionValues.count >= 10 {
            let recent = Array(barometerSessionValues.suffix(10))
            let first = recent.first ?? pressure
            let last = recent.last ?? pressure
            let diff = last - first
            if diff > 0.1 {
                barometerTrend = "rising"
                barometerWeatherPrediction = "barometer.weather.improving"
            } else if diff < -0.1 {
                barometerTrend = "falling"
                barometerWeatherPrediction = "barometer.weather.storm"
            } else {
                barometerTrend = "stable"
                barometerWeatherPrediction = "barometer.weather.stable"
            }
        }
    }

    private func startGyroscope() {
        guard isGyroscopeAvailable else {
            appLog("[Motion] ❌ Gyroscope not available")
            return
        }
        motionManager.gyroUpdateInterval = 0.1
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                appLog("[Motion] ❌ Gyroscope error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self.gyroUpdateCount += 1
            self.gyroX = data.rotationRate.x
            self.gyroY = data.rotationRate.y
            self.gyroZ = data.rotationRate.z
            self.samplePublisher.send(SensorSample(
                sensorID: .gyroscope,
                payload: .rotationRate(x: data.rotationRate.x, y: data.rotationRate.y, z: data.rotationRate.z)))
            if self.gyroUpdateCount <= 3 || self.gyroUpdateCount % 100 == 0 {
                appLog("[Motion] 📊 Gyro[\(self.gyroUpdateCount)]: x=\(String(format: "%.3f", data.rotationRate.x)) y=\(String(format: "%.3f", data.rotationRate.y)) z=\(String(format: "%.3f", data.rotationRate.z))")
            }
        }
        appLog("[Motion] ✓ Gyroscope started")
    }

    private func startMagnetometer() {
        guard isMagnetometerAvailable else {
            appLog("[Motion] ❌ Magnetometer not available")
            return
        }
        motionManager.magnetometerUpdateInterval = 0.1
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                appLog("[Motion] ❌ Magnetometer error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self?.magX = data.magneticField.x
            self?.magY = data.magneticField.y
            self?.magZ = data.magneticField.z
            self?.samplePublisher.send(SensorSample(
                sensorID: .magnetometer,
                payload: .magneticField(x: data.magneticField.x, y: data.magneticField.y, z: data.magneticField.z, accuracy: 0)))
        }
        appLog("[Motion] ✓ Magnetometer started")
    }

    private func startDeviceMotion() {
        guard isDeviceMotionAvailable else {
            appLog("[Motion] ❌ DeviceMotion not available")
            return
        }
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                appLog("[Motion] ❌ DeviceMotion error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                appLog("[Motion] ⚠ DeviceMotion: nil data")
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
            self.samplePublisher.send(SensorSample(
                sensorID: .deviceMotion,
                payload: .deviceMotion(DeviceMotionPayload(
                    roll: data.attitude.roll, pitch: data.attitude.pitch, yaw: data.attitude.yaw,
                    gravityX: data.gravity.x, gravityY: data.gravity.y, gravityZ: data.gravity.z,
                    userAccX: data.userAcceleration.x, userAccY: data.userAcceleration.y, userAccZ: data.userAcceleration.z,
                    rotationX: data.rotationRate.x, rotationY: data.rotationRate.y, rotationZ: data.rotationRate.z,
                    quatW: data.attitude.quaternion.w, quatX: data.attitude.quaternion.x,
                    quatY: data.attitude.quaternion.y, quatZ: data.attitude.quaternion.z,
                    calMagX: data.magneticField.field.x, calMagY: data.magneticField.field.y, calMagZ: data.magneticField.field.z,
                    calMagAccuracy: Int(data.magneticField.accuracy.rawValue)))))
            if self.dmUpdateCount <= 3 || self.dmUpdateCount % 100 == 0 {
                appLog("[Motion] 📊 DM[\(self.dmUpdateCount)]: roll=\(String(format: "%.2f", data.attitude.roll)) pitch=\(String(format: "%.2f", data.attitude.pitch)) yaw=\(String(format: "%.2f", data.attitude.yaw))")
            }
        }
        appLog("[Motion] ✓ DeviceMotion started")
    }

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else {
            appLog("[Motion] ❌ Pedometer not available")
            return
        }
        isPedometerAvailable = true
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            if let error = error {
                appLog("[Motion] ❌ Pedometer error: \(error.localizedDescription)")
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
                self?.samplePublisher.send(SensorSample(
                    sensorID: .pedometer,
                    payload: .pedometer(PedometerPayload(
                        steps: data.numberOfSteps.intValue,
                        distance: data.distance?.doubleValue ?? 0,
                        floorsAscended: data.floorsAscended?.intValue ?? 0,
                        floorsDescended: data.floorsDescended?.intValue ?? 0,
                        pace: data.currentPace?.doubleValue,
                        cadence: data.currentCadence?.doubleValue))))
                appLog("[Motion] 🚶 Steps: \(data.numberOfSteps.intValue)")
            }
        }
        appLog("[Motion] ✓ Pedometer started")
    }

    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            appLog("[Motion] ❌ Altimeter not available")
            return
        }
        isAltimeterAvailable = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                appLog("[Motion] ❌ Altimeter error: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            self?.relativeAltitude = data.relativeAltitude.doubleValue
            self?.pressure = data.pressure.doubleValue
            self?.samplePublisher.send(SensorSample(
                sensorID: .altimeter,
                payload: .altitude(relative: data.relativeAltitude.doubleValue, pressure: data.pressure.doubleValue)))
            self?.updateBarometerTracking()
        }
        appLog("[Motion] ✓ Altimeter started")
    }

    private func startActivity() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            appLog("[Motion] ❌ Activity not available")
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
            let stateString: String = {
                if activity.walking { return "walking" }
                if activity.running { return "running" }
                if activity.cycling { return "cycling" }
                if activity.automotive { return "automotive" }
                if activity.stationary { return "stationary" }
                return "unknown"
            }()
            self?.samplePublisher.send(SensorSample(
                sensorID: .motionActivity,
                payload: .activity(ActivityPayload(state: stateString, confidence: Int(activity.confidence.rawValue)))))
            appLog("[Motion] 🏃 Activity: \(activity.activityTypes)")
        }
        appLog("[Motion] ✓ Activity started")
    }

    func setThrottle(_ throttled: Bool) {
        let interval = throttled ? 0.5 : 0.1
        guard motionManager.accelerometerUpdateInterval != interval else { return }
        motionManager.accelerometerUpdateInterval = interval
        motionManager.gyroUpdateInterval = interval
        motionManager.magnetometerUpdateInterval = interval
        motionManager.deviceMotionUpdateInterval = interval
        if isStarted {
            // Restart with new interval
            motionManager.stopAccelerometerUpdates()
            motionManager.stopGyroUpdates()
            motionManager.stopMagnetometerUpdates()
            motionManager.stopDeviceMotionUpdates()
            startAccelerometer()
            startGyroscope()
            startMagnetometer()
            startDeviceMotion()
            appLog("[Motion] ⏱ Update interval changed to \(interval)s (throttled: \(throttled))")
        }
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
        appLog("[Motion] ■ All stopped")
    }

    private func calibrationAccuracy(_ accuracy: CMMagneticFieldCalibrationAccuracy) -> String {
        switch accuracy {
        case .uncalibrated: return "magaccuracy.uncalibrated"
        case .low: return "magaccuracy.low"
        case .medium: return "magaccuracy.medium"
        case .high: return "magaccuracy.high"
        @unknown default: return "magaccuracy.unknown"
        }
    }
}

extension CMMotionActivity {
    var activityTypes: String {
        var types: [String] = []
        if stationary { types.append("activity.stationary") }
        if walking { types.append("activity.walking") }
        if running { types.append("activity.running") }
        if cycling { types.append("activity.cycling") }
        if automotive { types.append("activity.automotive") }
        if unknown { types.append("activity.unknown") }
        return types.isEmpty ? "activity.unknown" : types.joined(separator: ", ")
    }
}
