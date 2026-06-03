import SwiftUI

struct LoggerSettingsView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage("logger.storageCapMB") private var storageCapMB: Int = 1024
    @AppStorage("logger.disableAutoLockDuringSession") private var disableAutoLock: Bool = true
    @AppStorage("logger.showExportWarning") private var showExportWarning: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LoggerSessionControl(style: .fullWidth)
                }
                Section(header: Text(localization.t("logger.settings.storageSection"))) {
                    Stepper(value: $storageCapMB, in: 256...10240, step: 256) {
                        Text("\(localization.t("logger.settings.cap")): \(storageCapMB) MB")
                    }
                }
                Section(header: Text(localization.t("logger.settings.behaviorSection"))) {
                    Toggle(localization.t("logger.settings.disableAutoLock"), isOn: $disableAutoLock)
                }
                Section(header: Text(localization.t("logger.settings.privacySection"))) {
                    Toggle(localization.t("logger.settings.showExportWarning"), isOn: $showExportWarning)
                }
                Section(header: Text(localization.t("logger.settings.sensorSection"))) {
                    ForEach(SensorCategory.allCases, id: \.self) { category in
                        DisclosureGroup(localization.t("category.\(category.rawValue)")) {
                            ForEach(SensorID.allCases.filter { $0.category == category }, id: \.self) { id in
                                NavigationLink(destination: SensorLogConfigView(sensorID: id)) {
                                    SensorRowConfigPreview(sensorID: id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(localization.t("logger.settings.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.t("logger.settings.done")) { dismiss() }
                }
            }
        }
    }
}
