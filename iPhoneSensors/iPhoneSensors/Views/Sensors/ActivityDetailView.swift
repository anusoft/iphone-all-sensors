import SwiftUI

struct ActivityDetailView: View {
    @EnvironmentObject var motion: MotionSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Current Activity")
                        .font(.headline)
                    Text(motion.activityState)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ActivityTile(title: "Stationary", icon: "figure.stand", isActive: motion.isStationary, color: .gray)
                    ActivityTile(title: "Walking", icon: "figure.walk", isActive: motion.isWalking, color: .green)
                    ActivityTile(title: "Running", icon: "figure.run", isActive: motion.isRunning, color: .orange)
                    ActivityTile(title: "Cycling", icon: "figure.outdoor.cycle", isActive: motion.isCycling, color: .blue)
                    ActivityTile(title: "Automotive", icon: "car.fill", isActive: motion.isAutomotive, color: .purple)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)
                    DataRow(label: "Available", value: motion.isActivityAvailable ? "Yes" : "No", icon: "checkmark.circle")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Activity Recognition")
        .navigationBarTitleDisplayMode(.inline)
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
