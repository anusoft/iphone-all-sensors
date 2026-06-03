import SwiftUI

struct CameraDashboardCards: View {
    @EnvironmentObject var cam: CameraSensorManager
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        AdaptiveCardGrid(spacing: 10) {
            NavigationLink {
                CameraDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.camera"),
                    icon: "camera.fill",
                    value: cam.isRearCameraAvailable ? locManager.t("status.available") : "",
                    unit: "",
                    color: .yellow,
                    isAvailable: cam.isRearCameraAvailable
                )
            }
            NavigationLink {
                TorchDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.torch"),
                    icon: "flashlight.on.fill",
                    value: cam.isTorchAvailable ? String(format: "%.0f%%", cam.torchLevel * 100) : "",
                    unit: "",
                    color: .orange,
                    isAvailable: cam.isTorchAvailable
                )
            }
        }
    }
}
