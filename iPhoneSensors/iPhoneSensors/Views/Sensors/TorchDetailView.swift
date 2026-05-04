import SwiftUI

struct TorchDetailView: View {
    @EnvironmentObject var cam: CameraSensorManager
    @State private var torchLevel: Float = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: torchLevel > 0 ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(torchLevel > 0 ? .yellow : .gray)
                    Text(torchLevel > 0 ? "ON" : "OFF")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Torch Level")
                        .font(.headline)
                    Slider(value: $torchLevel, in: 0...1)
                        .tint(.yellow)
                        .onChange(of: torchLevel) { _, newValue in
                            cam.setTorch(level: newValue)
                        }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    DataRow(label: "Available", value: cam.isTorchAvailable ? "Yes" : "No", icon: "flashlight.on.fill")
                    DataRow(label: "Level", value: String(format: "%.0f%%", torchLevel * 100), icon: "slider.horizontal.3")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Torch")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { torchLevel = cam.torchLevel }
    }
}
