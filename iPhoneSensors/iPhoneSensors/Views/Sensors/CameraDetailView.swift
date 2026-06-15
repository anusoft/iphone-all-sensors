import SwiftUI

struct CameraDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var cam: CameraSensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)
                    Text(locManager.t("section.cameraSystem"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.availability"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.rearCamera"), value: cam.isRearCameraAvailable ? locManager.t("status.available") : locManager.t("status.unavailable"), icon: "camera.fill")
                    DataRow(label: locManager.t("label.frontCamera"), value: cam.isFrontCameraAvailable ? locManager.t("status.available") : locManager.t("status.unavailable"), icon: "camera")
                    DataRow(label: locManager.t("label.flash"), value: cam.isFlashAvailable ? locManager.t("status.available") : locManager.t("status.unavailable"), icon: "bolt.fill")
                    DataRow(label: locManager.t("label.torch"), value: cam.isTorchAvailable ? locManager.t("status.available") : locManager.t("status.unavailable"), icon: "flashlight.on.fill")
                    DataRow(label: locManager.t("label.maxZoom"), value: LocalizedDisplayValue.numberNoSpace("%.1f", cam.maxZoomFactor, unitKey: "unit.scale", localization: locManager), icon: "plus.magnifyingglass")
                    DataRow(label: locManager.t("label.cameraAccess"), value: cam.cameraAccessGranted ? locManager.t("value.granted") : locManager.t("value.notGranted"), icon: "lock.shield")
                    DataRow(label: locManager.t("label.microphoneAccess"), value: cam.microphoneAccessGranted ? locManager.t("value.granted") : locManager.t("value.notGranted"), icon: "mic.fill")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.audioSession"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.category"), value: locManager.t("audiocategory." + cam.audioSessionCategory.lowercased().replacingOccurrences(of: " ", with: "")), icon: "speaker.wave.2")
                    DataRow(label: locManager.t("label.sampleRate"), value: LocalizedDisplayValue.number("%.0f", cam.audioSampleRate, unitKey: "unit.hz", localization: locManager), icon: "waveform")
                    DataRow(label: locManager.t("label.inputChannels"), value: "\(cam.audioInputChannels)", icon: "speaker.wave.2")
                }
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.camera)
        .showOffEntry(sensorID: "18", accent: SO.camAccent)
        .navigationTitle(locManager.t("sensor.camera"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
