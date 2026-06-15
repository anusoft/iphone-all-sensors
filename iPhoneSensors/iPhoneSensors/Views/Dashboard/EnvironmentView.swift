import SwiftUI

struct EnvironmentView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sensorManager: SensorManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let env = sensorManager.environmentManager
        return NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        CircularGauge(value: env.pressure, maxValue: 120, title: locManager.t("label.pressure"), unit: locManager.t("unit.kpa"), color: .orange, size: 120)
                        CircularGauge(value: env.relativeAltitude, maxValue: 500, title: locManager.t("label.altitude"), unit: locManager.t("unit.meters"), color: .cyan, size: 120)
                    }
                    .padding()
                    .glassCard()

                    AdaptiveCardGrid {
                    NavigationLink {
                        BarometerDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "barometer")
                                .foregroundStyle(.orange)
                            Text(locManager.t("sensor.barometer"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(LocalizedDisplayValue.number("%.1f", env.pressure, unitKey: "unit.kpa", localization: locManager))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        ProximityDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "sensor.tag.radiowaves.forward")
                                .foregroundStyle(.red)
                            Text(locManager.t("label.proximitySensor"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(env.proximityState ? locManager.t("value.near") : locManager.t("value.far"))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        LightDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.yellow)
                            Text(locManager.t("sensor.brightness"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(LocalizedDisplayValue.numberNoSpace("%.0f", env.screenBrightness * 100, unitKey: "unit.percent", localization: locManager))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(locManager.t("section.audioSession"))
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        DataRow(label: locManager.t("label.outputVolume"), value: LocalizedDisplayValue.numberNoSpace("%.0f", Double(env.audioVolume) * 100, unitKey: "unit.percent", localization: locManager), icon: "speaker.wave.2")
                        DataRow(label: locManager.t("label.category"), value: locManager.t("audiocategory." + env.audioSessionCategory.lowercased().replacingOccurrences(of: " ", with: "")), icon: "speaker.wave.2")
                        DataRow(label: locManager.t("label.otherAudioPlaying"), value: env.isAudioSessionActive ? locManager.t("value.yes") : locManager.t("value.no"), icon: "speaker.wave.2")
                        ForEach(env.audioOutputDevices, id: \.self) { device in
                            DataRow(label: locManager.t("label.audioOutput"), value: device, icon: "speaker.wave.2")
                        }
                    }
                    .padding()
                    .glassCard()
                }
                .responsivePage()
            }
            .appBackground()
            .navigationTitle(locManager.t("sensor.environment"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        }
    }
}
