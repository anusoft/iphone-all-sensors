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
                DataRow(label: locManager.t("label.heartRate"), value: locManager.t("unit.bpm"), icon: "heart.fill")
                DataRow(label: locManager.t("label.hrv"), value: locManager.t("unit.ms"), icon: "heart.text.square")
                DataRow(label: locManager.t("label.spo2"), value: locManager.t("unit.percent"), icon: "lungs")
                DataRow(label: locManager.t("label.steps"), value: locManager.t("unit.steps"), icon: "figure.walk")
                DataRow(label: locManager.t("label.distance"), value: locManager.t("unit.meters"), icon: "ruler")
                DataRow(label: locManager.t("label.bloodPressure"), value: locManager.t("unit.mmhg"), icon: "drop.fill")
                DataRow(label: locManager.t("label.bodyTemperature"), value: locManager.t("unit.celsius"), icon: "thermometer")
                DataRow(label: locManager.t("label.respiratoryRate"), value: locManager.t("unit.brmin"), icon: "wind")
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
                    Label(locManager.t(health.authorizationStatus), systemImage: "heart.text.square")
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    Spacer()
                }

                if let error = health.authorizationError {
                    Text(localizedManagerText(error))
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text(localizedManagerText(health.latestFetchStatus))
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
                        health.hasRequestedAuthorization ? locManager.t("health.refreshData") : locManager.t("permission.continue"),
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
                DataRow(label: locManager.t("label.heartRate"), value: LocalizedDisplayValue.number("%.0f", health.heartRate, unitKey: "unit.bpm", localization: locManager), icon: "heart.fill")
                DataRow(label: locManager.t("label.hrv"), value: LocalizedDisplayValue.number("%.0f", health.heartRateVariability, unitKey: "unit.ms", localization: locManager), icon: "heart.text.square")
                DataRow(label: locManager.t("label.spo2"), value: LocalizedDisplayValue.numberNoSpace("%.0f", health.oxygenSaturation, unitKey: "unit.percent", localization: locManager), icon: "lungs")
                DataRow(label: locManager.t("label.respiratoryRate"), value: LocalizedDisplayValue.number("%.0f", health.respiratoryRate, unitKey: "unit.brmin", localization: locManager), icon: "wind")
                DataRow(label: locManager.t("label.bodyTemperature"), value: LocalizedDisplayValue.numberNoSpace("%.1f", health.bodyTemperature, unitKey: "unit.celsius", localization: locManager), icon: "thermometer")
                DataRow(label: locManager.t("label.bloodPressure"), value: LocalizedDisplayValue.ratio("%.0f/%.0f", health.bloodPressureSystolic, health.bloodPressureDiastolic, unitKey: "unit.mmhg", localization: locManager), icon: "drop.fill")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.activityToday"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.steps"), value: String(format: "%.0f", health.stepCount), icon: "figure.walk")
                DataRow(label: locManager.t("label.distance"), value: LocalizedDisplayValue.number("%.1f", health.distanceWalkingRunning, unitKey: "unit.meters", localization: locManager), icon: "ruler")
                DataRow(label: locManager.t("label.flightsClimbed"), value: String(format: "%.0f", health.flightsClimbed), icon: "stairs")
                DataRow(label: locManager.t("label.activeEnergy"), value: LocalizedDisplayValue.number("%.0f", health.activeEnergyBurned, unitKey: "unit.kcal", localization: locManager), icon: "flame")
                DataRow(label: locManager.t("label.exerciseTime"), value: LocalizedDisplayValue.number("%.0f", health.exerciseTime, unitKey: "unit.min", localization: locManager), icon: "timer")
                DataRow(label: locManager.t("label.standTime"), value: LocalizedDisplayValue.number("%.0f", health.standTime, unitKey: "unit.min", localization: locManager), icon: "figure.stand")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.bodyMeasurements"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.height"), value: LocalizedDisplayValue.number("%.2f", health.height, unitKey: "unit.meters", localization: locManager), icon: "ruler")
                DataRow(label: locManager.t("label.weight"), value: LocalizedDisplayValue.number("%.1f", health.bodyMass, unitKey: "unit.kg", localization: locManager), icon: "scalemass")
                DataRow(label: locManager.t("label.bmi"), value: String(format: "%.1f", health.bodyMassIndex), icon: "figure")
                DataRow(label: locManager.t("label.bodyFat"), value: LocalizedDisplayValue.numberNoSpace("%.1f", health.bodyFatPercentage, unitKey: "unit.percent", localization: locManager), icon: "percent")
                DataRow(label: locManager.t("label.leanMass"), value: LocalizedDisplayValue.number("%.1f", health.leanBodyMass, unitKey: "unit.kg", localization: locManager), icon: "figure.arms.open")
            }
            .padding()
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(locManager.t("section.profile"))
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                DataRow(label: locManager.t("label.biologicalSex"), value: localizedSex(health.biologicalSex), icon: "person")
                DataRow(label: locManager.t("label.bloodType"), value: localizedBloodType(health.bloodType), icon: "drop")
                if let dob = health.dateOfBirth {
                    DataRow(label: locManager.t("label.dateOfBirth"), value: dob.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
            }
            .padding()
            .glassCard()
        }
    }

    private func localizedManagerText(_ status: String) -> String {
        let localized = locManager.t(status)
        return localized == status && !status.contains(".") ? status : localized
    }

    private func localizedSex(_ value: String) -> String {
        switch value {
        case "Female": return locManager.t("sex.female")
        case "Male": return locManager.t("sex.male")
        case "Other": return locManager.t("sex.other")
        case "Not Set": return locManager.t("sex.notSet")
        default: return locManager.t("sex.unknown")
        }
    }

    private func localizedBloodType(_ value: String) -> String {
        if value == "Not Set" {
            return locManager.t("blood.notSet")
        }
        if value == "Unknown" {
            return locManager.t("blood.unknown")
        }
        let key = value.lowercased()
            .replacingOccurrences(of: "+", with: "plus")
            .replacingOccurrences(of: "-", with: "minus")
            .replacingOccurrences(of: " ", with: "")
        return locManager.t("blood.\(key)")
    }
}
