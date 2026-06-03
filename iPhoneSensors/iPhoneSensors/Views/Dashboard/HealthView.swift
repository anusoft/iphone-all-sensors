import SwiftUI
import HealthKit

struct HealthView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sensorManager: SensorManager

    var body: some View {
        NavigationStack {
            ScrollView {
                HealthContent()
                    .environmentObject(sensorManager)
                    .responsivePage()
            }
            .appBackground()
            .navigationTitle(locManager.t("sensor.health"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        }
    }
}

struct HealthDisabledView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text(locManager.t("label.healthSensorsDisabled"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)

            Text(locManager.t("health.disabledDescription"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("label.availableWhenEnabled"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.heartRate"), value: "bpm", icon: "heart.fill")
                DataRow(label: locManager.t("label.hrv"), value: "ms", icon: "heart.text.square")
                DataRow(label: locManager.t("label.spo2"), value: "%", icon: "lungs")
                DataRow(label: locManager.t("label.steps"), value: "count", icon: "figure.walk")
                DataRow(label: locManager.t("label.distance"), value: "meters", icon: "ruler")
                DataRow(label: locManager.t("label.bloodPressure"), value: "mmHg", icon: "drop.fill")
                DataRow(label: locManager.t("label.bodyTemperature"), value: "°C", icon: "thermometer")
                DataRow(label: locManager.t("label.respiratoryRate"), value: "br/min", icon: "wind")
            }
            .padding()
            .glassCard()
        }
    }
}

struct HealthContent: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sensorManager: SensorManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let health = sensorManager.healthManager
        return AdaptiveCardGrid(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(health.authorizationStatus, systemImage: "heart.text.square")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    Spacer()
                }

                if let error = health.authorizationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text(health.latestFetchStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    if health.hasRequestedAuthorization {
                        health.refreshHealthData()
                    } else {
                        health.requestAuthorization()
                    }
                } label: {
                    Label(
                        health.hasRequestedAuthorization ? "Refresh Health Data" : "Allow Health Access",
                        systemImage: health.hasRequestedAuthorization ? "arrow.clockwise" : "heart.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!health.isHealthDataAvailable)
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.vitals"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.heartRate"), value: String(format: "%.0f bpm", health.heartRate), icon: "heart.fill")
                DataRow(label: locManager.t("label.hrv"), value: String(format: "%.0f ms", health.heartRateVariability), icon: "heart.text.square")
                DataRow(label: locManager.t("label.spo2"), value: String(format: "%.0f%%", health.oxygenSaturation), icon: "lungs")
                DataRow(label: locManager.t("label.respiratoryRate"), value: String(format: "%.0f br/min", health.respiratoryRate), icon: "wind")
                DataRow(label: locManager.t("label.bodyTemperature"), value: String(format: "%.1f°C", health.bodyTemperature), icon: "thermometer")
                DataRow(label: locManager.t("label.bloodPressure"), value: String(format: "%.0f/%.0f mmHg", health.bloodPressureSystolic, health.bloodPressureDiastolic), icon: "drop.fill")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.activityToday"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.steps"), value: String(format: "%.0f", health.stepCount), icon: "figure.walk")
                DataRow(label: locManager.t("label.distance"), value: String(format: "%.1f m", health.distanceWalkingRunning), icon: "ruler")
                DataRow(label: locManager.t("label.flightsClimbed"), value: String(format: "%.0f", health.flightsClimbed), icon: "stairs")
                DataRow(label: locManager.t("label.activeEnergy"), value: String(format: "%.0f kcal", health.activeEnergyBurned), icon: "flame")
                DataRow(label: locManager.t("label.exerciseTime"), value: String(format: "%.0f min", health.exerciseTime), icon: "timer")
                DataRow(label: locManager.t("label.standTime"), value: String(format: "%.0f min", health.standTime), icon: "figure.stand")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.bodyMeasurements"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.height"), value: String(format: "%.2f m", health.height), icon: "ruler")
                DataRow(label: locManager.t("label.weight"), value: String(format: "%.1f kg", health.bodyMass), icon: "scalemass")
                DataRow(label: locManager.t("label.bmi"), value: String(format: "%.1f", health.bodyMassIndex), icon: "figure")
                DataRow(label: locManager.t("label.bodyFat"), value: String(format: "%.1f%%", health.bodyFatPercentage), icon: "percent")
                DataRow(label: locManager.t("label.leanMass"), value: String(format: "%.1f kg", health.leanBodyMass), icon: "figure.arms.open")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.profile"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.biologicalSex"), value: locManager.t("sex." + health.biologicalSex.lowercased()), icon: "person")
                DataRow(label: locManager.t("label.bloodType"), value: locManager.t("blood." + health.bloodType.lowercased().replacingOccurrences(of: "+", with: "plus").replacingOccurrences(of: "-", with: "minus")), icon: "drop")
                if let dob = health.dateOfBirth {
                    DataRow(label: locManager.t("label.dateOfBirth"), value: dob.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
            }
            .padding()
            .glassCard()
        }
    }
}
