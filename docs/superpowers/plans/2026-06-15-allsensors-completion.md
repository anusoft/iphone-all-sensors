# All Sensors Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring All Sensors from its current mostly implemented state to a release-ready iOS app whose source, tests, documentation, screenshots, TestFlight packet, and App Store submission materials agree with each other.

**Architecture:** Keep the existing SwiftUI/Xcode project structure and complete the remaining gaps with narrow, test-first changes. Centralize public metadata URLs, preserve the current sensor-manager pattern, persist only small user-facing histories in `UserDefaults`, keep logger files local under Documents, and reconcile documentation to the current bundle identifier and six-tab app shape.

**Tech Stack:** Swift 6, SwiftUI, Combine, CoreMotion, CoreLocation, CoreBluetooth, AVFoundation, HealthKit read APIs, UserNotifications, GRDB, XCTest, Xcode 26.3.

---

## Current Verified State

- App target: `iPhoneSensors` in `iPhoneSensors/iPhoneSensors.xcodeproj`.
- Test target: `iPhoneSensorsTests`.
- Current bundle identifier: `com.1moby.allsensors`.
- Current development team: `D62Y8JVXB9`.
- Current app name for release materials: `All Sensors`.
- HealthKit entitlement is present in the app target.
- Clinical Health Records entitlement is not present and must remain absent.
- `RTK.md` is referenced by `AGENTS.md` but is not present in the repository. Follow the explicit `AGENTS.md` Apple Developer and HealthKit instructions.
- The app already has the six main tabs: Dashboard, Sensors, Environment, Health, Logger, and Show-Off.
- The repository contains widget source files, but `xcodebuild -list -json -project iPhoneSensors/iPhoneSensors.xcodeproj` currently reports no widget target.
- The prior audit passed these commands:

```bash
ruby Scripts/validate_no_force_unwraps.rb
ruby Scripts/validate_privacy_config.rb
ruby Scripts/validate_widget_claims.rb
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath /tmp/allsensors-test-1781484371.xcresult
```

The successful outputs were:

```text
No force unwraps found
Privacy config OK
Widget claims OK
** TEST SUCCEEDED **
```

## Top-Level Docs Reviewed

The planning input is the current `docs/*.md` set at the repository root. These files drive the implementation and release gates in this plan:

- `docs/features.md`: aggregate feature tracker with stale unchecked items; covered by Tasks 1-8 and the documentation reconciliation in Task 6.
- `docs/logging.md`: logger requirements for local persistent storage, session files, exports, Files access, deletion, and backup behavior; covered by Tasks 2, 7, 8, and 10.
- `docs/current-allsensors-features.md`: older current-state snapshot that conflicts with the current six-tab Health-enabled app; covered by Task 6.
- `docs/ui-screen.md`: current UI screen and tab expectations; covered by Task 6 and screenshot/device gates in Tasks 9-10.
- `docs/sensors-show-off.md`: Show-Off variants, including GPS TRACK and ALT GEO ALT; covered by Tasks 6, 9, and 10.
- `docs/app-store-metadata.md`: App Store metadata and URL expectations; covered by Tasks 1, 6, 11, and 12.
- `docs/testflight-beta.md`: TestFlight beta checklist and review flow; covered by Tasks 10-11.
- `docs/screenshots.md`: screenshot generation and verification requirements; covered by Task 9.
- `docs/privacy-policy.md`: privacy-policy statements for local processing, permissions, HealthKit, and deletion; covered by Tasks 1, 2, 5, 6, 10, and 12.
- `docs/all-sensor-current-features.md`: newer current-feature inventory; covered by Tasks 6-10.
- `docs/appstore-info.md`: App Store information packet summary; covered by Tasks 1, 6, 11, and 12.
- `docs/never-reject.md`: App Review risk analysis; covered by Tasks 1, 2, 5, 6, 8, 10, 11, and 12.

Nested docs under `docs/features/` and `docs/appstore/` are referenced by the top-level docs and are included where they are the authoritative packet or feature brief for a task.

## Remaining Completion Scope

1. Fix stale runtime and App Store URL mismatches.
2. Finish logger storage compliance for Files app access and iCloud backup exclusion.
3. Persist seismometer alarm history and localize notification text.
4. Persist completed barometer tracking sessions and localize weather prediction copy.
5. Correct HealthKit runtime copy and read-access semantics.
6. Reconcile stale documentation with current source truth.
7. Add focused tests for the completed feature briefs.
8. Run the automated validation, screenshot, physical-device, TestFlight, and App Store gates.

## File Structure

- Create `iPhoneSensors/iPhoneSensors/Services/AppMetadata.swift`: public metadata constants for privacy, support, and marketing URLs.
- Modify `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`: add `AppMetadata.swift` to the app target sources.
- Modify `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift`: replace hard-coded settings privacy URL with `AppMetadata.privacyURL`.
- Modify `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`: add URL metadata tests and runtime-copy translation tests.
- Modify `iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift`: create the logger root directory early and set `isExcludedFromBackup`.
- Modify `iPhoneSensors/iPhoneSensors/Info.plist`: add `LSSupportsOpeningDocumentsInPlace`.
- Modify `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`: verify backup exclusion and Files-compatible logger paths.
- Modify `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`: persist seismometer alarms, persist barometer sessions, and convert weather and notification text to translation keys.
- Modify `iPhoneSensors/iPhoneSensors/Views/Sensors/BarometerDetailView.swift`: show completed barometer sessions with localized labels.
- Modify `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`: add English extras for new keys and correct stale HealthKit copy.
- Modify `iPhoneSensors/iPhoneSensors/Services/LocalDataDeletionService.swift`: clear `barometerSessionHistory` with other local app-owned data.
- Modify `iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift`: test seismometer and barometer persistence helpers.
- Modify `iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift`: test `barometerSessionHistory` deletion.
- Modify `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift`: use accurate HealthKit no-samples messaging and avoid claiming read authorization was granted.
- Modify `iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift`: cover the no-samples explanation.
- Modify documentation under `README.md`, `docs/*.md`, and `docs/features/*.md`: replace stale bundle IDs, tab counts, disabled HealthKit claims, and widget App Group references with current truth.

## Task 1: Centralize Public App URLs and Fix Settings Privacy Link

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/AppMetadata.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift`
- Modify: `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write the failing URL metadata test**

Append this test to `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`:

```swift
func testPublishedAppURLsMatchAppStorePacket() throws {
    XCTAssertEqual(
        AppMetadata.privacyURL.absoluteString,
        "https://anusoft.github.io/iphone-all-sensors/privacy.html"
    )
    XCTAssertEqual(
        AppMetadata.supportURL.absoluteString,
        "https://anusoft.github.io/iphone-all-sensors/support.html"
    )
    XCTAssertEqual(
        AppMetadata.marketingURL.absoluteString,
        "https://anusoft.github.io/iphone-all-sensors/"
    )
}
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/SmokeTests/testPublishedAppURLsMatchAppStorePacket
```

Expected: the test target fails to compile because `AppMetadata` is not defined.

- [ ] **Step 3: Create `AppMetadata.swift`**

Create `iPhoneSensors/iPhoneSensors/Services/AppMetadata.swift`:

```swift
import Foundation

enum AppMetadata {
    static let privacyURL = url("https://anusoft.github.io/iphone-all-sensors/privacy.html")
    static let supportURL = url("https://anusoft.github.io/iphone-all-sensors/support.html")
    static let marketingURL = url("https://anusoft.github.io/iphone-all-sensors/")

    private static func url(_ string: String) -> URL {
        guard let value = URL(string: string) else {
            preconditionFailure("Invalid bundled URL: \(string)")
        }
        return value
    }
}
```

- [ ] **Step 4: Add `AppMetadata.swift` to the app target**

Modify `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj` by adding one `PBXFileReference`, one `PBXBuildFile`, adding the file reference to the main `iPhoneSensors` group children near `LocalDataDeletionService.swift`, and adding the build file to the app target `A80001 /* Sources */` list.

Use these IDs unless they already exist in the project file:

```text
F202606150001 /* AppMetadata.swift in Sources */ = {isa = PBXBuildFile; fileRef = F202606150002 /* AppMetadata.swift */; };
F202606150002 /* AppMetadata.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = AppMetadata.swift; sourceTree = "<group>"; };
```

Add this child entry near the other service files:

```text
F202606150002 /* AppMetadata.swift */,
```

Add this source entry to `A80001 /* Sources */`:

```text
F202606150001 /* AppMetadata.swift in Sources */,
```

- [ ] **Step 5: Update the settings privacy link**

In `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift`, replace:

```swift
Link(destination: URL(string: "https://1moby.com/privacy", encodingInvalidCharacters: false) ?? URL(fileURLWithPath: "/")) {
```

with:

```swift
Link(destination: AppMetadata.privacyURL) {
```

- [ ] **Step 6: Run the focused test and verify it passes**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/SmokeTests/testPublishedAppURLsMatchAppStorePacket
```

Expected: the focused test passes.

- [ ] **Step 7: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensors/Services/AppMetadata.swift \
  iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift \
  iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj \
  iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "fix: centralize public app urls"
```

## Task 2: Complete Logger Storage Compliance

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Info.plist`
- Test: `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`

- [ ] **Step 1: Write failing backup-exclusion tests**

Append these tests to `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`:

```swift
func testContinuousSQLiteCreatesBackupExcludedRoot() throws {
    let m = makeMgr()

    _ = try m.continuousSQLiteURL()

    let values = try m.rootURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
    XCTAssertEqual(values.isExcludedFromBackup, true)
}

func testSessionDirCreatesBackupExcludedRoot() throws {
    let m = makeMgr()

    _ = try m.sessionDir(UUID())

    let values = try m.rootURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
    XCTAssertEqual(values.isExcludedFromBackup, true)
}
```

- [ ] **Step 2: Run the focused logger-path tests and verify they fail**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/LogStoragePathsTests
```

Expected: one or both new tests fail because `rootURL` is not excluded from backup.

- [ ] **Step 3: Add root directory policy enforcement**

In `iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift`, replace the initializer with:

```swift
init(rootURL: URL? = nil) {
    if let rootURL { self.rootURL = rootURL }
    else {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.rootURL = docs.appendingPathComponent("SensorLogs", isDirectory: true)
    }
    try? ensureRootDirectoryPolicy()
}
```

Add this private helper before `filename(for:)`:

```swift
private func ensureRootDirectoryPolicy() throws {
    try fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    var mutableRoot = rootURL
    try mutableRoot.setResourceValues(values)
}
```

- [ ] **Step 4: Add Files app open-in-place support**

In `iPhoneSensors/iPhoneSensors/Info.plist`, add this key beside `UIFileSharingEnabled`:

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

- [ ] **Step 5: Run logger-path tests and verify they pass**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/LogStoragePathsTests
```

Expected: the logger path tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift \
  iPhoneSensors/iPhoneSensors/Info.plist \
  iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift
git commit -m "fix: exclude sensor logs from backup"
```

## Task 3: Persist Seismometer Alarms and Localize Alert Text

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift`

- [ ] **Step 1: Write failing seismometer persistence tests**

Append these tests to `iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift`:

```swift
func testSeismometerAlarmHistoryRoundTripsThroughDefaults() throws {
    let suite = "SeismometerAlarmHistoryTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }

    let alarm = MotionSensorManager.SeismometerAlarm(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        timestamp: Date(timeIntervalSince1970: 1_800_000_000),
        magnitude: 1.75,
        axis: "Z"
    )

    MotionSensorManager.saveSeismometerHistory([alarm], defaults: defaults)
    let restored = MotionSensorManager.loadSeismometerHistory(defaults: defaults)

    XCTAssertEqual(restored, [alarm])
}

func testSeismometerNotificationBodyUsesLocalizedTemplate() {
    let body = MotionSensorManager.seismometerNotificationBody(
        magnitude: 2.25,
        axis: "Y",
        language: .english
    )

    XCTAssertEqual(body, "G-force threshold exceeded: 2.25G on Y axis")
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testSeismometerAlarmHistoryRoundTripsThroughDefaults \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testSeismometerNotificationBodyUsesLocalizedTemplate
```

Expected: the tests fail to compile because `SeismometerAlarm` cannot be initialized with an explicit id, is not `Equatable`, and the static persistence helpers do not exist.

- [ ] **Step 3: Update the seismometer model and helpers**

In `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`, replace the nested `SeismometerAlarm` type with:

```swift
struct SeismometerAlarm: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let magnitude: Double
    let axis: String

    init(id: UUID = UUID(), timestamp: Date, magnitude: Double, axis: String) {
        self.id = id
        self.timestamp = timestamp
        self.magnitude = magnitude
        self.axis = axis
    }
}
```

Add these static helpers inside `MotionSensorManager`:

```swift
static let seismometerAlarmHistoryKey = "seismometerAlarmHistory"

static func loadSeismometerHistory(defaults: UserDefaults = .standard) -> [SeismometerAlarm] {
    guard let data = defaults.data(forKey: seismometerAlarmHistoryKey) else { return [] }
    return (try? JSONDecoder().decode([SeismometerAlarm].self, from: data)) ?? []
}

static func saveSeismometerHistory(_ alarms: [SeismometerAlarm], defaults: UserDefaults = .standard) {
    guard let data = try? JSONEncoder().encode(alarms) else { return }
    defaults.set(data, forKey: seismometerAlarmHistoryKey)
}

static func seismometerNotificationBody(
    magnitude: Double,
    axis: String,
    language: AppLanguage
) -> String {
    let template = Translations.get("seismometer.notificationBody", language: language)
    return String(format: template, magnitude, axis)
}
```

If `MotionSensorManager` does not already have an initializer, add one before `startUpdates()`:

```swift
init() {
    seismometerAlarmHistory = Self.loadSeismometerHistory()
}
```

If it already has an initializer, add this statement to that initializer:

```swift
seismometerAlarmHistory = Self.loadSeismometerHistory()
```

- [ ] **Step 4: Persist alarms after append and use localized notification text**

In `checkSeismometer()`, after trimming the alarm list, add:

```swift
Self.saveSeismometerHistory(seismometerAlarmHistory)
```

Replace the hard-coded notification title/body:

```swift
content.title = "Vibration Detected"
content.body = String(format: "G-force threshold exceeded: %.2fG on %@ axis", mag, axis)
```

with:

```swift
let language = LocalizationManager.shared.appLanguage
content.title = Translations.get("seismometer.notificationTitle", language: language)
content.body = Self.seismometerNotificationBody(
    magnitude: mag,
    axis: axis,
    language: language
)
```

- [ ] **Step 5: Add translation extras**

In `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`, add these keys to the existing `extras` dictionary:

```swift
"seismometer.notificationTitle": "Vibration Detected",
"seismometer.notificationBody": "G-force threshold exceeded: %.2fG on %@ axis",
```

- [ ] **Step 6: Run the focused seismometer tests and verify they pass**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testSeismometerAlarmHistoryRoundTripsThroughDefaults \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testSeismometerNotificationBodyUsesLocalizedTemplate
```

Expected: the focused tests pass.

- [ ] **Step 7: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift \
  iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift \
  iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift
git commit -m "feat: persist seismometer alarms"
```

## Task 4: Persist Completed Barometer Tracking Sessions

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Views/Sensors/BarometerDetailView.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalDataDeletionService.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift`

- [ ] **Step 1: Write failing barometer session persistence tests**

Append these tests to `iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift`:

```swift
func testBarometerSessionHistoryRoundTripsThroughDefaults() throws {
    let suite = "BarometerSessionHistoryTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }

    let session = MotionSensorManager.BarometerTrackingSession(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        startedAt: Date(timeIntervalSince1970: 1_800_000_000),
        endedAt: Date(timeIntervalSince1970: 1_800_000_300),
        baselinePressure: 101.20,
        endingPressure: 101.05,
        maxDelta: 0.22,
        elevationChange: 12.5,
        trend: "falling",
        weatherPredictionKey: "barometer.weather.storm"
    )

    MotionSensorManager.saveBarometerSessionHistory([session], defaults: defaults)
    let restored = MotionSensorManager.loadBarometerSessionHistory(defaults: defaults)

    XCTAssertEqual(restored, [session])
}

func testBarometerWeatherPredictionKeyMapsToLocalizedText() {
    XCTAssertEqual(Translations.get("barometer.weather.stable", language: .english), "Conditions stable")
    XCTAssertEqual(Translations.get("barometer.weather.improving", language: .english), "Conditions improving")
    XCTAssertEqual(Translations.get("barometer.weather.storm", language: .english), "Storm possible")
}
```

- [ ] **Step 2: Run focused barometer tests and verify they fail**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testBarometerSessionHistoryRoundTripsThroughDefaults \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testBarometerWeatherPredictionKeyMapsToLocalizedText
```

Expected: the tests fail to compile because `BarometerTrackingSession` and persistence helpers do not exist and weather keys are missing.

- [ ] **Step 3: Add the barometer session model and storage helpers**

In `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`, add this nested type near `SeismometerAlarm`:

```swift
struct BarometerTrackingSession: Identifiable, Codable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let baselinePressure: Double
    let endingPressure: Double
    let maxDelta: Double
    let elevationChange: Double
    let trend: String
    let weatherPredictionKey: String

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        baselinePressure: Double,
        endingPressure: Double,
        maxDelta: Double,
        elevationChange: Double,
        trend: String,
        weatherPredictionKey: String
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.baselinePressure = baselinePressure
        self.endingPressure = endingPressure
        self.maxDelta = maxDelta
        self.elevationChange = elevationChange
        self.trend = trend
        self.weatherPredictionKey = weatherPredictionKey
    }
}
```

Add this published property beside the other barometer tracking state:

```swift
@Published var barometerSessionHistory: [BarometerTrackingSession] = []
```

Add these static helpers inside `MotionSensorManager`:

```swift
static let barometerSessionHistoryKey = "barometerSessionHistory"

static func loadBarometerSessionHistory(defaults: UserDefaults = .standard) -> [BarometerTrackingSession] {
    guard let data = defaults.data(forKey: barometerSessionHistoryKey) else { return [] }
    return (try? JSONDecoder().decode([BarometerTrackingSession].self, from: data)) ?? []
}

static func saveBarometerSessionHistory(
    _ sessions: [BarometerTrackingSession],
    defaults: UserDefaults = .standard
) {
    guard let data = try? JSONEncoder().encode(sessions) else { return }
    defaults.set(data, forKey: barometerSessionHistoryKey)
}
```

Add this statement to the existing or newly added `MotionSensorManager` initializer:

```swift
barometerSessionHistory = Self.loadBarometerSessionHistory()
```

- [ ] **Step 4: Save completed tracking sessions on stop**

Replace `stopBarometerTracking()` with:

```swift
func stopBarometerTracking() {
    let endedAt = Date()
    if let startedAt = barometerTrackingStartTime {
        let session = BarometerTrackingSession(
            startedAt: startedAt,
            endedAt: endedAt,
            baselinePressure: barometerBaseline,
            endingPressure: pressure,
            maxDelta: barometerMaxDelta,
            elevationChange: barometerElevationChange,
            trend: barometerTrend,
            weatherPredictionKey: barometerWeatherPrediction
        )
        barometerSessionHistory.append(session)
        if barometerSessionHistory.count > 20 {
            barometerSessionHistory.removeFirst(barometerSessionHistory.count - 20)
        }
        Self.saveBarometerSessionHistory(barometerSessionHistory)
    }

    isBarometerTracking = false
    barometerTrackingStartTime = nil
    barometerSessionValues = []
    appLog("[Motion] Barometer tracking stopped")
}
```

- [ ] **Step 5: Store weather prediction keys instead of English strings**

In `startBarometerTracking()`, replace:

```swift
barometerWeatherPrediction = ""
```

with:

```swift
barometerWeatherPrediction = "barometer.weather.stable"
```

In `updateBarometerTracking()`, replace the three English assignments with these key assignments:

```swift
barometerWeatherPrediction = "barometer.weather.improving"
barometerWeatherPrediction = "barometer.weather.storm"
barometerWeatherPrediction = "barometer.weather.stable"
```

- [ ] **Step 6: Add translation extras**

In `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`, add these keys to the existing `extras` dictionary:

```swift
"barometer.weather.stable": "Conditions stable",
"barometer.weather.improving": "Conditions improving",
"barometer.weather.storm": "Storm possible",
"barometer.sessionHistory": "Session History",
"barometer.noSessionHistory": "No completed sessions yet",
"barometer.sessionPressure": "%.2f to %.2f kPa",
"barometer.sessionDelta": "Max delta %.2f kPa",
"barometer.sessionElevation": "Elevation change %.1f m",
```

- [ ] **Step 7: Render completed sessions in the barometer detail view**

In `iPhoneSensors/iPhoneSensors/Views/Sensors/BarometerDetailView.swift`, keep existing active tracking UI and add this section below it:

```swift
Section(header: Text(locManager.t("barometer.sessionHistory"))) {
    if motionManager.barometerSessionHistory.isEmpty {
        Text(locManager.t("barometer.noSessionHistory"))
            .foregroundColor(.secondary)
    } else {
        ForEach(motionManager.barometerSessionHistory.prefix(5)) { session in
            VStack(alignment: .leading, spacing: 6) {
                Text(session.endedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                Text(String(format: locManager.t("barometer.sessionPressure"), session.baselinePressure, session.endingPressure))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: locManager.t("barometer.sessionDelta"), session.maxDelta))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: locManager.t("barometer.sessionElevation"), session.elevationChange))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(locManager.t(session.weatherPredictionKey))
                    .font(.caption.weight(.medium))
            }
        }
    }
}
```

If `BarometerDetailView` currently displays `motionManager.barometerWeatherPrediction` directly, change that display to:

```swift
Text(locManager.t(motionManager.barometerWeatherPrediction))
```

- [ ] **Step 8: Add barometer history to local data deletion**

In `iPhoneSensors/iPhoneSensors/Services/LocalDataDeletionService.swift`, add this key to `appOwnedDefaultsKeys` beside `seismometerAlarmHistory`:

```swift
"barometerSessionHistory",
```

In `iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift`, add this setup line in `testClearsAppOwnedStateButPreservesConsentLanguageAndTheme()`:

```swift
defaults.set(["session"], forKey: "barometerSessionHistory")
```

Add this assertion after the seismometer assertion:

```swift
XCTAssertNil(defaults.object(forKey: "barometerSessionHistory"))
```

- [ ] **Step 9: Run focused barometer and deletion tests**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testBarometerSessionHistoryRoundTripsThroughDefaults \
  -only-testing:iPhoneSensorsTests/CoreSensorSmokeTests/testBarometerWeatherPredictionKeyMapsToLocalizedText \
  -only-testing:iPhoneSensorsTests/LocalDataDeletionServiceTests/testClearsAppOwnedStateButPreservesConsentLanguageAndTheme
```

Expected: the focused tests pass.

- [ ] **Step 10: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift \
  iPhoneSensors/iPhoneSensors/Views/Sensors/BarometerDetailView.swift \
  iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift \
  iPhoneSensors/iPhoneSensors/Services/LocalDataDeletionService.swift \
  iPhoneSensors/iPhoneSensorsTests/CoreSensorSmokeTests.swift \
  iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift
git commit -m "feat: persist barometer sessions"
```

## Task 5: Clean Up HealthKit Runtime Copy and Read-Access Semantics

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write failing HealthKit no-samples copy tests**

Append this test to `iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift`:

```swift
func testEmptyReadExplanationDoesNotClaimAuthorizationGranted() {
    let explanation = HealthSensorManager.emptyReadExplanation

    XCTAssertTrue(explanation.contains("No Health samples are available yet"))
    XCTAssertTrue(explanation.contains("Health read access was not enabled"))
    XCTAssertFalse(explanation.localizedCaseInsensitiveContains("granted"))
}
```

Append this test to `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`:

```swift
func testHealthDisabledCopyDoesNotClaimHealthKitCodeIsDisabled() {
    let description = Translations.get("health.disabledDescription", language: .english)

    XCTAssertFalse(description.localizedCaseInsensitiveContains("code is implemented"))
    XCTAssertFalse(description.localizedCaseInsensitiveContains("disabled"))
    XCTAssertTrue(description.localizedCaseInsensitiveContains("Health app"))
}
```

- [ ] **Step 2: Run focused HealthKit tests and verify they fail**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/HealthSensorManagerTests/testEmptyReadExplanationDoesNotClaimAuthorizationGranted \
  -only-testing:iPhoneSensorsTests/SmokeTests/testHealthDisabledCopyDoesNotClaimHealthKitCodeIsDisabled
```

Expected: the tests fail because `emptyReadExplanation` does not exist and the stale Health disabled copy still references disabled code.

- [ ] **Step 3: Add HealthKit empty-read explanation**

In `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift`, add this static property inside `HealthSensorManager`:

```swift
static let emptyReadExplanation = "No Health samples are available yet. This can mean there are no matching samples on this device or Health read access was not enabled in the Health app."
```

In every no-sample branch of `fetchLatestQuantity` and `fetchTodaySum`, set:

```swift
self.latestFetchStatus = Self.emptyReadExplanation
```

Keep any logging that says no samples were returned. Do not add copy that says HealthKit read access is granted, because HealthKit intentionally does not expose per-type read authorization status.

- [ ] **Step 4: Replace stale disabled Health copy**

In `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`, replace the English value for `health.disabledDescription` with:

```swift
"health.disabledDescription": "Health readings appear when matching samples are available in the Health app and read access is enabled for All Sensors.",
```

For non-English language dictionaries that still say the HealthKit code is implemented but disabled, either translate the same meaning accurately or remove those specific `health.disabledDescription` entries so the English fallback is used. Do not leave any runtime string claiming HealthKit is disabled by the app.

- [ ] **Step 5: Run focused HealthKit tests and verify they pass**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/HealthSensorManagerTests/testEmptyReadExplanationDoesNotClaimAuthorizationGranted \
  -only-testing:iPhoneSensorsTests/SmokeTests/testHealthDisabledCopyDoesNotClaimHealthKitCodeIsDisabled
```

Expected: the focused tests pass.

- [ ] **Step 6: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift \
  iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift \
  iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift \
  iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "fix: clarify healthkit read state copy"
```

## Task 6: Reconcile Stale Documentation with Current Source

**Files:**
- Modify: `README.md`
- Modify: `docs/features.md`
- Modify: `docs/current-allsensors-features.md`
- Modify: `docs/all-sensor-current-features.md`
- Modify: `docs/features/08-home-screen-widget.md`
- Modify: matching App Store docs under `docs/appstore/*.md`

- [ ] **Step 1: Find stale documentation claims**

Run:

```bash
rg -n \
  'com\.1moby\.iPhoneSensors|group\.com\.1moby\.iPhoneSensors|currently disabled|disabled by default|5 tabs|five tabs|HealthKit.*disabled|Clinical Health Records' \
  README.md docs iPhoneSensors
```

Expected: stale documentation hits plus the valid entitlement reminder that Clinical Health Records must not be enabled.

- [ ] **Step 2: Update bundle identifier references**

Replace current-product references to:

```text
com.1moby.iPhoneSensors
```

with:

```text
com.1moby.allsensors
```

Leave historical references only if the paragraph explicitly labels them historical. If a stale reference is not clearly historical, update it.

- [ ] **Step 3: Update widget App Group references**

In `docs/features/08-home-screen-widget.md`, replace:

```text
group.com.1moby.iPhoneSensors
```

with:

```text
group.com.1moby.allsensors
```

Add this note near the top of the widget brief:

```markdown
> Current status: the repository contains widget source files, but `xcodebuild -list -json -project iPhoneSensors/iPhoneSensors.xcodeproj` currently reports no widget target. Treat this brief as deferred until a widget target and App Group entitlement are intentionally added.
```

- [ ] **Step 4: Update tab-count and HealthKit claims**

In `README.md`, `docs/features.md`, and feature summary docs, replace old five-tab language with six-tab language:

```text
Dashboard, Sensors, Environment, Health, Logger, and Show-Off
```

Replace disabled HealthKit claims with:

```text
HealthKit is active as a read-only Health tab when the user grants access in the Health app. The app does not write Health data and does not use Clinical Health Records.
```

- [ ] **Step 5: Add superseded notices to old aggregate feature docs**

At the top of `docs/features.md`, add:

```markdown
> Status note: this file is an aggregate planning tracker. The current source of truth is the app source plus the App Store packet under `docs/appstore/`. Items marked incomplete here may already be implemented; validate against source before changing code.
```

At the top of `docs/current-allsensors-features.md`, add:

```markdown
> Status note: this snapshot predates the current six-tab app and Health tab implementation. Keep it for historical context, but use `docs/all-sensor-current-features.md`, source code, and tests for release decisions.
```

- [ ] **Step 6: Verify stale claims are resolved**

Run:

```bash
rg -n \
  'com\.1moby\.iPhoneSensors|group\.com\.1moby\.iPhoneSensors|currently disabled|disabled by default|5 tabs|five tabs|HealthKit.*disabled' \
  README.md docs
```

Expected: no matches, except explicit historical or superseded notes that are clearly labeled as such.

- [ ] **Step 7: Commit**

Run:

```bash
git add README.md docs
git commit -m "docs: align release docs with current app"
```

## Task 7: Add Focused Tests for Completed Feature Briefs

**Files:**
- Modify: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`
- Modify: `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`
- Modify: `iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift`

- [ ] **Step 1: Add a test that translation keys used by new features resolve**

Append this test to `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`:

```swift
func testCompletionFeatureTranslationKeysResolveToText() {
    let keys = [
        "seismometer.notificationTitle",
        "seismometer.notificationBody",
        "barometer.weather.stable",
        "barometer.weather.improving",
        "barometer.weather.storm",
        "barometer.sessionHistory",
        "barometer.noSessionHistory",
        "barometer.sessionPressure",
        "barometer.sessionDelta",
        "barometer.sessionElevation"
    ]

    for key in keys {
        XCTAssertNotEqual(Translations.get(key, language: .english), key, "Missing \(key)")
    }
}
```

- [ ] **Step 2: Add a test that local deletion key lists cover persisted histories**

Append this test to `iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift`:

```swift
func testDeletionServiceIncludesPersistedSensorHistories() {
    XCTAssertTrue(LocalDataDeletionService.appOwnedDefaultsKeys.contains("seismometerAlarmHistory"))
    XCTAssertTrue(LocalDataDeletionService.appOwnedDefaultsKeys.contains("barometerSessionHistory"))
}
```

- [ ] **Step 3: Add a logger path test for Files app-visible root name**

Append this test to `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`:

```swift
func testDefaultLogRootUsesSensorLogsDirectoryName() {
    let manager = LogStorageManager()

    XCTAssertEqual(manager.rootURL.lastPathComponent, "SensorLogs")
}
```

- [ ] **Step 4: Run the focused completion tests**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:iPhoneSensorsTests/SmokeTests/testCompletionFeatureTranslationKeysResolveToText \
  -only-testing:iPhoneSensorsTests/LocalDataDeletionServiceTests/testDeletionServiceIncludesPersistedSensorHistories \
  -only-testing:iPhoneSensorsTests/LogStoragePathsTests/testDefaultLogRootUsesSensorLogsDirectoryName
```

Expected: the focused tests pass after Tasks 1-6.

- [ ] **Step 5: Commit**

Run:

```bash
git add \
  iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift \
  iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift \
  iPhoneSensors/iPhoneSensorsTests/LocalDataDeletionServiceTests.swift
git commit -m "test: cover completion feature contracts"
```

## Task 8: Run Full Automated Gate

**Files:**
- No source edits unless a command fails.

- [ ] **Step 1: Run force-unwrap validator**

Run:

```bash
ruby Scripts/validate_no_force_unwraps.rb
```

Expected:

```text
No force unwraps found
```

- [ ] **Step 2: Run privacy config validator**

Run:

```bash
ruby Scripts/validate_privacy_config.rb
```

Expected:

```text
Privacy config OK
```

- [ ] **Step 3: Run widget claims validator**

Run:

```bash
ruby Scripts/validate_widget_claims.rb
```

Expected:

```text
Widget claims OK
```

- [ ] **Step 4: Run the full simulator test suite**

Run:

```bash
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath /tmp/allsensors-completion-tests.xcresult
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 5: Run a Release simulator build**

Run:

```bash
xcodebuild build \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Expected:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 6: Commit validation fixes if any were required**

If Steps 1-5 required code changes, run:

```bash
git add iPhoneSensors Scripts docs README.md
git commit -m "fix: satisfy release validation gate"
```

If no files changed, record the passing commands in the implementation handoff instead of creating an empty commit.

## Task 9: Generate and Verify App Store Screenshots

**Files:**
- Generated screenshots under the repository screenshot output path used by the existing screenshot tooling.
- Modify: `docs/screenshots.md`
- Modify: `docs/appstore/11-build-and-screenshots.md`

- [ ] **Step 1: Identify the screenshot command**

Run:

```bash
rg -n 'screenshot|Screenshot|xcrun simctl io|iPhone 17 Pro Max|iPad Pro' Scripts docs iPhoneSensors -g '!*.xcresult/**'
```

Expected: find the existing screenshot-generation script or documented command.

- [ ] **Step 2: Generate iPhone screenshots**

Run the repository's documented iPhone screenshot command. If the command accepts a simulator name, use:

```text
iPhone 17 Pro Max
```

Expected: screenshots are generated for the required App Store sizes and app states listed in `docs/screenshots.md`.

- [ ] **Step 3: Generate iPad screenshots if the app is submitted as universal**

Run the documented iPad screenshot command with:

```text
iPad Pro 13-inch (M5)
```

Expected: iPad screenshots are generated, or `docs/appstore/11-build-and-screenshots.md` explicitly states that only iPhone screenshots are required for the selected App Store availability.

- [ ] **Step 4: Visually verify screenshot contents**

Open the generated screenshots and verify:

- No permission alert blocks the app UI.
- No Health screen claims HealthKit is disabled.
- No logger screen implies data leaves the device.
- The first screenshot communicates All Sensors as the product.
- Text is not clipped in English.
- Screenshots do not show placeholder Bangkok GPS coordinates.

- [ ] **Step 5: Update screenshot documentation with verified artifact paths**

In `docs/screenshots.md` and `docs/appstore/11-build-and-screenshots.md`, add this dated entry after verifying the files exist in the stable screenshot output folders:

```markdown
## Generated Screenshots - 2026-06-15

- iPhone 17 Pro Max: `screenshots/iphone-6.9/`.
- iPad Pro 13-inch (M5): `screenshots/ipad-13/`.
- Visual verification: permission alerts absent, Health copy current, logger copy local-only, no clipped text, no placeholder GPS coordinates.
```

- [ ] **Step 6: Commit screenshot artifacts and docs**

Run:

```bash
git add docs screenshots/iphone-6.9 screenshots/ipad-13
git commit -m "docs: refresh app store screenshots"
```

## Task 10: Physical Device Verification

**Files:**
- Modify: `docs/testflight-beta.md`
- Modify: `docs/appstore/12-final-checklist.md`

- [ ] **Step 1: Install on a real iPhone**

Use Xcode to run the `iPhoneSensors` scheme on a physical iPhone signed with team `D62Y8JVXB9`.

Expected:

- App launches without crash.
- Bundle identifier is `com.1moby.allsensors`.
- HealthKit entitlement remains enabled.
- Clinical Health Records remains disabled.

- [ ] **Step 2: Verify motion and environment sensors**

On the device, verify:

- Accelerometer, gyroscope, magnetometer, and device motion update on dashboard or detail screens.
- Seismometer can be enabled and records an alarm when the device is shaken above the threshold.
- Surface level haptic feedback triggers when the phone is level.
- Barometer tracking can start, show live deltas, stop, and show a completed session in history.
- Altimeter and barometer show unavailable states gracefully if hardware access is unavailable.

- [ ] **Step 3: Verify location and show-off mode**

On the device, verify:

- Location permission prompt appears with neutral copy.
- GPS values are blank or permission-gated before permission.
- GPS TRACK show-off mode uses live location after permission.
- ALT GEO ALT show-off mode displays live or gracefully unavailable altitude.
- No hard-coded Bangkok coordinate appears.

- [ ] **Step 4: Verify Health tab**

On the device, verify:

- Health authorization prompt appears when requested.
- The app reads available Health samples after access is enabled in the Health app.
- Empty Health results show the no-samples explanation.
- The app does not write Health data.
- The app does not request Clinical Health Records.

- [ ] **Step 5: Verify logger storage and deletion**

On the device, verify:

- Logger can start and stop a session.
- Files appear under the app's Files app container in `SensorLogs`.
- Local data deletion removes logger files, seismometer history, and barometer session history.
- Local data deletion preserves consent, language, and theme settings.

- [ ] **Step 6: Record physical-device results**

Run this prompt-driven command after the physical device checks are complete. It refuses to append the note when any observed value is blank:

```bash
printf 'Device model: '
IFS= read -r DEVICE_MODEL
printf 'iOS version: '
IFS= read -r IOS_VERSION
printf 'Build number: '
IFS= read -r BUILD_NUMBER
printf 'Verification result: '
IFS= read -r DEVICE_RESULT
test -n "$DEVICE_MODEL"
test -n "$IOS_VERSION"
test -n "$BUILD_NUMBER"
test -n "$DEVICE_RESULT"
cat >> docs/testflight-beta.md <<EOF

## Physical Device Verification - 2026-06-15

- Device: $DEVICE_MODEL
- iOS: $IOS_VERSION
- Build: $BUILD_NUMBER
- Result: $DEVICE_RESULT
- Notes: HealthKit read-only flow, logger local storage, seismometer history, barometer history, GPS show-off mode, and local data deletion verified.
EOF
```

In `docs/appstore/12-final-checklist.md`, mark the physical-device verification item complete with the same date if all checks passed.

- [ ] **Step 7: Commit device verification notes**

Run:

```bash
git add docs/testflight-beta.md docs/appstore/12-final-checklist.md
git commit -m "docs: record physical device verification"
```

## Task 11: TestFlight External Beta Gate

**Files:**
- Modify: `docs/testflight-beta.md`
- Modify: `docs/appstore/12-final-checklist.md`
- Modify: `docs/appstore/14-build-upload-submit-for-review.md`

- [ ] **Step 1: Archive the app**

Run from Xcode Product > Archive for a generic iOS device, or use the documented archive command in `docs/appstore/14-build-upload-submit-for-review.md`.

Expected:

- Archive succeeds.
- Team is `D62Y8JVXB9`.
- Bundle identifier is `com.1moby.allsensors`.
- HealthKit entitlement is present.
- Clinical Health Records entitlement is absent.

- [ ] **Step 2: Upload to App Store Connect**

Upload the archive using Xcode Organizer, Transporter, or the documented command in `docs/appstore/14-build-upload-submit-for-review.md`.

Expected:

- Upload succeeds.
- Export compliance uses non-exempt encryption value `false`.
- App Store Connect receives the build.

- [ ] **Step 3: Configure TestFlight beta metadata**

In App Store Connect TestFlight, set beta notes to match `docs/testflight-beta.md`:

```text
All Sensors reads iPhone sensor data locally for diagnostics, demonstrations, and optional export. Please test the six tabs, Health read-only flow, sensor logger, show-off modes, privacy controls, and local data deletion.
```

- [ ] **Step 4: Submit external beta for review**

Submit the build for TestFlight external testing.

Expected: Beta App Review accepts the build or returns actionable feedback. If feedback is returned, make code or metadata changes, rerun Task 8, and upload a new build.

- [ ] **Step 5: Record TestFlight result**

Run this prompt-driven command after TestFlight review completes. It refuses to append the note when any observed value is blank:

```bash
printf 'TestFlight build number: '
IFS= read -r TESTFLIGHT_BUILD
printf 'TestFlight status: '
IFS= read -r TESTFLIGHT_STATUS
test -n "$TESTFLIGHT_BUILD"
test -n "$TESTFLIGHT_STATUS"
cat >> docs/testflight-beta.md <<EOF

## External TestFlight - 2026-06-15

- Build: $TESTFLIGHT_BUILD
- Status: $TESTFLIGHT_STATUS
- Review notes used: \`docs/appstore/07-review-information.md\`.
EOF
```

- [ ] **Step 6: Commit TestFlight notes**

Run:

```bash
git add docs/testflight-beta.md docs/appstore/12-final-checklist.md docs/appstore/14-build-upload-submit-for-review.md
git commit -m "docs: record testflight beta result"
```

## Task 12: Final App Store Submission Gate

**Files:**
- Modify: `docs/appstore/*.md`
- Modify: `docs/appstore/metadata/**`

- [ ] **Step 1: Verify App Store metadata packet**

Run:

```bash
find docs/appstore/metadata -maxdepth 4 -type f -print -exec sed -n '1,120p' {} \;
```

Expected:

- Name: All Sensors.
- Bundle ID in notes: `com.1moby.allsensors`.
- Privacy URL: `https://anusoft.github.io/iphone-all-sensors/privacy.html`.
- Support URL: `https://anusoft.github.io/iphone-all-sensors/support.html`.
- Marketing URL: `https://anusoft.github.io/iphone-all-sensors/`.
- Health data description says read-only.
- No Clinical Health Records claim.

- [ ] **Step 2: Verify privacy labels against source**

Compare `docs/appstore/04-app-privacy-labels.md` and `iPhoneSensors/PrivacyInfo.xcprivacy`.

Expected:

- No tracking.
- No analytics.
- No third-party advertising.
- Health data is read only and not linked for tracking.
- Location is used only for app functionality when permission is granted.
- Logger files stay local unless the user exports them.

- [ ] **Step 3: Verify review information**

Open `docs/appstore/07-review-information.md` and confirm review notes include:

```text
HealthKit is read-only. The app does not write Health data and does not request Clinical Health Records.
Sensor logs are stored locally and can be deleted from Settings.
Location, camera, microphone, Bluetooth, and Health permissions are optional and permission-gated.
```

- [ ] **Step 4: Submit for App Review**

Submit the accepted TestFlight build for App Review in App Store Connect.

Expected:

- Build is selected.
- Screenshots are attached.
- App privacy answers are complete.
- Export compliance is complete.
- Review notes are present.
- Submission is accepted by App Store Connect.

- [ ] **Step 5: Record submission result**

Run this prompt-driven command after App Review submission. It refuses to append the note when any observed value is blank:

```bash
printf 'Submitted build number: '
IFS= read -r SUBMITTED_BUILD
printf 'Submission status: '
IFS= read -r SUBMISSION_STATUS
printf 'Follow-up required: '
IFS= read -r SUBMISSION_FOLLOW_UP
test -n "$SUBMITTED_BUILD"
test -n "$SUBMISSION_STATUS"
test -n "$SUBMISSION_FOLLOW_UP"
cat >> docs/appstore/12-final-checklist.md <<EOF

## App Review Submission - 2026-06-15

- Build: $SUBMITTED_BUILD
- Submission status: $SUBMISSION_STATUS
- Follow-up required: $SUBMISSION_FOLLOW_UP
EOF
```

- [ ] **Step 6: Commit submission notes**

Run:

```bash
git add docs/appstore
git commit -m "docs: record app store submission"
```

## Final Completion Audit

- [ ] **Step 1: Check worktree state**

Run:

```bash
git status --short
```

Expected: only intentional uncommitted changes remain. If unrelated user changes existed before this plan, do not revert them.

- [ ] **Step 2: Search for release-blocking stale claims**

Run:

```bash
rg -n 'https://1moby.com/privacy|com\.1moby\.iPhoneSensors|group\.com\.1moby\.iPhoneSensors|HealthKit.*disabled|5 tabs|five tabs' README.md docs iPhoneSensors
```

Expected: no stale runtime or release-blocking claims. Explicit historical notes are acceptable only when clearly labeled.

- [ ] **Step 3: Run final automated validation**

Run:

```bash
ruby Scripts/validate_no_force_unwraps.rb
ruby Scripts/validate_privacy_config.rb
ruby Scripts/validate_widget_claims.rb
xcodebuild test \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath /tmp/allsensors-final-tests.xcresult
xcodebuild build \
  -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

Expected:

```text
No force unwraps found
Privacy config OK
Widget claims OK
** TEST SUCCEEDED **
** BUILD SUCCEEDED **
```

- [ ] **Step 4: Confirm Apple Developer settings**

Confirm in Apple Developer Certificates, Identifiers & Profiles:

```text
Bundle ID: com.1moby.allsensors
Team ID: D62Y8JVXB9
HealthKit: enabled
Clinical Health Records: disabled
```

- [ ] **Step 5: Confirm final App Store Connect state**

Confirm in App Store Connect:

```text
App name: All Sensors
Bundle ID: com.1moby.allsensors
Build: uploaded and selected
Privacy URL: https://anusoft.github.io/iphone-all-sensors/privacy.html
Support URL: https://anusoft.github.io/iphone-all-sensors/support.html
Marketing URL: https://anusoft.github.io/iphone-all-sensors/
Review notes: include read-only HealthKit and local-only logger behavior
```
