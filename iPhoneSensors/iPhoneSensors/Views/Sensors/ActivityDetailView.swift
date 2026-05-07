import SwiftUI

struct ActivityDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text(locManager.t("section.currentActivity"))
                        .font(.headline)
                    Text(motion.activityState.split(separator: ", ").map { locManager.t(String($0)) }.joined(separator: ", "))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .glassCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ActivityTile(title: locManager.t("activity.stationary"), icon: "figure.stand", isActive: motion.isStationary, color: .gray)
                    ActivityTile(title: locManager.t("activity.walking"), icon: "figure.walk", isActive: motion.isWalking, color: .green)
                    ActivityTile(title: locManager.t("activity.running"), icon: "figure.run", isActive: motion.isRunning, color: .orange)
                    ActivityTile(title: locManager.t("activity.cycling"), icon: "figure.outdoor.cycle", isActive: motion.isCycling, color: .blue)
                    ActivityTile(title: locManager.t("activity.automotive"), icon: "car.fill", isActive: motion.isAutomotive, color: .purple)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("label.status"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.available"), value: motion.isActivityAvailable ? locManager.t("value.yes") : locManager.t("value.no"), icon: "checkmark.circle")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(locManager.t("sensor.activity"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}

struct ActivityTile: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(isActive ? color : .gray.opacity(0.4))
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isActive ? color.opacity(0.1) : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? color : Color.clear, lineWidth: 2)
        )
    }
}
