import SwiftUI
import HealthKit

struct HealthView: View {
    @EnvironmentObject var sensorManager: SensorManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !sensorManager.healthKitEnabled {
                        HealthDisabledView()
                    } else {
                        HealthContent()
                            .environmentObject(sensorManager)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Health")
        }
    }
}

struct HealthDisabledView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Health Sensors Disabled")
                .font(.title2)
                .fontWeight(.bold)

            Text("HealthKit requires an Apple Developer account with HealthKit capability enabled. The code is implemented but currently disabled.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Available when enabled:")
                    .font(.headline)
                DataRow(label: "Heart Rate", value: "bpm", icon: "heart.fill")
                DataRow(label: "HRV", value: "ms", icon: "heart.text.square")
                DataRow(label: "SpO2", value: "%", icon: "lungs")
                DataRow(label: "Steps", value: "count", icon: "figure.walk")
                DataRow(label: "Distance", value: "meters", icon: "ruler")
                DataRow(label: "Blood Pressure", value: "mmHg", icon: "drop.fill")
                DataRow(label: "Body Temperature", value: "°C", icon: "thermometer")
                DataRow(label: "Respiratory Rate", value: "br/min", icon: "wind")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct HealthContent: View {
    @EnvironmentObject var sensorManager: SensorManager

    var body: some View {
        let health = sensorManager.healthManager
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vitals")
                    .font(.headline)
                DataRow(label: "Heart Rate", value: String(format: "%.0f bpm", health.heartRate), icon: "heart.fill")
                DataRow(label: "HRV", value: String(format: "%.0f ms", health.heartRateVariability), icon: "heart.text.square")
                DataRow(label: "SpO2", value: String(format: "%.0f%%", health.oxygenSaturation), icon: "lungs")
                DataRow(label: "Respiratory Rate", value: String(format: "%.0f br/min", health.respiratoryRate), icon: "wind")
                DataRow(label: "Body Temperature", value: String(format: "%.1f°C", health.bodyTemperature), icon: "thermometer")
                DataRow(label: "Blood Pressure", value: String(format: "%.0f/%.0f mmHg", health.bloodPressureSystolic, health.bloodPressureDiastolic), icon: "drop.fill")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Today")
                    .font(.headline)
                DataRow(label: "Steps", value: String(format: "%.0f", health.stepCount), icon: "figure.walk")
                DataRow(label: "Distance", value: String(format: "%.1f m", health.distanceWalkingRunning), icon: "ruler")
                DataRow(label: "Flights Climbed", value: String(format: "%.0f", health.flightsClimbed), icon: "stairs")
                DataRow(label: "Active Energy", value: String(format: "%.0f kcal", health.activeEnergyBurned), icon: "flame")
                DataRow(label: "Exercise Time", value: String(format: "%.0f min", health.exerciseTime), icon: "timer")
                DataRow(label: "Stand Time", value: String(format: "%.0f min", health.standTime), icon: "figure.stand")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 12) {
                Text("Body Measurements")
                    .font(.headline)
                DataRow(label: "Height", value: String(format: "%.2f m", health.height), icon: "ruler")
                DataRow(label: "Weight", value: String(format: "%.1f kg", health.bodyMass), icon: "scalemass")
                DataRow(label: "BMI", value: String(format: "%.1f", health.bodyMassIndex), icon: "figure")
                DataRow(label: "Body Fat", value: String(format: "%.1f%%", health.bodyFatPercentage), icon: "percent")
                DataRow(label: "Lean Mass", value: String(format: "%.1f kg", health.leanBodyMass), icon: "figure.arms.open")
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 12) {
                Text("Profile")
                    .font(.headline)
                DataRow(label: "Biological Sex", value: health.biologicalSex, icon: "person")
                DataRow(label: "Blood Type", value: health.bloodType, icon: "drop")
                if let dob = health.dateOfBirth {
                    DataRow(label: "Date of Birth", value: dob.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
