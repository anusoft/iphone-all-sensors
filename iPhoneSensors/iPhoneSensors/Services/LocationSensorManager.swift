import Foundation
import CoreLocation
import Combine

@MainActor
class LocationSensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var altitude: Double = 0
    @Published var speed: Double = 0
    @Published var course: Double = 0
    @Published var horizontalAccuracy: Double = 0
    @Published var verticalAccuracy: Double = 0
    @Published var speedAccuracy: Double = 0
    @Published var courseAccuracy: Double = 0
    @Published var floor: Int?
    @Published var timestamp: Date = Date()

    @Published var heading: Double = 0
    @Published var headingAccuracy: Double = 0
    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var headingTimestamp: Date = Date()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationAccuracy: CLAccuracyAuthorization = .reducedAccuracy
    @Published var isAuthorized = false
    @Published var authorizationDescription: String = "Not Determined"

    /// Stream of sensor samples for the logging pipeline.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    private var isStarted = false
    private var locationUpdateCount = 0
    private var headingUpdateCount = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        print("[Location] ── Manager initialized ──")
    }

    func startUpdates() {
        guard !isStarted else {
            print("[Location] ⚠ Already started")
            return
        }
        isStarted = true
        print("[Location] ═══════════════════════════════════")
        print("[Location] STARTING LOCATION SENSORS")
        print("[Location] ═══════════════════════════════════")
        print("[Location] Auth status: \(authorizationStatusString(locationManager.authorizationStatus))")

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()

        print("[Location] ✓ Location updates requested")
        print("[Location] ✓ Heading updates requested")
        print("[Location] ═══════════════════════════════════")
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        print("[Location] ■ Stopped")
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("[Location] ⚠ Empty locations")
            return
        }
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.locationUpdateCount += 1
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.altitude = location.altitude
            self.speed = location.speed
            self.course = location.course
            self.horizontalAccuracy = location.horizontalAccuracy
            self.verticalAccuracy = location.verticalAccuracy
            self.speedAccuracy = location.speedAccuracy
            self.courseAccuracy = location.courseAccuracy
            self.floor = location.floor?.level
            self.timestamp = location.timestamp
            self.samplePublisher.send(SensorSample(
                sensorID: .gps,
                payload: .location(LocationPayload(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude,
                    alt: location.altitude,
                    speed: location.speed,
                    course: location.course,
                    horizAccuracy: location.horizontalAccuracy,
                    vertAccuracy: location.verticalAccuracy,
                    speedAccuracy: location.speedAccuracy,
                    courseAccuracy: location.courseAccuracy,
                    floor: location.floor?.level))))
            if self.locationUpdateCount <= 5 || self.locationUpdateCount % 20 == 0 {
                print("[Location] 📍 #\(self.locationUpdateCount): \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude)) alt:\(String(format: "%.1f", location.altitude))m hAcc:\(String(format: "%.1f", location.horizontalAccuracy))m")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.headingUpdateCount += 1
            self.heading = newHeading.trueHeading
            self.headingAccuracy = newHeading.headingAccuracy
            self.magneticHeading = newHeading.magneticHeading
            self.trueHeading = newHeading.trueHeading
            self.headingTimestamp = newHeading.timestamp
            self.samplePublisher.send(SensorSample(
                sensorID: .heading,
                payload: .heading(
                    trueHeading: newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil,
                    magneticHeading: newHeading.magneticHeading,
                    accuracy: newHeading.headingAccuracy)))
            if self.headingUpdateCount <= 5 || self.headingUpdateCount % 20 == 0 {
                print("[Location] 🧭 #\(self.headingUpdateCount): true=\(String(format: "%.1f", newHeading.trueHeading))° mag=\(String(format: "%.1f", newHeading.magneticHeading))° acc=\(String(format: "%.1f", newHeading.headingAccuracy))°")
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = manager.authorizationStatus
            self.locationAccuracy = manager.accuracyAuthorization
            self.isAuthorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
            self.authorizationDescription = self.authorizationStatusString(manager.authorizationStatus)
            print("[Location] 🔐 Auth changed: \(self.authorizationDescription)")
            print("[Location] 🔐 Is authorized: \(self.isAuthorized)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] ❌ Error: \(error.localizedDescription)")
        if let clError = error as? CLError {
            print("[Location] ❌ CLOError code: \(clError.code.rawValue)")
        }
    }

    private func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
