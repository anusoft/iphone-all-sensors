import Foundation

struct LocalDataDeletionResult {
    var deletedURLs: [URL] = []
    var deletedDefaultsKeys: [String] = []
    var preservedDefaultsKeys: [String] = []
    var errors: [String] = []

    var didSucceed: Bool { errors.isEmpty }
}

struct LocalDataDeletionService {
    private let documentsURL: URL
    private let defaults: UserDefaults
    private let fileManager: FileManager

    static let generatedDirectoryNames = [
        "Logging",
        "SensorLogs"
    ]

    static let generatedFilePrefixes = [
        "sensor_data_",
        "signal_map_"
    ]

    static let appOwnedDefaultsKeys = [
        "logger.masterEnabled",
        "logger.storageCapMB",
        "logger.disableAutoLockDuringSession",
        "logger.showExportWarning",
        "loggingConfig.v1",
        "healthAuthorizationRequested",
        "hasCompletedPermissionFlow",
        "hasSeenShowOffTutorial",
        "seismometerAlarmHistory",
        "gpsmap.style",
        "gpsmap.tracking",
        "gpsmap.realistic",
        "gpsmap.pitch3D",
        "gpsmap.traffic",
        "gpsmap.poi",
        "gpsmap.selectable",
        "gpsmap.compass",
        "gpsmap.scale",
        "gpsmap.zoomLimit",
        "gpsmap.flyover"
    ]

    static let preservedDefaultsKeys = [
        "consentGivenAt",
        "consentAccepted",
        "appLanguage",
        "appTheme"
    ]

    init(
        documentsURL: URL? = nil,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.documentsURL = documentsURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.defaults = defaults
        self.fileManager = fileManager
    }

    func deleteLocalData() -> LocalDataDeletionResult {
        var result = LocalDataDeletionResult()
        deleteGeneratedFiles(result: &result)
        deleteAppOwnedDefaults(result: &result)
        result.preservedDefaultsKeys = Self.preservedDefaultsKeys
        return result
    }

    private func deleteGeneratedFiles(result: inout LocalDataDeletionResult) {
        for directoryName in Self.generatedDirectoryNames {
            let url = documentsURL.appendingPathComponent(directoryName, isDirectory: true)
            removeIfExists(url, result: &result)
        }

        guard let urls = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) else {
            return
        }

        for url in urls where shouldDeleteGeneratedFile(url) {
            removeIfExists(url, result: &result)
        }
    }

    private func shouldDeleteGeneratedFile(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        return Self.generatedFilePrefixes.contains { name.hasPrefix($0) }
    }

    private func removeIfExists(_ url: URL, result: inout LocalDataDeletionResult) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
            result.deletedURLs.append(url)
        } catch {
            result.errors.append("Failed to delete \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private func deleteAppOwnedDefaults(result: inout LocalDataDeletionResult) {
        for key in Self.appOwnedDefaultsKeys {
            defaults.removeObject(forKey: key)
            result.deletedDefaultsKeys.append(key)
        }
    }
}
