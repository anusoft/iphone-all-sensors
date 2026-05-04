import SwiftUI

struct LightDetailView: View {
    @EnvironmentObject var env: EnvironmentSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.0f%%", env.screenBrightness * 100))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("Screen Brightness")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Adjust Brightness")
                        .font(.headline)
                    Slider(value: Binding(
                        get: { env.screenBrightness },
                        set: { env.setScreenBrightness($0) }
                    ), in: 0...1)
                    .tint(.yellow)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ambient Light")
        .navigationBarTitleDisplayMode(.inline)
    }
}
