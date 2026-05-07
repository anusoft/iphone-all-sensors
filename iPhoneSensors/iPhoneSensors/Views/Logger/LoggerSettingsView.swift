import SwiftUI

struct LoggerSettingsView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage("logger.storageCapMB") private var storageCapMB: Int = 1024
    @AppStorage("logger.disableAutoLockDuringSession") private var disableAutoLock: Bool = true
    @AppStorage("logger.pauseContinuousOnLowBattery") private var pauseOnLowBattery: Bool = false
    @AppStorage("logger.pauseContinuousOnThermal") private var pauseOnThermal: Bool = false
    @AppStorage("logger.showExportWarning") private var showExportWarning: Bool = true
    @State private var showClearConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(localization.t("logger.settings.storageSection"))) {
                    Stepper(value: $storageCapMB, in: 256...10240, step: 256) {
                        Text("\(localization.t("logger.settings.cap")): \(storageCapMB) MB")
                    }
                    Button(localization.t("logger.settings.clearContinuous"), role: .destructive) {
                        showClearConfirm = true
                    }
                }
                Section(header: Text(localization.t("logger.settings.behaviorSection"))) {
                    Toggle(localization.t("logger.settings.disableAutoLock"), isOn: $disableAutoLock)
                    Toggle(localization.t("logger.settings.pauseLowBattery"), isOn: $pauseOnLowBattery)
                    Toggle(localization.t("logger.settings.pauseThermal"), isOn: $pauseOnThermal)
                }
                Section(header: Text(localization.t("logger.settings.privacySection"))) {
                    Toggle(localization.t("logger.settings.showExportWarning"), isOn: $showExportWarning)
                }
            }
            .navigationTitle(localization.t("logger.settings.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.t("logger.settings.done")) { dismiss() }
                }
            }
            .confirmationDialog(localization.t("logger.settings.clearConfirm"),
                                isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button(localization.t("logger.settings.clearContinuous"), role: .destructive) {
                    try? loggingService.storage.deleteContinuous()
                }
            }
        }
    }
}
