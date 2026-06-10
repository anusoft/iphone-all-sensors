import SwiftUI

struct LoggerSettingsView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @AppStorage("logger.storageCapMB") private var storageCapMB: Int = 1024
    @AppStorage("logger.disableAutoLockDuringSession") private var disableAutoLock: Bool = true
    @AppStorage("logger.showExportWarning") private var showExportWarning: Bool = true
    @AppStorage(LoggingService.masterEnabledKey) private var masterEnabled = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LoggerMasterToggle(isOn: $masterEnabled)
                }
                Section {
                    LoggerSessionControl(style: .fullWidth)
                }
                .disabled(!masterEnabled)
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
                if masterEnabled {
                    Section(header: Text(localization.t("logger.settings.sensorSection"))) {
                        ForEach(SensorCategory.allCases, id: \.self) { category in
                            let ids = SensorID.allCases.filter { $0.category == category }
                            DisclosureGroup {
                                ForEach(ids, id: \.self) { id in
                                    NavigationLink(destination: SensorLogConfigView(sensorID: id)) {
                                        SensorRowConfigPreview(sensorID: id)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(localization.t("category.\(category.rawValue)"))
                                    Spacer()
                                    LoggerBulkActionMenu(ids: ids)
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Label(localization.t("logger.master.disabledNote"), systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
