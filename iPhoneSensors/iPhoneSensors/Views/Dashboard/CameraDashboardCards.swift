import SwiftUI

struct CameraDashboardCards: View {
    @EnvironmentObject var cam: CameraSensorManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                CameraDetailView()
            } label: {
                SensorCard(
                    title: "Camera",
                    icon: "camera.fill",
                    value: cam.isRearCameraAvailable ? "Available" : "",
                    unit: "",
                    color: .yellow,
                    isAvailable: cam.isRearCameraAvailable
                )
            }
            NavigationLink {
                TorchDetailView()
            } label: {
                SensorCard(
                    title: "Torch",
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
