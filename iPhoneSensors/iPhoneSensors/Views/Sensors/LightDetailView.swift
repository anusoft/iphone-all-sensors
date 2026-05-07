import SwiftUI

struct LightDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
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
                    Text(locManager.t("section.screenBrightness"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.adjustBrightness"))
                        .font(.headline)
                    Slider(value: Binding(
                        get: { env.screenBrightness },
                        set: { env.setScreenBrightness($0) }
                    ), in: 0...1)
                    .tint(.yellow)
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Ambient Light")
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
