import Foundation
import HealthKit
import Combine

@MainActor
class HealthSensorManager: ObservableObject {
    private let healthStore = HKHealthStore()
    static let authorizationRequestedKey = "healthAuthorizationRequested"
    private let authorizationRequestedKey = HealthSensorManager.authorizationRequestedKey

    /// Combine publisher emitting per-metric samples for the LoggingService.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    @Published var heartRate: Double = 0
    @Published var heartRateVariability: Double = 0
    @Published var oxygenSaturation: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var bodyTemperature: Double = 0
    @Published var bloodPressureSystolic: Double = 0
    @Published var bloodPressureDiastolic: Double = 0
    @Published var electrodermalActivity: Double = 0

    @Published var stepCount: Double = 0
    @Published var distanceWalkingRunning: Double = 0
    @Published var flightsClimbed: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var basalEnergyBurned: Double = 0
    @Published var exerciseTime: Double = 0
    @Published var standTime: Double = 0

    @Published var height: Double = 0
    @Published var bodyMass: Double = 0
    @Published var bodyMassIndex: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var waistCircumference: Double = 0
    @Published var biologicalSex: String = "Not Set"
    @Published var dateOfBirth: Date?
    @Published var bloodType: String = "Not Set"

    @Published var isHealthDataAvailable = false
    @Published var authorizationStatus: String = "health.status.needsPermission"
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var hasRequestedAuthorization: Bool
    @Published var latestFetchStatus: String = "health.fetch.initial"
    private var isStarted = false

    init() {
        hasRequestedAuthorization = UserDefaults.standard.bool(forKey: authorizationRequestedKey)
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        authorizationStatus = Self.authorizationStatusText(
            isHealthDataAvailable: isHealthDataAvailable,
            authorizationRequested: hasRequestedAuthorization,
            authorizationError: nil
        )
        isAuthorized = hasRequestedAuthorization && isHealthDataAvailable
    }

    nonisolated static func authorizationStatusText(
        isHealthDataAvailable: Bool,
        authorizationRequested: Bool,
        authorizationError: String?
    ) -> String {
        if authorizationError != nil { return "status.error" }
        guard isHealthDataAvailable else { return "status.unavailable" }
        return authorizationRequested ? "health.status.accessRequested" : "health.status.needsPermission"
    }

    func startUpdates() {
        guard !isStarted else {
            appLog("[Health] ⚠ Already started")
            return
        }
        isStarted = true
        appLog("[Health] ── Starting Health Sensors ──")
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        appLog("[Health] HealthKit available: \(isHealthDataAvailable)")

        guard isHealthDataAvailable else {
            appLog("[Health] ❌ HealthKit not available on this device")
            return
        }

        refreshAuthorizationState()

        if hasRequestedAuthorization {
            fetchAllHealthData()
        } else {
            appLog("[Health] ⏭ HealthKit permission has not been requested — skipping data fetch")
        }
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        appLog("[Health] ■ Stopping health sensors")
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        appLog("[Health] Requesting HealthKit authorization...")

        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        guard isHealthDataAvailable else {
            refreshAuthorizationState(error: nil)
            completion?(false)
            return
        }

        guard let readTypes = Self.healthReadTypes() else {
            let message = "health.error.typeUnavailable"
            authorizationError = message
            refreshAuthorizationState(error: message)
            appLog("[Health] ❌ A requested HealthKit data type is unavailable on this OS.")
            completion?(false)
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self else {
                    completion?(false)
                    return
                }
                if let error = error {
                    self.authorizationError = error.localizedDescription
                    appLog("[Health] ❌ Authorization error: \(error.localizedDescription)")
                } else {
                    self.authorizationError = nil
                }
                self.hasRequestedAuthorization = success
                UserDefaults.standard.set(success, forKey: self.authorizationRequestedKey)
                self.refreshAuthorizationState(error: error?.localizedDescription)
                appLog("[Health] Authorization request processed: \(success ? "request delivered" : "failed")")
                if success {
                    self.fetchAllHealthData()
                } else {
                    self.latestFetchStatus = "health.fetch.permissionFailed"
                }
                completion?(success)
            }
        }
    }

    func refreshHealthData() {
        refreshAuthorizationState()
        guard isHealthDataAvailable else { return }
        guard hasRequestedAuthorization else {
            requestAuthorization()
            return
        }
        fetchAllHealthData()
    }

    private func refreshAuthorizationState(error: String? = nil) {
        authorizationError = error
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        isAuthorized = isHealthDataAvailable && hasRequestedAuthorization && authorizationError == nil
        authorizationStatus = Self.authorizationStatusText(
            isHealthDataAvailable: isHealthDataAvailable,
            authorizationRequested: hasRequestedAuthorization,
            authorizationError: authorizationError
        )
    }

    nonisolated static func healthReadTypes() -> Set<HKObjectType>? {
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .respiratoryRate,
            .bodyTemperature,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .electrodermalActivity,
            .stepCount,
            .distanceWalkingRunning,
            .flightsClimbed,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .appleExerciseTime,
            .appleStandTime,
            .height,
            .bodyMass,
            .bodyMassIndex,
            .bodyFatPercentage,
            .leanBodyMass,
            .waistCircumference
        ]
        let characteristicTypes: [HKCharacteristicTypeIdentifier] = [
            .biologicalSex,
            .dateOfBirth,
            .bloodType
        ]

        let quantities = quantityTypes.compactMap(HKQuantityType.quantityType(forIdentifier:))
        let characteristics = characteristicTypes.compactMap(HKCharacteristicType.characteristicType(forIdentifier:))
        guard quantities.count == quantityTypes.count,
              characteristics.count == characteristicTypes.count else { return nil }

        return Set(quantities + characteristics)
    }

    private func fetchAllHealthData() {
        appLog("[Health] Fetching all health data...")
        latestFetchStatus = "health.fetch.loading"

        fetchLatestQuantity(.heartRate) { [weak self] value, ts in
            self?.heartRate = value
            self?.publishHealth(metric: "heartRate", value: value, unit: "count/min", ts: ts)
            appLog("[Health] Heart rate: \(value) bpm")
        }
        fetchLatestQuantity(.heartRateVariabilitySDNN) { [weak self] value, ts in
            self?.heartRateVariability = value
            self?.publishHealth(metric: "heartRateVariability", value: value, unit: "ms", ts: ts)
            appLog("[Health] HRV: \(value) ms")
        }
        fetchLatestQuantity(.oxygenSaturation) { [weak self] value, ts in
            self?.oxygenSaturation = value * 100
            self?.publishHealth(metric: "oxygenSaturation", value: value * 100, unit: "%", ts: ts)
            appLog("[Health] SpO2: \(value * 100)%")
        }
        fetchLatestQuantity(.respiratoryRate) { [weak self] value, ts in
            self?.respiratoryRate = value
            self?.publishHealth(metric: "respiratoryRate", value: value, unit: "count/min", ts: ts)
            appLog("[Health] Respiratory rate: \(value) br/min")
        }
        fetchLatestQuantity(.bodyTemperature) { [weak self] value, ts in
            self?.bodyTemperature = value
            self?.publishHealth(metric: "bodyTemperature", value: value, unit: "degC", ts: ts)
            appLog("[Health] Body temp: \(value)°C")
        }
        fetchLatestQuantity(.bloodPressureSystolic) { [weak self] value, ts in
            self?.bloodPressureSystolic = value
            self?.publishHealth(metric: "bloodPressureSystolic", value: value, unit: "mmHg", ts: ts)
            appLog("[Health] BP systolic: \(value) mmHg")
        }
        fetchLatestQuantity(.bloodPressureDiastolic) { [weak self] value, ts in
            self?.bloodPressureDiastolic = value
            self?.publishHealth(metric: "bloodPressureDiastolic", value: value, unit: "mmHg", ts: ts)
            appLog("[Health] BP diastolic: \(value) mmHg")
        }
        fetchLatestQuantity(.electrodermalActivity) { [weak self] value, ts in
            self?.electrodermalActivity = value
            self?.publishHealth(metric: "electrodermalActivity", value: value, unit: "count", ts: ts)
            appLog("[Health] EDA: \(value)")
        }
        fetchTodaySum(.stepCount) { [weak self] value, ts in
            self?.stepCount = value
            self?.publishHealth(metric: "stepCount", value: value, unit: "count", ts: ts)
            appLog("[Health] Steps today: \(value)")
        }
        fetchTodaySum(.distanceWalkingRunning) { [weak self] value, ts in
            self?.distanceWalkingRunning = value
            self?.publishHealth(metric: "walkingDistance", value: value, unit: "m", ts: ts)
            appLog("[Health] Distance today: \(value)m")
        }
        fetchTodaySum(.flightsClimbed) { [weak self] value, ts in
            self?.flightsClimbed = value
            self?.publishHealth(metric: "flightsClimbed", value: value, unit: "count", ts: ts)
            appLog("[Health] Flights today: \(value)")
        }
        fetchTodaySum(.activeEnergyBurned) { [weak self] value, ts in
            self?.activeEnergyBurned = value
            self?.publishHealth(metric: "activeEnergy", value: value, unit: "kcal", ts: ts)
            appLog("[Health] Active energy: \(value) kcal")
        }
        fetchTodaySum(.basalEnergyBurned) { [weak self] value, ts in
            self?.basalEnergyBurned = value
            self?.publishHealth(metric: "basalEnergy", value: value, unit: "kcal", ts: ts)
        }
        fetchTodaySum(.appleExerciseTime) { [weak self] value, ts in
            self?.exerciseTime = value
            self?.publishHealth(metric: "exerciseTime", value: value, unit: "min", ts: ts)
            appLog("[Health] Exercise time: \(value) min")
        }
        fetchTodaySum(.appleStandTime) { [weak self] value, ts in
            self?.standTime = value
            self?.publishHealth(metric: "standTime", value: value, unit: "count", ts: ts)
        }

        fetchLatestQuantity(.height) { [weak self] value, ts in
            self?.height = value
            self?.publishHealth(metric: "height", value: value, unit: "m", ts: ts)
        }
        fetchLatestQuantity(.bodyMass) { [weak self] value, ts in
            self?.bodyMass = value
            self?.publishHealth(metric: "bodyMass", value: value, unit: "kg", ts: ts)
        }
        fetchLatestQuantity(.bodyMassIndex) { [weak self] value, ts in
            self?.bodyMassIndex = value
            self?.publishHealth(metric: "bodyMassIndex", value: value, unit: "%", ts: ts)
        }
        fetchLatestQuantity(.bodyFatPercentage) { [weak self] value, ts in
            self?.bodyFatPercentage = value * 100
            self?.publishHealth(metric: "bodyFatPercentage", value: value * 100, unit: "%", ts: ts)
        }
        fetchLatestQuantity(.leanBodyMass) { [weak self] value, ts in
            self?.leanBodyMass = value
            self?.publishHealth(metric: "leanBodyMass", value: value, unit: "kg", ts: ts)
        }
        fetchLatestQuantity(.waistCircumference) { [weak self] value, ts in
            self?.waistCircumference = value
            self?.publishHealth(metric: "waistCircumference", value: value, unit: "m", ts: ts)
        }

        fetchCharacteristicData()
        latestFetchStatus = "health.fetch.queryStarted"
        appLog("[Health] ✅ Health data fetch initiated")
    }

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, completion: @escaping (Double, Date) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            appLog("[Health] ⚠ Unknown quantity type: \(identifier.rawValue)")
            return
        }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            Task { @MainActor in
                if let error = error {
                    appLog("[Health] ❌ Query error for \(identifier.rawValue): \(error.localizedDescription)")
                    self.latestFetchStatus = "health.fetch.queryError"
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    appLog("[Health] ⚠ No data for \(identifier.rawValue)")
                    return
                }
                let unit = self.preferredUnit(for: identifier)
                let value = sample.quantity.doubleValue(for: unit)
                completion(value, sample.endDate)
                self.latestFetchStatus = "health.fetch.loaded"
            }
        }
        healthStore.execute(query)
    }

    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, completion: @escaping (Double, Date) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            appLog("[Health] ⚠ Unknown quantity type: \(identifier.rawValue)")
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            Task { @MainActor in
                if let error = error {
                    appLog("[Health] ❌ Stats query error for \(identifier.rawValue): \(error.localizedDescription)")
                    self.latestFetchStatus = "health.fetch.queryError"
                    return
                }
                let unit = self.preferredUnit(for: identifier)
                guard let sum = result?.sumQuantity() else {
                    appLog("[Health] ⚠ No data for \(identifier.rawValue) today")
                    return
                }
                let value = sum.doubleValue(for: unit)
                completion(value, Date())
                self.latestFetchStatus = "health.fetch.loaded"
            }
        }
        healthStore.execute(query)
    }

    /// Helper to publish a single health metric sample on the publisher.
    private func publishHealth(metric: String, value: Double, unit: String, ts: Date) {
        samplePublisher.send(SensorSample(
            sensorID: .health,
            payload: .health(
                metric: metric,
                value: value,
                unit: unit,
                ts: ts
            )))
    }

    private func fetchCharacteristicData() {
        do {
            if let sex = try? healthStore.biologicalSex() {
                switch sex.biologicalSex {
                case .female: biologicalSex = "Female"
                case .male: biologicalSex = "Male"
                case .other: biologicalSex = "Other"
                case .notSet: biologicalSex = "Not Set"
                @unknown default: biologicalSex = "Unknown"
                }
                appLog("[Health] Biological sex: \(biologicalSex)")
            }
            if let dob = try? healthStore.dateOfBirthComponents() {
                dateOfBirth = dob.date
                appLog("[Health] DOB: \(dob.date?.formatted() ?? "N/A")")
            }
            if let blood = try? healthStore.bloodType() {
                switch blood.bloodType {
                case .aPositive: bloodType = "A+"
                case .aNegative: bloodType = "A-"
                case .bPositive: bloodType = "B+"
                case .bNegative: bloodType = "B-"
                case .abPositive: bloodType = "AB+"
                case .abNegative: bloodType = "AB-"
                case .oPositive: bloodType = "O+"
                case .oNegative: bloodType = "O-"
                case .notSet: bloodType = "Not Set"
                @unknown default: bloodType = "Unknown"
                }
                appLog("[Health] Blood type: \(bloodType)")
            }
        }
    }

    private func preferredUnit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .heartRate, .respiratoryRate: return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN: return .secondUnit(with: .milli)
        case .oxygenSaturation: return .percent()
        case .bodyTemperature: return .degreeCelsius()
        case .bloodPressureSystolic, .bloodPressureDiastolic: return .millimeterOfMercury()
        case .electrodermalActivity: return .count()
        case .stepCount, .flightsClimbed: return .count()
        case .distanceWalkingRunning, .waistCircumference: return .meter()
        case .activeEnergyBurned, .basalEnergyBurned: return .kilocalorie()
        case .appleExerciseTime, .appleStandTime: return .minute()
        case .height: return .meter()
        case .bodyMass, .leanBodyMass: return .gramUnit(with: .kilo)
        case .bodyMassIndex, .bodyFatPercentage: return .percent()
        default: return .count()
        }
    }
}
