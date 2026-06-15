import XCTest
@testable import iPhoneSensors

final class SmokeTests: XCTestCase {
    func testTrue() { XCTAssertTrue(true) }

    func testEveryLanguageDefinesEverySourceUsedLocalizationKey() {
        let englishKeys = sourceUsedLocalizationKeys()

        XCTAssertFalse(englishKeys.isEmpty, "English localization table should not be empty")

        for language in AppLanguage.allCases where language != .english {
            let missing = englishKeys.subtracting(localizationKeys(for: language)).sorted()

            XCTAssertTrue(
                missing.isEmpty,
                "\(language.rawValue) is missing localized entries for: \(missing.joined(separator: ", "))"
            )
        }
    }

    func testLocalizedValuesDoNotUseWrongScript() {
        let nonCJKLanguages: [AppLanguage] = [
            .english,
            .thai,
            .spanish,
            .french,
            .german,
            .portuguese,
            .arabic,
            .italian,
            .russian
        ]

        for language in nonCJKLanguages {
            let mismatches = localizationValues(for: language)
                .filter { _, value in containsCJKScript(value) }

            XCTAssertTrue(
                mismatches.isEmpty,
                "\(language.rawValue) contains CJK-script values: \(mismatches.keys.sorted().joined(separator: ", "))"
            )
        }
    }

    func testVisibleDashboardSensorLabelsResolveToText() {
        let keys = [
            "label.orientation",
            "label.torch",
            "section.altitude"
        ]

        for key in keys {
            XCTAssertNotEqual(Translations.get(key, language: .english), key)
        }
    }

    func testShowOffRegistryChromeTextUsesLocalizedCopy() {
        let gps = SOSensors.all[0]
        XCTAssertEqual(gps.localizedTitle(language: .thai), "GPS · ตำแหน่ง")
        XCTAssertEqual(gps.localizedShort(language: .thai), "GPS")
        XCTAssertEqual(gps.localizedVariantName(at: 2, language: .spanish), "Altimapa")

        let network = SOSensors.all[16]
        XCTAssertEqual(network.localizedTitle(language: .spanish), "Red")
        XCTAssertEqual(network.localizedShort(language: .spanish), "Red")
        XCTAssertEqual(network.localizedVariantName(at: 1, language: .french), "Débit")

        let battery = SOSensors.all[10]
        XCTAssertEqual(battery.localizedTitle(language: .french), "Batterie")
        XCTAssertEqual(battery.localizedVariantName(at: 2, language: .french), "Charge")
    }

    func testShowOffVariantLabelsResolveThroughLocalizationTable() {
        XCTAssertEqual(
            SOText.localized("Field Strength · μT", language: .spanish),
            "Intensidad de campo · μT"
        )
        XCTAssertEqual(
            SOText.localized("METERS GPS", language: .thai),
            "เมตร GPS"
        )
        XCTAssertEqual(
            SOText.localized("LOOK AROUND UNAVAILABLE HERE", language: .french),
            "Look Around indisponible ici"
        )
    }

    func testShowOffTechnicalTokensFallBackToOriginalText() {
        XCTAssertEqual(SOText.localized("X", language: .spanish), "X")
        XCTAssertEqual(SOText.localized("PDOP", language: .thai), "PDOP")
    }

    func testShowOffFormattedLabelsLocalizeStaticWords() {
        XCTAssertEqual(
            SOText.localizedFormat("%d devices", language: .spanish, 3),
            "3 dispositivos"
        )
        XCTAssertEqual(
            SOText.localizedFormat("%d cores · per-core load", language: .thai, 8),
            "8 คอร์ · โหลดต่อคอร์"
        )
        XCTAssertEqual(
            SOText.localizedFormat("Heading %d°", language: .french, 90),
            "Cap 90°"
        )
    }

    func testShowOffSceneKitPoseMapsDeviceMotionToRadians() {
        let pose = SOSceneKitPose(roll: .pi / 6, pitch: -.pi / 8, yaw: .pi / 4)

        XCTAssertEqual(pose.eulerX, Float(-.pi / 8), accuracy: 0.0001)
        XCTAssertEqual(pose.eulerY, Float(.pi / 4), accuracy: 0.0001)
        XCTAssertEqual(pose.eulerZ, Float(.pi / 6), accuracy: 0.0001)
    }

    func testAppIntentMetadataStringCatalogCoversEveryLanguage() throws {
        let catalogURL = repositoryRoot()
            .appendingPathComponent("iPhoneSensors/iPhoneSensors/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Localizable.xcstrings should be a JSON string catalog"
        )
        let strings = try XCTUnwrap(
            catalog["strings"] as? [String: Any],
            "Localizable.xcstrings should contain a strings dictionary"
        )

        for key in appIntentMetadataKeys() {
            let entry = try XCTUnwrap(strings[key] as? [String: Any], "Missing App Intent string: \(key)")
            let localizations = try XCTUnwrap(
                entry["localizations"] as? [String: Any],
                "Missing localizations for App Intent string: \(key)"
            )

            for language in AppLanguage.allCases {
                let localization = try XCTUnwrap(
                    localizations[language.rawValue] as? [String: Any],
                    "Missing \(language.rawValue) localization for App Intent string: \(key)"
                )
                let stringUnit = try XCTUnwrap(
                    localization["stringUnit"] as? [String: Any],
                    "Missing string unit for \(language.rawValue).\(key)"
                )
                let value = try XCTUnwrap(
                    stringUnit["value"] as? String,
                    "Missing string value for \(language.rawValue).\(key)"
                )
                XCTAssertFalse(value.isEmpty, "Empty App Intent string value for \(language.rawValue).\(key)")
            }
        }
    }

    func testPermissionPromptActionTranslationsUseNeutralContinueCopy() {
        let permissionPromptKeys = [
            "permission.allowLocation",
            "permission.allowMotion",
            "permission.allowCamera",
            "permission.allowMicrophone",
            "permission.allowBluetooth"
        ]

        for language in AppLanguage.allCases {
            let continueTitle = Translations.get("permission.continue", language: language)
            XCTAssertFalse(continueTitle.isEmpty, "Missing neutral continuation label for \(language.rawValue)")

            for key in permissionPromptKeys {
                XCTAssertEqual(
                    Translations.get(key, language: language),
                    continueTitle,
                    "\(language.rawValue).\(key) must use neutral continuation copy"
                )
            }
        }
    }

    func testFirstRunShowsPermissionFlowAsDedicatedRootSurface() {
        XCTAssertEqual(
            RootExperiencePresentation(hasCompletedPermissionFlow: false).surface,
            .permissionFlow
        )
        XCTAssertFalse(RootExperiencePresentation(hasCompletedPermissionFlow: false).showsMainTabs)

        XCTAssertEqual(
            RootExperiencePresentation(hasCompletedPermissionFlow: true).surface,
            .mainTabs
        )
        XCTAssertTrue(RootExperiencePresentation(hasCompletedPermissionFlow: true).showsMainTabs)
    }

    func testDashboardReadinessSummaryCountsEveryVisibleSensor() {
        let readiness = DashboardReadinessSnapshot(
            motion: .init(available: 7, total: 7),
            location: .init(available: 2, total: 2),
            environment: .init(available: 3, total: 3),
            system: .init(available: 5, total: 5),
            connectivity: .init(available: 2, total: 2),
            camera: .init(available: 2, total: 2)
        )

        XCTAssertEqual(readiness.totalSensors, 21)
        XCTAssertEqual(readiness.availableSensors, 21)
        XCTAssertEqual(readiness.readinessValue, "21/21")
    }

    func testDashboardReadinessSummaryReportsPermissionGatedLocationSensors() {
        let readiness = DashboardReadinessSnapshot(
            motion: .init(available: 7, total: 7),
            location: .init(available: 0, total: 2),
            environment: .init(available: 3, total: 3),
            system: .init(available: 5, total: 5),
            connectivity: .init(available: 2, total: 2),
            camera: .init(available: 2, total: 2)
        )

        XCTAssertEqual(readiness.totalSensors, 21)
        XCTAssertEqual(readiness.location.available, 0)
        XCTAssertEqual(readiness.availableSensors, 19)
        XCTAssertEqual(readiness.readinessValue, "19/21")
    }

    private func localizationValues(for language: AppLanguage) -> [String: String] {
        let mainValues: [String: String]

        switch language {
        case .english:
            mainValues = Translations.english
        case .thai:
            mainValues = Translations.thai
        case .chinese:
            mainValues = Translations.chinese
        case .japanese:
            mainValues = Translations.japanese
        case .korean:
            mainValues = Translations.korean
        case .spanish:
            mainValues = Translations.spanish
        case .french:
            mainValues = Translations.french
        case .german:
            mainValues = Translations.german
        case .portuguese:
            mainValues = Translations.portuguese
        case .arabic:
            mainValues = Translations.arabic
        case .italian:
            mainValues = Translations.italian
        case .russian:
            mainValues = Translations.russian
        }

        var values = mainValues
        for (key, value) in Translations.extras[language] ?? [:] {
            values[key] = value
        }
        for (key, value) in Translations.showOffExtras[language] ?? [:] {
            values[key] = value
        }
        for (key, value) in Translations.screenshotExtras[language] ?? [:] {
            values[key] = value
        }
        for (key, value) in Translations.showOffVariantExtras[language] ?? [:] {
            values[key] = value
        }
        return values
    }

    private func containsCJKScript(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x1100...0x11FF, // Hangul Jamo
                 0x3040...0x309F, // Hiragana
                 0x30A0...0x30FF, // Katakana
                 0x3130...0x318F, // Hangul Compatibility Jamo
                 0x31F0...0x31FF, // Katakana Phonetic Extensions
                 0x3400...0x4DBF, // CJK Unified Ideographs Extension A
                 0x4E00...0x9FFF, // CJK Unified Ideographs
                 0xAC00...0xD7AF, // Hangul Syllables
                 0xF900...0xFAFF: // CJK Compatibility Ideographs
                return true
            default:
                return false
            }
        }
    }

    private func sourceUsedLocalizationKeys() -> Set<String> {
        var keys: Set<String> = [
            "theme.system",
            "theme.light",
            "theme.dark",
            "network.wifi",
            "network.cellular",
            "network.ethernet",
            "network.other",
            "network.disconnected",
            "category.motion",
            "category.location",
            "category.environment",
            "category.system",
            "category.connectivity",
            "category.camera",
            "category.health",
            "logger.format.sqlite",
            "logger.format.jsonl",
            "logger.format.csv",
            "logger.interval.everySample"
        ]

        for sensorID in SensorID.allCases {
            keys.insert(sensorID.localizationKey)
        }

        keys.formUnion([
            "tab.sensors", "tab.system", "tab.environment", "tab.health", "tab.logger",
            "diagnostic.title", "permission.continue", "permission.allowLocation",
            "permission.allowMotion", "permission.allowCamera", "permission.allowMicrophone",
            "permission.allowBluetooth", "label.orientation", "label.torch", "section.altitude",
            "permission.subtitle.privacy", "permission.subtitle.allSensors",
            "permission.subtitle.location", "permission.subtitle.motion",
            "permission.subtitle.camera", "permission.subtitle.microphone",
            "permission.subtitle.bluetooth", "permission.subtitle.health"
        ])

        keys.formUnion([
            "dataviewer.title", "dataviewer.tab.sessions", "dataviewer.tab.sensor",
            "dataviewer.tab.files", "dataviewer.delete", "dataviewer.session.active",
            "dataviewer.session.metadata", "dataviewer.session.perSensor",
            "dataviewer.session.title", "dataviewer.sensor", "logger.title",
            "logger.storage", "logger.stream.session", "logger.format", "logger.interval",
            "logger.enabled", "logger.sessionOff", "logger.inlineCard.title",
            "logger.inlineCard.notLogging", "logger.sessionControl.startHint",
            "logger.sessionControl.stopHint", "logger.settings.title", "logger.settings.done",
            "logger.settings.storageSection", "logger.settings.cap",
            "logger.settings.behaviorSection", "logger.settings.disableAutoLock",
            "logger.settings.privacySection", "logger.settings.showExportWarning",
            "logger.settings.sensorSection", "logger.bulk.section", "logger.bulk.allSensors",
            "logger.bulk.enableAll", "logger.bulk.disableAll", "logger.bulk.setFormat",
            "logger.bulk.setInterval", "logger.bulk.reset", "logger.resetSensor",
            "logger.sessionRecording", "logger.sessionIdle"
        ])

        keys.formUnion([
            "network.ssid", "network.ssidUnavailable", "network.ssidRequiresLocation",
            "network.openSettings", "privacy.dataPrivacy", "privacy.localProcessing",
            "privacy.noExternalServers", "privacy.noAnalytics", "privacy.noTracking",
            "privacy.deleteMyData", "privacy.deleteMyDataConfirm", "privacy.consentHistory",
            "privacy.consentGivenAt", "privacy.manageConsent", "health.disclaimer.text",
            "health.disclaimer.agree", "health.error.typeUnavailable", "health.fetch.initial",
            "health.fetch.loading", "health.fetch.permissionFailed", "health.fetch.queryError",
            "health.fetch.queryStarted", "health.fetch.loaded", "health.refreshData", "status.error",
            "health.status.accessRequested", "health.status.needsPermission",
            "consent.title", "consent.description",
            "consent.acceptAll", "barometer.trackSession", "barometer.stopSession",
            "barometer.baseline", "barometer.delta", "barometer.elevationChange",
            "level.title", "level.levelAchieved", "signalMap.title",
            "signalMap.startRecording", "signalMap.stopRecording", "signalMap.exportKML",
            "signalMap.exportCSV", "signalMap.noData", "seismometer.title",
            "seismometer.enable", "seismometer.threshold", "seismometer.alarmHistory",
            "seismometer.alarmAxisFormat", "seismometer.noAlarms", "diagnostic.unavailable",
            "diagnostic.permissionDenied", "diagnostic.permissionRequired", "diagnostic.active"
        ])

        keys.formUnion([
            "showoff.accessibility.close", "showoff.accessibility.sensorSwipe",
            "showoff.accessibility.showAllSensors", "showoff.unknownSensor",
            "sex.notSet", "blood.notSet", "unit.cores"
        ])

        keys.formUnion([
            "intent.getSensor.openApp", "intent.getSensor.unavailable",
            "intent.recording.started", "intent.recording.stopped",
            "intent.export.done"
        ])

        for sensor in SOSensors.all {
            keys.insert(sensor.titleLocalizationKey)
            keys.insert(sensor.shortLocalizationKey)
            for index in sensor.variants.indices {
                keys.insert(sensor.variantLocalizationKey(at: index))
            }
        }

        if let showOffVariantKeys = Translations.showOffVariantExtras[.english]?.keys {
            keys.formUnion(showOffVariantKeys)
        }
        if let screenshotKeys = Translations.screenshotExtras[.english]?.keys {
            keys.formUnion(screenshotKeys)
        }

        return keys
    }

    private func localizationKeys(for language: AppLanguage) -> Set<String> {
        Set(localizationValues(for: language).keys)
    }

    private func repositoryRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        return url
    }

    private func appIntentMetadataKeys() -> [String] {
        [
            "Sensor",
            "Accelerometer",
            "Gyroscope",
            "Magnetometer",
            "GPS",
            "Compass",
            "Barometer",
            "Battery",
            "Get Sensor Reading",
            "Get the current value of a specific sensor.",
            "Start Sensor Recording",
            "Start recording data from a sensor.",
            "Stop Sensor Recording",
            "Stop the active sensor logging session.",
            "Export Sensor Data",
            "Export a snapshot of all current sensor readings as a CSV file.",
            "Open All Sensors and keep it in the foreground, then try again.",
            "Could not write the export file. Check available storage and try again.",
            "Start Sensor Logging Session",
            "Begin a new sensor logging session.",
            "Stop Sensor Logging Session",
            "End the current sensor logging session.",
            "Start sensor recording in ${applicationName}",
            "Start logging sensors in ${applicationName}",
            "Start Recording",
            "Stop sensor recording in ${applicationName}",
            "Stop logging sensors in ${applicationName}",
            "Stop Recording"
        ]
    }
}
