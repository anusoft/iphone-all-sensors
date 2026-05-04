import SwiftUI

struct EnvironmentView: View {
    @EnvironmentObject var sensorManager: SensorManager

    var body: some View {
        let env = sensorManager.environmentManager
        return NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        CircularGauge(value: env.pressure, maxValue: 120, title: "Pressure", unit: "kPa", color: .orange, size: 120)
                        CircularGauge(value: env.relativeAltitude, maxValue: 100, title: "Altitude", unit: "m", color: .cyan, size: 120)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    NavigationLink {
                        BarometerDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "barometer")
                                .foregroundStyle(.orange)
                            Text("Barometer")
                            Spacer()
                            Text(String(format: "%.1f kPa", env.pressure))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        ProximityDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "sensor.tag.radiowaves.forward")
                                .foregroundStyle(.red)
                            Text("Proximity Sensor")
                            Spacer()
                            Text(env.proximityState ? "Near" : "Far")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        LightDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.yellow)
                            Text("Screen Brightness")
                            Spacer()
                            Text(String(format: "%.0f%%", env.screenBrightness * 100))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio")
                            .font(.headline)
                        DataRow(label: "Output Volume", value: String(format: "%.0f%%", env.audioVolume * 100), icon: "speaker.wave.2")
                        DataRow(label: "Category", value: env.audioSessionCategory, icon: "speaker.wave.2")
                        DataRow(label: "Other Audio Playing", value: env.isAudioSessionActive ? "Yes" : "No", icon: "speaker.wave.2")
                        ForEach(env.audioOutputDevices, id: \.self) { device in
                            DataRow(label: "Output", value: device, icon: "speaker.wave.2")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Environment")
            .onAppear {
                sensorManager.environmentManager.startUpdates()
            }
        }
    }
}
