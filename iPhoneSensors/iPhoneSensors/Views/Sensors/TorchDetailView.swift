import SwiftUI

struct TorchDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var cam: CameraSensorManager
    @State private var torchLevel: Float = 0

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: torchLevel > 0 ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(torchLevel > 0 ? .yellow : .gray)
                    Text(torchLevel > 0 ? locManager.t("value.on") : locManager.t("value.off"))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.torchLevel"))
                        .font(.headline)
                    Slider(value: $torchLevel, in: 0...1)
                        .tint(.yellow)
                        .onChange(of: torchLevel) { _, newValue in
                            cam.setTorch(level: newValue)
                        }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.details"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.available"), value: cam.isTorchAvailable ? locManager.t("value.yes") : locManager.t("value.no"), icon: "flashlight.on.fill")
                    DataRow(label: locManager.t("label.level"), value: LocalizedDisplayValue.numberNoSpace("%.0f", Double(torchLevel) * 100, unitKey: "unit.percent", localization: locManager), icon: "slider.horizontal.3")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.torch)
        .showOffEntry(sensorID: "21", accent: SO.torchAccent)
        .navigationTitle(locManager.t("sensor.torch"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        .onAppear { torchLevel = cam.torchLevel }
    }
}
