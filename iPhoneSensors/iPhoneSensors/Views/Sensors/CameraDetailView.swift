import SwiftUI

struct CameraDetailView: View {
    @EnvironmentObject var cam: CameraSensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)
                    Text("Camera System")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Camera Availability")
                        .font(.headline)
                    DataRow(label: "Rear Camera", value: cam.isRearCameraAvailable ? "Available" : "Unavailable", icon: "camera.fill")
                    DataRow(label: "Front Camera", value: cam.isFrontCameraAvailable ? "Available" : "Unavailable", icon: "camera")
                    DataRow(label: "Flash", value: cam.isFlashAvailable ? "Available" : "Unavailable", icon: "bolt.fill")
                    DataRow(label: "Torch", value: cam.isTorchAvailable ? "Available" : "Unavailable", icon: "flashlight.on.fill")
                    DataRow(label: "Max Zoom", value: String(format: "%.1fx", cam.maxZoomFactor), icon: "plus.magnifyingglass")
                    DataRow(label: "Camera Access", value: cam.cameraAccessGranted ? "Granted" : "Not Granted", icon: "lock.shield")
                    DataRow(label: "Microphone Access", value: cam.microphoneAccessGranted ? "Granted" : "Not Granted", icon: "mic.fill")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Audio Session")
                        .font(.headline)
                    DataRow(label: "Category", value: cam.audioSessionCategory, icon: "speaker.wave.2")
                    DataRow(label: "Sample Rate", value: String(format: "%.0f Hz", cam.audioSampleRate), icon: "waveform")
                    DataRow(label: "Input Channels", value: "\(cam.audioInputChannels)", icon: "speaker.wave.2")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
    }
}
