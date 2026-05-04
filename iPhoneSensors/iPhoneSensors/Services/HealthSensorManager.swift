import Foundation
import HealthKit
import Combine

@MainActor
class HealthSensorManager: ObservableObject {
    private let healthStore = HKHealthStore()

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
    @Published var authorizationStatus: String = "Not Authorized"
    @Published var isAuthorized = false
    @Published var authorizationError: String?

    func startUpdates() {
        print("[Health] ── Starting Health Sensors ──")
        isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
        print("[Health] HealthKit available: \(isHealthDataAvailable)")

        guard isHealthDataAvailable else {
            print("[Health] ❌ HealthKit not available on this device")
            return
        }

        requestAuthorization()
    }

    func stopUpdates() {
        print("[Health] ■ Stopping health sensors")
    }

    func requestAuthorization() {
        print("[Health] Requesting HealthKit authorization...")

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .electrodermalActivity)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .waistCircumference)!,
            HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
            HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKCharacteristicType.characteristicType(forIdentifier: .bloodType)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                self?.isAuthorized = success
                self?.authorizationStatus = success ? "Authorized" : "Not Authorized"
                if let error = error {
                    self?.authorizationError = error.localizedDescription
                    print("[Health] ❌ Authorization error: \(error.localizedDescription)")
                }
                print("[Health] Authorization result: \(success ? "✅ Authorized" : "❌ Denied")")
                if success {
                    self?.fetchAllHealthData()
                }
            }
        }
    }

    private func fetchAllHealthData() {
        print("[Health] Fetching all health data...")

        fetchLatestQuantity(.heartRate) { [weak self] value in
            self?.heartRate = value
            print("[Health] Heart rate: \(value) bpm")
        }
        fetchLatestQuantity(.heartRateVariabilitySDNN) { [weak self] value in
            self?.heartRateVariability = value
            print("[Health] HRV: \(value) ms")
        }
        fetchLatestQuantity(.oxygenSaturation) { [weak self] value in
            self?.oxygenSaturation = value * 100
            print("[Health] SpO2: \(value * 100)%")
        }
        fetchLatestQuantity(.respiratoryRate) { [weak self] value in
            self?.respiratoryRate = value
            print("[Health] Respiratory rate: \(value) br/min")
        }
        fetchLatestQuantity(.bodyTemperature) { [weak self] value in
            self?.bodyTemperature = value
            print("[Health] Body temp: \(value)°C")
        }
        fetchLatestQuantity(.bloodPressureSystolic) { [weak self] value in
            self?.bloodPressureSystolic = value
            print("[Health] BP systolic: \(value) mmHg")
        }
        fetchLatestQuantity(.bloodPressureDiastolic) { [weak self] value in
            self?.bloodPressureDiastolic = value
            print("[Health] BP diastolic: \(value) mmHg")
        }
        fetchLatestQuantity(.electrodermalActivity) { [weak self] value in
            self?.electrodermalActivity = value
            print("[Health] EDA: \(value)")
        }
        fetchTodaySum(.stepCount) { [weak self] value in
            self?.stepCount = value
            print("[Health] Steps today: \(value)")
        }
        fetchTodaySum(.distanceWalkingRunning) { [weak self] value in
            self?.distanceWalkingRunning = value
            print("[Health] Distance today: \(value)m")
        }
        fetchTodaySum(.flightsClimbed) { [weak self] value in
            self?.flightsClimbed = value
            print("[Health] Flights today: \(value)")
        }
        fetchTodaySum(.activeEnergyBurned) { [weak self] value in
            self?.activeEnergyBurned = value
            print("[Health] Active energy: \(value) kcal")
        }
        fetchTodaySum(.basalEnergyBurned) { [weak self] value in
            self?.basalEnergyBurned = value
        }
        fetchTodaySum(.appleExerciseTime) { [weak self] value in
            self?.exerciseTime = value
            print("[Health] Exercise time: \(value) min")
        }
        fetchTodaySum(.appleStandTime) { [weak self] value in
            self?.standTime = value
        }

        fetchLatestQuantity(.height) { [weak self] value in self?.height = value }
        fetchLatestQuantity(.bodyMass) { [weak self] value in self?.bodyMass = value }
        fetchLatestQuantity(.bodyMassIndex) { [weak self] value in self?.bodyMassIndex = value }
        fetchLatestQuantity(.bodyFatPercentage) { [weak self] value in self?.bodyFatPercentage = value * 100 }
        fetchLatestQuantity(.leanBodyMass) { [weak self] value in self?.leanBodyMass = value }
        fetchLatestQuantity(.waistCircumference) { [weak self] value in self?.waistCircumference = value }

        fetchCharacteristicData()
        print("[Health] ✅ Health data fetch initiated")
    }

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("[Health] ⚠ Unknown quantity type: \(identifier.rawValue)")
            return
        }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("[Health] ❌ Query error for \(identifier.rawValue): \(error.localizedDescription)")
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                print("[Health] ⚠ No data for \(identifier.rawValue)")
                return
            }
            let unit = self.preferredUnit(for: identifier)
            let value = sample.quantity.doubleValue(for: unit)
            completion(value)
        }
        healthStore.execute(query)
    }

    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            print("[Health] ⚠ Unknown quantity type: \(identifier.rawValue)")
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("[Health] ❌ Stats query error for \(identifier.rawValue): \(error.localizedDescription)")
                return
            }
            let unit = self.preferredUnit(for: identifier)
            let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            completion(value)
        }
        healthStore.execute(query)
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
                print("[Health] Biological sex: \(biologicalSex)")
            }
            if let dob = try? healthStore.dateOfBirthComponents() {
                dateOfBirth = dob.date
                print("[Health] DOB: \(dob.date?.formatted() ?? "N/A")")
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
                print("[Health] Blood type: \(bloodType)")
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
        case .stepCount, .flightsClimbed, .appleStandTime: return .count()
        case .distanceWalkingRunning, .waistCircumference: return .meter()
        case .activeEnergyBurned, .basalEnergyBurned: return .kilocalorie()
        case .appleExerciseTime: return .minute()
        case .height: return .meter()
        case .bodyMass, .leanBodyMass: return .gramUnit(with: .kilo)
        case .bodyMassIndex, .bodyFatPercentage: return .percent()
        default: return .count()
        }
    }
}
