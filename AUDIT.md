# Repository Audit & Improvement Plan — All Sensors

## Executive Summary

Health grade: **C+**. The app has a credible SwiftUI/iOS foundation, real sensor breadth, a meaningful local logging subsystem, App Store automation, screenshots, tests, and privacy/release documentation. It is not yet "complete and ready to use" because at least one advertised feature is not integrated into the build, privacy/review declarations do not fully match source behavior, and several data/privacy paths can mislead users or silently drop failures. Top risks: the WidgetKit code is not an Xcode target and its app-group id does not match any entitlement; HealthKit/read/privacy declarations are inconsistent across source, manifest, privacy policy, and review notes; logger/export/delete flows can lose or retain sensitive sensor data without clear user feedback. Top opportunities: make the app's differentiators review-proof by integrating the widget or removing the claim, harden privacy/data lifecycle behavior, and turn CI/lint/test coverage into a real shipping gate. The architecture is good enough to finish incrementally; avoid a broad rewrite. The best next step is an M0/M1 stabilization pass focused on build targets, privacy truthfulness, deletion/export behavior, and failing tests for these paths.

_Audit date: 2026-06-14 · Workspace: `/Users/mac/Projects/poc/iphone-all-sensors` · Mode: evidence-grounded audit_

Notes:
- Evidence is cited as `path:line`.
- Each finding is tagged **fact** when directly observed, or **judgment** when it interprets observed evidence.
- The worktree was already dirty at audit start (`git status --short` showed modified app, test, and docs files plus an untracked App Store doc). This audit describes the current working tree, not necessarily `HEAD`.
- `@RTK.md` is referenced by the prompt, but no `RTK.md` file was found under this workspace during discovery.

---

## Repo Map

**Purpose.** All Sensors is a SwiftUI iOS/iPadOS app that presents live iPhone/iPad sensor data, hardware diagnostics, Show-Off visualizations, data logging/export, App Intents, and WidgetKit source. The project guide describes live readouts, charts, Show-Off Mode, and CSV/JSON/SQLite logging (`CLAUDE.md:3`-`CLAUDE.md:5`). The README advertises supported sensor categories, real-time charts, diagnostic mode, sensor recording, App Intents, and a home-screen widget (`README.md:14`-`README.md:42`). Intended users appear to be consumers/tinkerers and App Store reviewers; maturity is an active indie App Store submission, not just a toy prototype, based on the App Store Connect runbook and build submission history (`CLAUDE.md:68`-`CLAUDE.md:78`).

**Stack and targets.** The app is an Xcode project at `iPhoneSensors/iPhoneSensors.xcodeproj` with scheme `iPhoneSensors`, bundle id `com.1moby.allsensors`, iOS 17 deployment, and iPhone/iPad device families (`CLAUDE.md:7`-`CLAUDE.md:16`). It uses SwiftUI, Combine, UIKit app delegate glue, AppIntents, WidgetKit, CoreMotion, CoreLocation, HealthKit, CoreBluetooth, AVFoundation, Swift Charts, and GRDB for SQLite. The only resolved third-party package found is `GRDB.swift` 7.10.0 (`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5`-`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:11`).

**Size.** Discovery found 108 Swift files (~22,898 LOC), 71 Markdown files (~11,406 LOC), 30 PNGs, plus small Python/Ruby/shell/YAML/plist config. The core application code is overwhelmingly Swift; docs and App Store materials are unusually substantial for a small iOS app.

**Architecture sketch.** `iPhoneSensorsApp` creates and injects the central `SensorManager`, seven concrete sensor managers, `LoggingService`, `LocalizationManager`, `DiagnosticManager`, `SensorRecorder`, `ThemeManager`, and `ScreenshotRouter` into SwiftUI (`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:5`-`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:31`). Startup bootstraps logging and attaches sample publishers from motion, location, environment, system, connectivity, camera, and health managers (`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:38`-`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:54`). `SensorManager` coordinates those managers and exposes a current-value accessor for App Intents (`iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:4`-`iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:14`, `iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:103`-`iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:140`). The logging subsystem is separate under `Services/Logging/`, with writers for CSV/JSON/SQLite. The widget source independently reads shared `UserDefaults` for the last sensor value (`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:34`-`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:58`).

**Key directories.**
- `iPhoneSensors/iPhoneSensors/App/` — SwiftUI app entry, tab root, App Intents.
- `iPhoneSensors/iPhoneSensors/Services/` — sensor acquisition, export, diagnostics, recording, localization, app logging.
- `iPhoneSensors/iPhoneSensors/Services/Logging/` — persistent logging, schema, storage, session lifecycle, CSV/JSON/SQLite writers.
- `iPhoneSensors/iPhoneSensors/Views/` — dashboard, sensor detail views, logger UI, components, screenshot capture views, Show-Off variants.
- `iPhoneSensors/iPhoneSensorsWidget/` — WidgetKit extension source and assets.
- `iPhoneSensors/iPhoneSensorsTests/` — unit and smoke tests, mostly logging plus some core manager/export tests.
- `.github/workflows/`, `.swiftlint.yml`, `fastlane/`, `Scripts/`, `docs/appstore/`, `screenshots/` — CI, lint, release, App Store, and screenshot automation.

**Identified core 20%.** This audit spent most effort on: app composition and App Intents (`App/`), `SensorManager` plus concrete managers in `Services/`, `Services/Logging/`, `DataExportManager`, `SensorRecorder`, `DiagnosticManager`, widget source and entitlements, tests, CI/lint, privacy/release config, and docs that describe shipping behavior. Detail views, Show-Off visualization variants, screenshot composition assets, and translated README files received lighter sampling.

**Current conventions.** The code now uses an `appLog` wrapper over `os.Logger` for most production logs (`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:4`-`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:20`), dependency injection in logging, SwiftUI `@EnvironmentObject` for app state, and a manually maintained Xcode project. The project guide explicitly warns the `project.pbxproj` is hand-written and adding a Swift file requires editing four sections by hand (`CLAUDE.md:18`-`CLAUDE.md:20`). CI exists and runs build/test on macOS 15 (`.github/workflows/ci.yml:25`-`.github/workflows/ci.yml:70`), but SwiftLint is currently non-blocking (`.github/workflows/ci.yml:13`-`.github/workflows/ci.yml:23`).

**Surprising observations.** The repository has useful shipping guardrails in place now: CI builds and tests the app (`.github/workflows/ci.yml:25`-`.github/workflows/ci.yml:70`), SwiftLint configuration exists (`.swiftlint.yml:1`-`.swiftlint.yml:39`), and most production logging is routed through `appLog` (`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:4`-`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:20`). The biggest integration gap is still product-facing: widget code exists, but it reads a stale app-group id (`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:39`) while the app entitlement only contains HealthKit (`iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements:5`-`iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements:6`).

---

## Audit Report

### Strengths To Preserve

- The app has a real central composition point: `iPhoneSensorsApp` creates the sensor managers, logging service, diagnostic manager, recorder, localization, theme, and screenshot router, then injects them into SwiftUI (`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:5`-`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:31`).
- Sensor startup is explicit and readable, with each manager started in one place (`iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:33`-`iPhoneSensors/iPhoneSensors/Services/SensorManager.swift:65`).
- Logging is opt-in by default, which is the right privacy posture for a sensor app (`iPhoneSensors/iPhoneSensors/Services/Logging/LoggingConfigStore.swift:14`-`iPhoneSensors/iPhoneSensors/Services/Logging/LoggingConfigStore.swift:24`, `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift:104`-`iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift:109`).
- GRDB is pinned in `Package.resolved`, reducing dependency drift (`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5`-`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:11`).
- The project has CI build/test coverage and a SwiftLint config, even if the lint gate is not yet strict (`.github/workflows/ci.yml:12`-`.github/workflows/ci.yml:70`, `.swiftlint.yml:1`-`.swiftlint.yml:39`).
- App Store and screenshot operations are unusually well documented for a small app (`CLAUDE.md:28`-`CLAUDE.md:78`, `docs/appstore/14-build-upload-submit-for-review.md:42`-`docs/appstore/14-build-upload-submit-for-review.md:169`).

### Architecture & Design

#### 1. **Fact - High - Advertised widget is not part of the build**

**What.** The README advertises a Home Screen Widget, with a caveat that it requires manual target setup (`README.md:40`-`README.md:41`, `README.md:175`-`README.md:188`). The repository contains widget source (`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:159`-`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:170`), but the Xcode project has only the app and unit-test native targets (`iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:547`-`iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:589`), and `xcodebuild -list` showed only `iPhoneSensors` and `iPhoneSensorsTests`.

**Where.** `README.md:40`, `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:547`, `iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:159`.

**Why it matters.** Users and reviewers cannot install the advertised widget from this project. This is a product completeness problem and an App Store metadata truthfulness risk.

#### 2. **Fact - High - Widget data sharing cannot work with current app-group configuration**

**What.** Widget code reads `UserDefaults(suiteName: "group.com.iphone-sensors")` (`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:38`-`iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:43`). The documented intended group is `group.com.1moby.iPhoneSensors` (`docs/features/08-home-screen-widget.md:47`-`docs/features/08-home-screen-widget.md:63`). The app entitlements file contains only HealthKit and no app group (`iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements:5`-`iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements:6`).

**Where.** `iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:39`, `docs/features/08-home-screen-widget.md:47`, `iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements:5`.

**Why it matters.** Even after adding the widget target, it will render fallback values unless both targets share the same App Group entitlement and the app writes widget values into that exact suite.

#### 3. **Judgment - Medium - App state is heavily global/singleton-based**

**What.** The app uses environment objects for many managers (`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:17`-`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:31`) plus static bridges for App Intents (`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:59`-`iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:65`) and singletons such as `DataExportManager.shared` (`iPhoneSensors/iPhoneSensors/Services/DataExportManager.swift:17`-`iPhoneSensors/iPhoneSensors/Services/DataExportManager.swift:19`) and `DiagnosticManager.shared` (`iPhoneSensors/iPhoneSensors/Services/DiagnosticManager.swift:31`-`iPhoneSensors/iPhoneSensors/Services/DiagnosticManager.swift:33`).

**Where.** `iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift:17`, `iPhoneSensors/iPhoneSensors/Services/DataExportManager.swift:19`, `iPhoneSensors/iPhoneSensors/Services/DiagnosticManager.swift:33`.

**Why it matters.** This is acceptable for a prototype-to-indie-app stage, but it makes targeted tests, previews, App Intent behavior, and future background/widget flows harder to reason about.

### Code Quality

#### 4. **Fact - High - Logger write failures are silently dropped**

**What.** CSV and JSON writers clear buffered data after write failures (`iPhoneSensors/iPhoneSensors/Services/Logging/Writers/CSVLogWriter.swift:34`-`iPhoneSensors/iPhoneSensors/Services/Logging/Writers/CSVLogWriter.swift:50`, `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/JSONLogWriter.swift:36`-`iPhoneSensors/iPhoneSensors/Services/Logging/Writers/JSONLogWriter.swift:54`). SQLite drops encode/insert failures without surfacing state (`iPhoneSensors/iPhoneSensors/Services/Logging/Writers/SQLiteLogWriter.swift:20`-`iPhoneSensors/iPhoneSensors/Services/Logging/Writers/SQLiteLogWriter.swift:47`). `LoggingService.startSessionFromUI` also catches start failures and resets UI state without a user-visible error (`iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift:123`-`iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift:134`).

**Where.** `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/CSVLogWriter.swift:50`, `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/JSONLogWriter.swift:52`, `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/SQLiteLogWriter.swift:46`, `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift:130`.

**Why it matters.** Users can believe a session was recorded while data was lost because disk, database, or file-handle errors have no durable error state or UI feedback.

#### 5. **Fact - Medium - Production `print` remains in privacy/export paths**

**What.** Most logging uses `appLog`, but `SettingsSheet.confirmDeleteAllData` still calls `print("[Privacy] All user data deleted")` (`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:756`-`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:770`). Network KML export prints failures directly (`iPhoneSensors/iPhoneSensors/Views/Sensors/NetworkDetailView.swift:124`-`iPhoneSensors/iPhoneSensors/Views/Sensors/NetworkDetailView.swift:125`).

**Where.** `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:770`, `iPhoneSensors/iPhoneSensors/Views/Sensors/NetworkDetailView.swift:124`.

**Why it matters.** It weakens the stated `appLog` convention and makes privacy-sensitive actions harder to filter/redact consistently.

#### 6. **Fact - Low - The source still carries a 5,175-line localization manager**

**What.** `LocalizationManager.swift` is 5,175 lines by LOC inventory, and `.swiftlint.yml` explicitly excludes it while noting migration to `.xcstrings` later (`.swiftlint.yml:8`-`.swiftlint.yml:10`).

**Where.** `.swiftlint.yml:8`.

**Why it matters.** This is not a release blocker, but it is the biggest maintainability hotspot. Translation regressions and merge conflicts are likely until the string table is moved into structured resources.

### Security & Privacy

#### 7. **Fact - High - Privacy manifest and App Store privacy answer disagree**

**What.** The published/privacy-doc position says App Privacy should be "Data Not Collected" (`docs/appstore/04-app-privacy-labels.md:5`-`docs/appstore/04-app-privacy-labels.md:13`, `docs/appstore/12-final-checklist.md:48`-`docs/appstore/12-final-checklist.md:54`). The checked-in privacy manifest declares `NSPrivacyCollectedDataTypeHealth` (`iPhoneSensors/PrivacyInfo.xcprivacy:9`-`iPhoneSensors/PrivacyInfo.xcprivacy:23`). The docs already call this out as an action-needed reconciliation issue (`docs/appstore/04-app-privacy-labels.md:49`-`docs/appstore/04-app-privacy-labels.md:59`).

**Where.** `iPhoneSensors/PrivacyInfo.xcprivacy:9`, `docs/appstore/04-app-privacy-labels.md:49`, `docs/appstore/12-final-checklist.md:52`.

**Why it matters.** Reviewers compare the privacy label, privacy policy, manifest, and app behavior. Inconsistent declarations create avoidable rejection risk and user-trust risk.

#### 8. **Fact - High - "Delete My Data" does not delete all user data/preferences**

**What.** The Settings UI exposes `Delete My Data` (`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:689`-`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:705`). The implementation deletes `SensorRecorder` recordings, all files in Documents, and one `seismometerAlarmHistory` key, but deliberately preserves consent timestamp and does not clear logger settings, HealthKit authorization request state, language/theme, Show-Off/GPS map settings, or other `@AppStorage`/`UserDefaults` keys (`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:756`-`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:770`; examples at `iPhoneSensors/iPhoneSensors/App/ContentView.swift:12`, `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:50`, `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerSettingsView.swift:6`-`iPhoneSensors/iPhoneSensors/Views/Logger/LoggerSettingsView.swift:9`, `iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_Motion.swift:659`-`iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_Motion.swift:669`).

**Where.** `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:756`, `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:50`, `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerSettingsView.swift:6`.

**Why it matters.** A privacy control that says it deletes "all" data but leaves meaningful local state behind can violate user expectations and privacy policy wording.

#### 9. **Fact - Medium - HealthKit scope and review/privacy docs are broader/narrower than each other**

**What.** The Health UI displays vitals, activity, body measurements, profile, and blood type/date of birth (`iPhoneSensors/iPhoneSensors/Views/Dashboard/HealthView.swift:112`-`iPhoneSensors/iPhoneSensors/Views/Dashboard/HealthView.swift:164`). Authorization requests read 24 HealthKit object types including blood pressure, oxygen saturation, electrodermal activity, waist circumference, biological sex, date of birth, and blood type (`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:110`-`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:135`). Review notes and privacy policy mention a smaller set such as steps, heart rate, active energy, distance, and sleep/workouts (`docs/appstore/07-review-information.md:41`-`docs/appstore/07-review-information.md:45`, `docs/appstore/05-privacy-policy.md:53`-`docs/appstore/05-privacy-policy.md:54`).

**Where.** `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:110`, `iPhoneSensors/iPhoneSensors/Views/Dashboard/HealthView.swift:112`, `docs/appstore/07-review-information.md:41`, `docs/appstore/05-privacy-policy.md:53`.

**Why it matters.** HealthKit permission sheets with many sensitive toggles invite extra scrutiny. The app should either reduce requested types to what it clearly explains or make review/privacy copy exactly match the broader feature.

#### 10. **Fact - Medium - HealthKit authorization UI treats request delivery as readiness**

**What.** `requestAuthorization` sets `hasRequestedAuthorization = success` and stores it (`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:137`-`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:152`). The displayed status maps any requested, available, no-error state to "Ready" (`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:60`-`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:68`). Apple intentionally does not reveal read-grant status; an authorization request returning successfully does not prove read access was granted.

**Where.** `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:60`, `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:137`.

**Why it matters.** Users who deny Health read access can see "Ready" with empty values. That is not a crash, but it is misleading and creates support/review confusion.

#### 11. **Fact - Medium - Sensitive identifiers and location are logged in clear app logs**

**What.** System startup logs the device name and identifier-for-vendor (`iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:72`-`iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:83`). Location updates log precise coordinates during early updates and every twentieth update (`iPhoneSensors/iPhoneSensors/Services/LocationSensorManager.swift:114`-`iPhoneSensors/iPhoneSensors/Services/LocationSensorManager.swift:116`). App logs are routed through `os.Logger` but without privacy annotations because `appLog` accepts preformatted strings (`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:4`-`iPhoneSensors/iPhoneSensors/Services/AppLog.swift:20`).

**Where.** `iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:83`, `iPhoneSensors/iPhoneSensors/Services/LocationSensorManager.swift:115`, `iPhoneSensors/iPhoneSensors/Services/AppLog.swift:4`.

**Why it matters.** Console/sysdiagnose logs can expose identifiers and precise location. This conflicts with a "local-only/no tracking" posture even if data is not transmitted.

### Testing

#### 12. **Fact - Medium - Tests cover core logging/model pieces but not widget or privacy lifecycle**

**What.** Test inventory shows XCTest unit tests for logging writers, schema, config, session lifecycle, sensor IDs/payloads, Health status text, and smoke cases (`iPhoneSensors/iPhoneSensorsTests/CSVLogWriterTests.swift:4`-`iPhoneSensors/iPhoneSensorsTests/CSVLogWriterTests.swift:14`, `iPhoneSensors/iPhoneSensorsTests/DatabaseSchemaTests.swift:5`-`iPhoneSensors/iPhoneSensorsTests/DatabaseSchemaTests.swift:29`, `iPhoneSensors/iPhoneSensorsTests/SessionLifecycleTests.swift:5`-`iPhoneSensors/iPhoneSensorsTests/SessionLifecycleTests.swift:90`, `iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift:5`-`iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift:33`). No test references the widget suite name/app group path, privacy manifest reconciliation, or delete-all-data behavior.

**Where.** `iPhoneSensors/iPhoneSensorsTests/SessionLifecycleTests.swift:5`, `iPhoneSensors/iPhoneSensorsTests/HealthSensorManagerTests.swift:5`, `iPhoneSensors/iPhoneSensorsWidget/iPhoneSensorsWidget.swift:39`.

**Why it matters.** The riskiest current product-readiness failures are not guarded by tests, so they can regress silently.

#### 13. **Fact - Medium - CI lint is intentionally non-blocking**

**What.** CI installs SwiftLint but runs `swiftlint lint ... || true` with a comment that it only surfaces warnings for now (`.github/workflows/ci.yml:13`-`.github/workflows/ci.yml:23`). The local environment used for this audit did not have SwiftLint installed, so local lint status is unverified.

**Where.** `.github/workflows/ci.yml:20`.

**Why it matters.** Lint guardrails do not prevent regressions in the exact areas the ruleset is trying to protect, including force unwrap warnings (`.swiftlint.yml:25`-`.swiftlint.yml:32`).

### Performance

#### 14. **Judgment - Medium - Disk-space sampling and verbose logs are high-churn during sensor runs**

**What.** `SystemSensorManager` runs a repeating 2-second timer, reads disk attributes, updates uptime/low-power/brightness, publishes disk/uptime/lowPower samples, and `updateDiskSpace` logs free/total disk on each call (`iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:161`-`iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:180`, `iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:199`-`iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:207`).

**Where.** `iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:161`, `iPhoneSensors/iPhoneSensors/Services/SystemSensorManager.swift:206`.

**Why it matters.** This is probably acceptable while foregrounded, but it increases IO/log volume in an app already sampling many sensors. If users leave it open for long sessions, battery and log noise can grow.

#### 15. **Judgment - Low - Show-Off screens rely on many fixed frames**

**What.** The Show-Off variants intentionally use many fixed `Spacer().frame(...)` and fixed visualization frames (examples: `iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_Environment.swift:67`, `iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_System.swift:607`, `iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_Motion.swift:364`). The app does use adaptive layout metrics elsewhere (`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:21`-`iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:42`).

**Where.** `iPhoneSensors/iPhoneSensors/Views/ShowOff/ShowOffVariants_Environment.swift:67`, `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift:21`.

**Why it matters.** This is not automatically wrong for theatrical full-screen visualizations, but it needs screenshot/device verification on iPhone SE, iPhone Pro Max landscape, iPad Split View, and large Dynamic Type.

### Dependencies

#### 16. **Fact - Low - Dependency surface is small and pinned**

**What.** GRDB is the only resolved SPM dependency and is pinned to 7.10.0 (`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5`-`iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:11`).

**Where.** `iPhoneSensors/iPhoneSensors.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:5`.

**Why it matters.** Healthy dimension. Keep the dependency footprint small; audit GRDB updates periodically rather than adding generic dependency tooling.

### DevEx & Operations

#### 17. **Fact - Medium - Manual project-file maintenance is a recurring operational risk**

**What.** The project guide says the `.pbxproj` is hand-written and adding a Swift file requires editing four sections manually (`CLAUDE.md:18`-`CLAUDE.md:20`). The current widget gap is consistent with this risk: widget files exist but no native extension target is present (`iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:547`-`iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:589`).

**Where.** `CLAUDE.md:18`, `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj:547`.

**Why it matters.** Manual project graph changes are easy to miss and hard to review. This is likely to recur as assets, widgets, app intents, and tests grow.

#### 18. **Fact - Medium - Release docs contain real App Store credentials metadata**

**What.** Docs include App Store Connect key IDs, issuer ID, app ID, and local key paths (`docs/appstore/13-api-publish-runbook.md:21`-`docs/appstore/13-api-publish-runbook.md:28`, `docs/appstore/14-build-upload-submit-for-review.md:17`-`docs/appstore/14-build-upload-submit-for-review.md:23`). The private `.p8` contents are not committed, and scripts read the key from environment/default key path (`Scripts/appstore/asc.py:37`-`Scripts/appstore/asc.py:42`).

**Where.** `docs/appstore/13-api-publish-runbook.md:21`, `docs/appstore/14-build-upload-submit-for-review.md:17`, `Scripts/appstore/asc.py:39`.

**Why it matters.** Key IDs and issuer IDs are not sufficient by themselves to authenticate, but they are operationally sensitive. If this repo is public, rotate/restrict keys and consider moving exact values to private operator docs.

### Documentation

#### 19. **Fact - High - Product/docs say widget and write-to-Health behavior that source does not support**

**What.** README says the widget is code-ready but manual (`README.md:188`); the project has no widget target. Privacy/support docs mention HealthKit write behavior via Logger (`docs/appstore/05-privacy-policy.md:53`-`docs/appstore/05-privacy-policy.md:54`, `docs/appstore/06-support-page.md:119`-`docs/appstore/06-support-page.md:121`), but source HealthKit authorization passes `toShare: nil` (`iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:137`) and the audit found no HealthKit save path.

**Where.** `README.md:188`, `docs/appstore/05-privacy-policy.md:54`, `iPhoneSensors/iPhoneSensors/Services/HealthSensorManager.swift:137`.

**Why it matters.** Documentation drift is now user-facing and reviewer-facing. For App Store submission, inaccurate claims can be worse than missing features.

#### 20. **Fact - Low - `AGENTS.md` references missing `RTK.md`**

**What.** The instruction prompt references `@RTK.md`, but no `RTK.md` was found under the workspace during discovery. `AGENTS.md` itself contains only Apple Developer configuration (`AGENTS.md:1`-`AGENTS.md:10`).

**Where.** `AGENTS.md:1`.

**Why it matters.** This is a minor repo hygiene gap, but missing agent instructions can cause inconsistent future edits.

---

## Improvement Strategy

### Theme 1: Make App Store Claims Match The Binary

**Target state.** Every App Store claim, README feature, privacy label, privacy manifest, and reviewer note is true for the built `.ipa`.

**Guiding principle.** Prefer removing or narrowing claims over rushing incomplete features into a release.

**Trade-offs.** Integrating the widget is valuable but touches project structure, signing, app groups, and widget data flow. Removing widget claims is faster but less impressive.

**What not to fix yet.** Do not add background sensor modes or HealthKit writes just to match old docs; those increase review risk and are not needed for a solid v1.

**Definition of done.** `xcodebuild -list` shows all advertised targets, privacy manifest/data-label docs agree, review notes match HealthKit types requested, and README has no "manual setup required" user-facing feature claims.

### Theme 2: Treat Local Sensor Data As Sensitive

**Target state.** Logging, export, delete, and diagnostics have explicit user-visible states for data creation, failure, deletion, and sharing.

**Guiding principle.** Local-only does not mean low-risk; precise location, HealthKit metrics, identifiers, and sensor recordings still deserve clear controls.

**Trade-offs.** More confirmation and error UI can add friction. Keep it targeted to sessions/export/delete and do not interrupt passive sensor viewing.

**What not to fix yet.** Do not implement cloud sync, accounts, encryption-at-rest, or Keychain unless product intent changes.

**Definition of done.** Delete-all-data clears documented local storage/state or names what it preserves; logger write failures surface in UI/tests; logs redact location and identifiers; export warnings are tested.

### Theme 3: Stabilize Build, Test, And Project Graph Guardrails

**Target state.** A clean checkout can build/test/lint the app and any shipped extension without manual Xcode edits.

**Guiding principle.** Automate the project graph enough to prevent missing-target regressions, even if the app stays in a plain Xcode project.

**Trade-offs.** Moving to XcodeGen/Tuist is larger than necessary; a focused project-file validation script may be enough for this stage.

**What not to fix yet.** Do not migrate to Swift Package modularization until the current App Store blockers are resolved.

**Definition of done.** CI fails on test/build failures and selected lint rules; CI or a script verifies widget target/app group when widget is claimed; privacy plist lint and manifest checks run in CI.

### Theme 4: Improve HealthKit Trustworthiness

**Target state.** HealthKit asks for a minimal, explained read set, renders empty/denied states honestly, and does not imply medical or write behavior that does not exist.

**Guiding principle.** HealthKit read denial is indistinguishable from no data; UI copy must reflect that instead of claiming readiness.

**Trade-offs.** Requesting fewer HealthKit types reduces permission friction but may reduce dashboard breadth. Broad reads are acceptable only if the Health tab and privacy policy explain them clearly.

**What not to fix yet.** Do not enable Clinical Health Records or HealthKit writes for v1.

**Definition of done.** Health UI never equates request success with granted read access; App Review notes list the same categories the app requests; tests cover authorization copy states.

---

## Task Plan

### M0: Safety Net - Tests, CI, Guardrails Before Refactoring

#### Task M0.1 - Add privacy/config validation script

**Description.** Add a small read-only script that checks plist validity, required reason API declarations, widget claim/target consistency, app group consistency, and no Clinical Health Records entitlement.

**Files/areas affected.** `Scripts/`, `.github/workflows/ci.yml`, `iPhoneSensors/PrivacyInfo.xcprivacy`, `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`, `iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements`.

**Acceptance criteria.** CI fails if widget is advertised but no widget target exists; fails if a widget suite name has no matching app group entitlement; fails if manifest collected-data claims contradict configured App Privacy source; passes on a clean aligned tree.

**Effort.** M.

**Change risk.** Low; script-only plus CI.

**Dependencies.** None.

#### Task M0.2 - Make SwiftLint a selective blocking gate

**Description.** Install/run SwiftLint in CI as blocking for a small set of high-signal rules after cleaning current violations or scoping rules to touched areas.

**Files/areas affected.** `.github/workflows/ci.yml`, `.swiftlint.yml`, small source cleanup if needed.

**Acceptance criteria.** CI no longer uses `|| true`; `force_unwrapping` and no-production-`print` equivalent checks fail the build or a custom `rg` step catches them.

**Effort.** S.

**Change risk.** Low.

**Dependencies.** M0.1 optional.

#### Task M0.3 - Add tests for local data lifecycle

**Description.** Extract deletion logic into a testable service and add tests for recorder files, exported files, logger storage, and declared `UserDefaults` keys.

**Files/areas affected.** `Views/Components/SensorComponents.swift`, new service under `Services/`, `iPhoneSensorsTests/`.

**Acceptance criteria.** A test proves delete-all-data removes every key documented for deletion and preserves only explicitly documented audit fields.

**Effort.** M.

**Change risk.** Medium.

**Dependencies.** None.

### M1: Critical Security And Correctness

#### Task M1.1 - Decide and fix widget product path

**Description.** Either integrate the widget as a real extension target with matching App Group entitlements and app writes, or remove widget claims/docs/screenshots until it ships.

**Files/areas affected.** `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`, `iPhoneSensors/iPhoneSensorsWidget/`, `iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements`, README/docs, possibly widget entitlements.

**Acceptance criteria.** If shipped, `xcodebuild -list` includes the widget scheme/target, both app and widget use one App Group id, the app writes `widget_sensor_*` values, and widget tests or validation cover the suite name. If not shipped, README/App Store docs no longer present it as a current feature.

**Effort.** L to integrate, S to remove claims.

**Change risk.** High if integrating because of signing/project graph; low if removing claims.

**Dependencies.** M0.1 recommended.

#### Task M1.2 - Reconcile privacy manifest, privacy policy, and App Privacy answer

**Description.** Pick the truthful stance for HealthKit/local logs, then align `PrivacyInfo.xcprivacy`, docs, metadata, and App Store checklist.

**Files/areas affected.** `iPhoneSensors/PrivacyInfo.xcprivacy`, `docs/appstore/04-app-privacy-labels.md`, `docs/appstore/05-privacy-policy.md`, `docs/privacy.html`, `docs/appstore/metadata/`, README if needed.

**Acceptance criteria.** No contradiction between "Data Not Collected" and manifest collected-data entries; policy accurately describes local logger persistence and HealthKit read/write behavior; `plutil -lint` passes.

**Effort.** S.

**Change risk.** Medium because it affects external declarations.

**Dependencies.** Human decision on privacy stance.

#### Task M1.3 - Fix delete-all-data semantics

**Description.** Replace the current partial deletion code with a data lifecycle service that removes all local app data covered by the UI claim, or changes copy to "Delete recordings and exports" if preferences are intentionally preserved.

**Files/areas affected.** `Views/Components/SensorComponents.swift`, `Services/Logging/`, `SensorRecorder`, `UserDefaults` keys.

**Acceptance criteria.** User-facing copy matches actual deletion; logger storage, exports, recordings, alarm/signal-map data, and selected preferences are covered by tests; completion/failure is visible to the user.

**Effort.** M.

**Change risk.** Medium; deletion is destructive.

**Dependencies.** M0.3.

#### Task M1.4 - Redact or remove sensitive app logs

**Description.** Stop logging identifier-for-vendor and precise coordinates by default. Use `Logger` privacy annotations or coarse/debug-only logging where appropriate.

**Files/areas affected.** `AppLog.swift`, `SystemSensorManager.swift`, `LocationSensorManager.swift`, Health logging sites.

**Acceptance criteria.** Production logs do not include raw coordinates, date of birth, blood type, device name, or identifier-for-vendor; debug builds can opt into sensitive logs explicitly.

**Effort.** S.

**Change risk.** Low.

**Dependencies.** None.

### M2: High-Leverage Improvements

#### Task M2.1 - Make logger failures user-visible and testable

**Description.** Add writer/coordinator error reporting so failed file/database writes update logger UI and do not silently clear buffered data without a recorded failure.

**Files/areas affected.** `Services/Logging/Writers/`, `LoggingCoordinator.swift`, `LoggingService.swift`, `Views/Logger/`.

**Acceptance criteria.** Tests simulate unwritable storage or a failing writer and assert visible error state; UI shows "Recording failed" or similar; successful sessions still pass existing tests.

**Effort.** L.

**Change risk.** Medium-high; actor/error propagation touches core logging.

**Dependencies.** M0 tests.

#### Task M2.2 - Tighten HealthKit request and empty-state copy

**Description.** Make requested HealthKit types match the visible Health tab and review notes, or split advanced health metrics behind an in-tab explanation. Change "Ready" copy so it means "request processed" rather than "read granted."

**Files/areas affected.** `HealthSensorManager.swift`, `HealthView.swift`, localization strings, App Store review notes/privacy docs.

**Acceptance criteria.** Health permission rationale lists the same categories requested; denied/no-data states are honest; tests cover `authorizationStatusText`.

**Effort.** M.

**Change risk.** Medium; touches sensitive permission UX.

**Dependencies.** M1.2 decision.

#### Task M2.3 - Validate adaptive UI on target devices

**Description.** Run screenshot/UI checks on iPhone SE width, iPhone 6.9, iPad 13, iPad split-width, dark/light, and large Dynamic Type.

**Files/areas affected.** `screenshots/`, `Views/ShowOff/`, `Views/Components/`, docs.

**Acceptance criteria.** Known target view set has screenshots with no clipped/overlapping primary text; documented device matrix exists; top layout bugs are filed or fixed.

**Effort.** M.

**Change risk.** Low for validation, medium for fixes.

**Dependencies.** None.

### M3: Quality And Polish

#### Task M3.1 - Migrate localization data out of the 5k-line manager

**Description.** Move translation dictionaries into `.xcstrings`, `.stringsdict`, JSON, or another structured resource and keep `LocalizationManager` focused on lookup/state.

**Files/areas affected.** `LocalizationManager.swift`, resources, tests/docs.

**Acceptance criteria.** `LocalizationManager.swift` drops below 500 lines; translation files validate; existing localization smoke tests pass.

**Effort.** XL.

**Change risk.** High; needs careful regression checks across languages.

**Dependencies.** M1/M2 blockers resolved first.

#### Task M3.2 - Replace manual project graph risk with generation or validation

**Description.** Adopt XcodeGen/Tuist or maintain a focused project validation script that catches orphaned Swift files, missing targets, and missing resources.

**Files/areas affected.** Xcode project, scripts, CI.

**Acceptance criteria.** CI fails when a Swift file under app/widget source is not in the intended target; documented workflow for adding files exists.

**Effort.** M for validation, XL for generation migration.

**Change risk.** Medium to high.

**Dependencies.** M1.1 if integrating widget.

#### Task M3.3 - Product polish and assets pass

**Description.** After correctness/privacy blockers, generate or refine visual assets for icon/widget/screenshot surfaces and verify screenshots against App Store dimensions.

**Files/areas affected.** `Assets.xcassets`, `screenshots/`, `docs/screenshots.md`, possibly `iPhoneSensorsWidget/Assets.xcassets`.

**Acceptance criteria.** App icon and screenshot assets are consistent with current UI; `screenshots/run.sh` produces valid upload dimensions; widget assets exist if widget ships.

**Effort.** M.

**Change risk.** Low-medium.

**Dependencies.** M1.1.

### Quick Wins

- Remove or correct widget claims until the target is integrated. Effort S, impact high.
- Remove `NSPrivacyCollectedDataTypeHealth` or update App Privacy/docs so declarations agree. Effort S, impact high.
- Replace remaining production `print` calls with `appLog` or user-visible errors. Effort S, impact medium.
- Update HealthKit review notes to match actual requested/displayed types. Effort S, impact medium-high.
- Make CI lint fail for new `print(` in app Swift files. Effort S, impact medium.

### Implementation Sketches For Top 3 Tasks

#### Sketch 1 - Widget Decision

1. Run `xcodebuild -list -project iPhoneSensors/iPhoneSensors.xcodeproj` and keep the output in the PR.
2. If shipping the widget, add a WidgetKit extension target with bundle id `com.1moby.allsensors.widget`, product type `com.apple.product-type.app-extension`, and sources under `iPhoneSensors/iPhoneSensorsWidget/`.
3. Add app group entitlement to app and widget using one chosen id, preferably `group.com.1moby.allsensors` or the already documented `group.com.1moby.iPhoneSensors`; update `UserDefaults(suiteName:)` to match.
4. Add app-side write path for `widget_sensor_name`, `widget_sensor_value`, `widget_sensor_unit`, and `widget_sensor_active`.
5. Add validation that fails if widget source exists but no widget target/app group exists.

#### Sketch 2 - Privacy Reconciliation

1. Decide whether local-only HealthKit reads/logs count as "not collected" for App Privacy. Current docs argue yes.
2. If keeping "Data Not Collected", remove `NSPrivacyCollectedDataTypeHealth` from `PrivacyInfo.xcprivacy` and keep only required-reason APIs.
3. Correct the disk-space reason code discrepancy: shipped manifest uses `E174.1` (`iPhoneSensors/PrivacyInfo.xcprivacy:34`-`iPhoneSensors/PrivacyInfo.xcprivacy:40`) while docs recommend `85F4.1` (`docs/appstore/04-app-privacy-labels.md:94`-`docs/appstore/04-app-privacy-labels.md:100`); verify against current Apple allowed reasons before editing.
4. Update privacy policy/support/review notes so HealthKit write claims are removed unless a write path is implemented.
5. Run `plutil -lint iPhoneSensors/PrivacyInfo.xcprivacy` and archive a Release build before submission.

#### Sketch 3 - Delete-All-Data Service

1. Create `LocalDataDeletionService` with injectable `FileManager`, document root, log storage root, and `UserDefaults`.
2. Move the deletion list into named keys/constants: recorder files, `SensorLogs`, exported `sensor_data_*`, `seismometerAlarmHistory`, logger settings, Health authorization requested flag, Show-Off/GPS map preferences as product decides.
3. Return a result with deleted paths, deleted keys, preserved keys, and errors.
4. Update Settings UI to show success/failure and exact copy: either "Delete recordings and exports" or "Delete all app data on this device."
5. Add unit tests with a temporary directory and isolated `UserDefaults(suiteName:)`.

---

## Open Questions

1. Should the v1 release ship a real Home Screen Widget, or should widget claims be removed until a later version?
2. What is the final App Privacy stance: "Data Not Collected" with no manifest collected-data entries, or a conservative declaration for locally processed Health data?
3. Should HealthKit be limited to the smaller set in review notes, or is the full vitals/body/profile dashboard intentional for v1?
4. Should "Delete My Data" delete preferences and consent timestamps, or should the UI explicitly preserve some local audit/config state?
5. Is this repository public? If yes, should App Store Connect key IDs/issuer IDs be moved out of committed docs even though private key contents are absent?
6. What device/performance targets define "ready": minimum iPhone SE support, iPad Split View, max session duration, battery budget, and logger data-loss tolerance?

---

## Remediation Log

### 2026-06-15 - Logging Privacy Quick Win

- Replaced remaining direct production `print(` calls in app Swift files with `appLog`, covering privacy deletion, KML export failure, and haptic setup/playback errors.
- Redacted debug logs that previously emitted device name, identifier-for-vendor, and precise latitude/longitude; system/location logs now record non-sensitive event metadata only.
- Added CI guards that fail on new direct `print(` calls under `iPhoneSensors/iPhoneSensors` and on `appLog` calls that interpolate known sensitive identifier/precise-coordinate patterns.
- Verification: local guard commands returned no matches; `.github/workflows/ci.yml` parsed with Ruby YAML; `git diff --check` passed for touched files; `xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test` passed 47 tests with 0 failures.

### 2026-06-15 - Privacy Manifest / HealthKit Docs Alignment

- Aligned `PrivacyInfo.xcprivacy` with the App Store "Data Not Collected" stance by keeping `NSPrivacyCollectedDataTypes` empty and retaining only required-reason API declarations.
- Corrected the disk-space required-reason declaration to the display-storage reason used by the app system sensor UI.
- Removed HealthKit write-purpose claims from build settings, App Store metadata, privacy/support docs, and internal purpose-string references because the app requests HealthKit read access only.
- Added `Scripts/validate_privacy_config.rb` and a CI step that fails when the privacy manifest, App Privacy doc, required-reason API declarations, or Clinical Health Records entitlement drift from the shipping privacy stance.
- Verification: Ruby YAML parse passed for `.github/workflows/ci.yml`; local logging guards returned no matches; `Scripts/validate_privacy_config.rb` printed `Privacy config OK`; `plutil -lint iPhoneSensors/PrivacyInfo.xcprivacy iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements iPhoneSensors/iPhoneSensors/Info.plist` passed; `git diff --check` passed for touched privacy/docs files; `xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test` passed 47 tests with 0 failures.

### 2026-06-15 - Widget Claim Truthfulness Guard

- Chose the safe v1 path for the widget gap: keep `iPhoneSensors/iPhoneSensorsWidget/` as a future WidgetKit scaffold, but remove or narrow user-facing claims that presented it as a current shipping feature.
- Updated README and feature catalogs to say the widget is deferred until a real extension target, matching App Group entitlements, and app-side `widget_sensor_*` writes exist.
- Removed stale widget-bridge wording from `iPhoneSensorsApp` comments because App Intents are the only current foreground reader using the shared `SensorManager` handle.
- Added `Scripts/validate_widget_claims.rb` and a CI step that fails if public docs advertise widget support while `xcodebuild -list` does not expose a widget target.
- Verification: `Scripts/validate_widget_claims.rb` printed `Widget claims OK`; Ruby YAML parse passed for `.github/workflows/ci.yml`; privacy/logging guards still passed; plist lint passed for app privacy, app entitlements, app Info.plist, and widget scaffold Info.plist; `git diff --check` passed for touched widget/docs files; after a transient simulator-busy launch failure, booting the selected iPhone 17 Pro Max simulator and rerunning `xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'id=5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7' test` passed 47 tests with 0 failures.

### 2026-06-15 - Delete My Data Semantics

- Added a dedicated `LocalDataDeletionService` that deletes app-generated local artifacts while preserving unrelated user documents: logger directories (`Logging`, `SensorLogs`) and generated exports with `sensor_data_` / `signal_map_` prefixes are removed from Documents.
- Cleared app-owned local state for logger configuration, HealthKit request state, permission flow/tutorial state, seismometer alarm history, and GPS map preferences; preserved consent history plus language/theme preferences pending the product decision captured in Open Questions.
- Updated the Settings deletion path to call `SensorRecorder.shared.deleteAllRecordings()` and the new deletion service, with privacy-scoped logging for success/error count instead of silent behavior.
- Added `LocalDataDeletionServiceTests` covering generated-file deletion, unrelated-document preservation, app-owned UserDefaults deletion, and consent/language/theme preservation.
- Verification: targeted `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --extra-args '-only-testing:iPhoneSensorsTests/LocalDataDeletionServiceTests' --progress --output text` passed 2 tests with 0 failures; Ruby YAML parse passed for `.github/workflows/ci.yml`; `Scripts/validate_privacy_config.rb` printed `Privacy config OK`; `Scripts/validate_widget_claims.rb` printed `Widget claims OK`; logging guards returned no matches; plist lint passed for the privacy manifest, app entitlements, app Info.plist, and widget scaffold Info.plist; `git diff --check` passed for touched files; full `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --progress --output text` passed 49 tests with 0 failures.

### 2026-06-15 - HealthKit Read Authorization Copy

- Changed HealthKit status text from `Ready` to `Access Requested` after the HealthKit prompt is processed, because HealthKit does not reveal whether read access was granted.
- Updated the HealthKit authorization log line to say the request was delivered instead of implying the app is authorized or ready to read.
- Updated support copy to explain that empty HealthKit results can mean access is off or no matching samples exist, and to direct users to iOS Health privacy settings for confirmation.
- Added/updated `HealthSensorManagerTests` to assert the corrected post-request status text; the test was run red first and failed with `("Ready") is not equal to ("Access Requested")` before the production change.
- Verification: targeted `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --extra-args '-only-testing:iPhoneSensorsTests/HealthSensorManagerTests' --progress --output text` passed 3 tests with 0 failures; Ruby YAML parse passed for `.github/workflows/ci.yml`; `Scripts/validate_privacy_config.rb` printed `Privacy config OK`; `Scripts/validate_widget_claims.rb` printed `Widget claims OK`; logging guards returned no matches; plist lint passed for the privacy manifest, app entitlements, app Info.plist, and widget scaffold Info.plist; `git diff --check` passed for touched files; full `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --progress --output text` passed 49 tests with 0 failures.

### 2026-06-15 - Logger Failure Visibility

- Added writer-level failure state to `LogWriter`: file/database writers now expose `pendingBytes` and `lastErrorMessage` so failed flushes are observable.
- Changed CSV/JSON/SQLite writers to preserve buffered/pending samples when a flush fails instead of clearing data silently; successful flushes still clear buffers and reset the error.
- Changed `LoggingCoordinator.flushAll()` to return the latest writer error after flushing, allowing higher layers to surface storage failures.
- Added `LoggingService.lastLoggingError`, set it for session-start failures and writer flush failures, and displayed it in `LoggerStatusHeaderView` with an alert icon.
- Added regression tests for JSON writer flush failure preservation, coordinator flush error propagation, and `LoggingService` start-session failure publishing.
- Verification: red tests first exposed the missing writer API (`JSONLogWriter` had no `pendingBytes` / `lastErrorMessage`) and missing coordinator contract (`flushAll()` returned `Void`); focused logging tests passed 12 tests with 0 failures; Ruby YAML parse passed for `.github/workflows/ci.yml`; `Scripts/validate_privacy_config.rb` printed `Privacy config OK`; `Scripts/validate_widget_claims.rb` printed `Widget claims OK`; logging guards returned no matches; plist lint passed for the privacy manifest, app entitlements, app Info.plist, and widget scaffold Info.plist; `git diff --check` passed; full `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --progress --output text` passed 52 tests with 0 failures.

### 2026-06-15 - Blocking Lint And Force-Unwrap Guard

- Made SwiftLint blocking in CI by removing the temporary `|| true` escape hatch, and promoted the `force_unwrapping` rule from warning to error.
- Added `Scripts/validate_no_force_unwraps.rb`, wired it into CI, and verified it failed before cleanup on HealthKit type construction, logging fallback, privacy link URL construction, map config reads, tests, and the widget scaffold.
- Removed force unwraps from app, test, and widget Swift files outside the excluded generated/string-table localization manager. HealthKit read types are now built through a safe helper, continuous SQLite logging no longer falls back to an in-memory database if persistent storage cannot open, the widget refresh date uses a fallback, and XCTest setup uses `XCTUnwrap` in throwing tests/helpers.
- Added `HealthSensorManagerTests.testHealthReadTypesCanBeBuiltWithoutForceUnwraps` to cover the HealthKit read-type set without relying on force unwraps.
- Verification: `Scripts/validate_no_force_unwraps.rb` first failed with force-unwrap matches, then printed `No force unwraps found`; targeted `HealthSensorManagerTests` passed 4 tests with 0 failures; targeted `LoggingCoordinatorTests` passed 2 tests with 0 failures; Ruby YAML parse passed for `.github/workflows/ci.yml`; `Scripts/validate_privacy_config.rb` printed `Privacy config OK`; `Scripts/validate_widget_claims.rb` printed `Widget claims OK`; production print and sensitive-log guards returned no matches; plist lint passed for the privacy manifest, app entitlements, app Info.plist, and widget scaffold Info.plist; `git diff --check` passed; full `xcodebuildmcp simulator test --project-path iPhoneSensors/iPhoneSensors.xcodeproj --scheme iPhoneSensors --simulator-id 5AAB3C46-0246-44CF-B44E-24DF1FFE2AA7 --progress --output text` passed 56 tests with 0 failures.
