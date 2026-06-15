---
name: all-sensor-current-features
description: Authoritative feature catalog for the All Sensors iOS app (com.1moby.iPhoneSensors), reflecting the codebase as of 2026-05-07.
---

# All Sensors — Current Features

> **App:** All Sensors (`com.1moby.iPhoneSensors`)
> **Platform:** iOS 17+ (iPhone & iPad)
> **Snapshot date:** 2026-05-07
> **Source:** Direct read of `iPhoneSensors/iPhoneSensors/` source tree.

This document supersedes `docs/current-allsensors-features.md` (dated 2026-05-06), incorporating the Logger Phase 4/5 work merged on the current branch.

---

## Table of contents

1. [App shell & navigation](#1-app-shell--navigation)
2. [Sensor coverage](#2-sensor-coverage)
3. [Real-time dashboard](#3-real-time-dashboard)
4. [Sensor detail views](#4-sensor-detail-views)
5. [Live data visualization](#5-live-data-visualization)
6. [Quick recording (in-memory)](#6-quick-recording-in-memory)
7. [Sensor logging system (persistent)](#7-sensor-logging-system-persistent)
8. [Data viewer & file browser](#8-data-viewer--file-browser)
9. [Diagnostics](#9-diagnostics)
10. [App Intents & Siri](#10-app-intents--siri)
11. [Future widget scaffold](#11-future-widget-scaffold)
12. [Localization](#12-localization)
13. [Theme & UI system](#13-theme--ui-system)
14. [Permissions](#14-permissions)
15. [Privacy & compliance](#15-privacy--compliance)
16. [Power & thermal management](#16-power--thermal-management)
17. [Tests](#17-tests)
18. [Repository structure](#18-repository-structure)

---

## 1. App shell & navigation

- **Entry point:** `iPhoneSensorsApp` injects 9 environment objects (`SensorManager` and its sub-managers, `LocalizationManager`, `LoggingService`, `ThemeManager`, `DiagnosticManager`, `SensorRecorder`).
- **`AppDelegate`** flushes the logging service on `applicationWillTerminate` (semaphore-bounded 200 ms).
- **Tab bar — 6 tabs:**
  1. Sensors (`DashboardView`)
  2. System (`SystemInfoView`)
  3. Environment (`EnvironmentView`)
  4. Diagnostic (`DiagnosticView`)
  5. Health (`HealthView`)
  6. Logger (`LoggerOverviewView`) — **new in Phase 4/5**
- **First-run flow:** `PermissionRequestView` is shown until `hasCompletedPermissionFlow` is set in `@AppStorage`, then `SensorManager.startAllSensors()` runs.
- **Tab bar styling:** translucent toolbar background tracking light/dark color scheme.

---

## 2. Sensor coverage

The runtime exposes **26 logical sensor IDs** (`SensorID` enum) grouped into 7 categories. The dashboard surfaces ~21 of these as user-visible cards; the rest are event-driven feeds that only appear in the Logger.

### Motion (7)
| ID | Source framework | Notes |
|---|---|---|
| `motion.accelerometer` | CoreMotion | 100 Hz hardware max, 10 ms `minIntervalMs` |
| `motion.gyroscope` | CoreMotion | 100 Hz hardware max |
| `motion.magnetometer` | CoreMotion | 100 Hz hardware max |
| `motion.deviceMotion` | CoreMotion | Roll/pitch/yaw, gravity, user accel, quaternion, rotation matrix |
| `motion.altimeter` | CoreMotion | Relative altitude + pressure, 1 Hz min |
| `motion.pedometer` | CoreMotion | Steps, distance, floors, pace, cadence |
| `motion.activity` | CoreMotion | Walking/running/cycling/automotive/stationary |

### Location (2)
| ID | Source framework | Notes |
|---|---|---|
| `location.gps` | CoreLocation | Lat/lon/altitude/speed/course/accuracy/floor |
| `location.heading` | CoreLocation | True + magnetic heading |

### Environment (4)
| ID | Source framework | Notes |
|---|---|---|
| `environment.proximity` | UIDevice | Near/Far |
| `environment.brightness` | UIScreen | 0–1 |
| `environment.torch` | AVFoundation | Level + on/off |
| `environment.audio` | AVFoundation | Audio session input/output |

### System (6)
| ID | Source framework | Notes |
|---|---|---|
| `system.battery` | UIDevice | Level + state |
| `system.thermal` | ProcessInfo | Nominal/Fair/Serious/Critical |
| `system.lowPower` | ProcessInfo | Low Power Mode flag |
| `system.orientation` | UIDevice | Device orientation |
| `system.disk` | FileManager | Total/Free/Used |
| `system.uptime` | ProcessInfo | Uptime seconds |

### Connectivity (4)
| ID | Source framework | Notes |
|---|---|---|
| `connectivity.bluetoothState` | CoreBluetooth | Power state |
| `connectivity.bluetoothScan` | CoreBluetooth | Discovered peripherals |
| `connectivity.network` | Network | WiFi/cellular type, SSID gate |
| `connectivity.cellular` | CoreTelephony | Carrier, radio tech |

### Camera (1)
| ID | Notes |
|---|---|
| `camera.snapshot` | Front/rear availability, flash, zoom, audio session |

### Health (1, opt-in)
| ID | Notes |
|---|---|
| `health.metric` | Heart rate, steps, energy, body metrics |

`SensorID.minIntervalMs` clamps user-configured intervals so the logger never upsamples beyond the hardware ceiling.

---

## 3. Real-time dashboard

`DashboardView` and the category-specific dashboard files (`MotionDashboardCards`, `LocationDashboardCards`, `EnvironmentDashboardCards`, `SystemDashboardCards`, `ConnectivityDashboardCards`, `CameraDashboardCards`):

- Glass-morphism cards grouped by sensor category.
- Real-time value previews on each card (latest reading).
- Green/red availability dots.
- Tap-through to detail view via `NavigationStack`.
- Global sensor search.
- Five tab-level dashboards (Sensors, System, Environment, Health, plus Logger and Diagnostic).

---

## 4. Sensor detail views

21 dedicated `*DetailView.swift` files in `Views/Sensors/`:

`AccelerometerDetailView`, `ActivityDetailView`, `AltimeterDetailView`, `BarometerDetailView`, `BatteryDetailView`, `BluetoothDetailView`, `CameraDetailView`, `DeviceMotionDetailView`, `DiskDetailView`, `GyroscopeDetailView`, `HeadingDetailView`, `LightDetailView`, `LocationDetailView`, `MagnetometerDetailView`, `MemoryDetailView`, `NetworkDetailView`, `PedometerDetailView`, `ProcessorDetailView`, `ProximityDetailView`, `ThermalDetailView`, `TorchDetailView`.

Per-detail capabilities (varies by sensor):
- 3-axis bars (`ThreeAxisView`), circular gauges (`CircularGauge`), 3D rotation cube, axis visualization, compass dial.
- Real-time chart with play/pause toggle.
- Quick CSV/JSON export from toolbar (in-memory recordings — distinct from persistent logger).
- Recording start/stop through the persistent logger session pipeline via `SensorRecorder` compatibility shim.
- Inline logger card for per-sensor session enable/disable and configuration.

---

## 5. Live data visualization

Built on Swift Charts:
- 3-axis line charts (X=red, Y=green, Z=blue) with Catmull-Rom interpolation.
- Single-value line + area marks for scalar sensors (barometer, battery).
- 200-point rolling buffer.
- Play/Pause toggle (pauses chart, sensor keeps running).
- Time-based X axis with auto-scaling.

Custom components in `Views/Components/SensorComponents.swift`:
- `CircularGauge`
- `ThreeAxisView`
- `CompassDial`
- `RotationCube` (3D)
- `AxisVisualization`

---

## 6. Quick recording (in-memory)

`SensorRecorder` in `Services/SensorManager.swift`:
- Compatibility shim that starts/stops `LoggingService` sessions for the selected sensor.
- Multi-recording list with duration + data-point count.
- Swipe to delete; clear-all.
- Export individual recording as CSV/JSON via `DataExportManager.exportRecording`.
- Auto-stop on thermal/low-power throttle.

`DataExportManager` builds a snapshot of all current sensor values across motion/location/environment/system/connectivity/camera and writes CSV or JSON to the Documents directory for the share sheet.

> Note: This in-memory recorder predates the persistent Logger and continues to coexist with it.

---

## 7. Sensor logging system (persistent)

The full Phase 1–5 logger lives under `Services/Logging/` and `Models/Logging/`.

### Two streams per sensor
Every `SensorID` has independent **continuous** and **session** stream configs:

| Stream | Default behavior | Lifecycle |
|---|---|---|
| Continuous | Always-on background log | Writes whenever the app is running |
| Session | User-bounded recording window | Started/stopped from UI or Siri |

`PerStreamConfig = .off | .on(format, intervalMs, options)`.

### Three on-disk formats (`LogFormat`)
- `sqlite` — GRDB-backed SQLite, session log file `log.sqlite` plus shared `continuous.sqlite`.
- `jsonl` — newline-delimited JSON.
- `csv` — configurable delimiter via `FormatOptions.csvDelimiter`.

Writers in `Services/Logging/Writers/`: `SQLiteLogWriter`, `JSONLogWriter`, `CSVLogWriter`, plus a common `LogWriter` protocol.

### Storage layout (`LogStorageManager`)
```
<Documents>/SensorLogs/
  ├── continuous/
  │     ├── continuous.sqlite
  │     └── <yyyy-MM-dd>/<sensor>.{jsonl|csv}
  └── sessions/
        └── <UUID>/
              ├── log.sqlite
              └── <sensor>[.<rotation>].{jsonl|csv}
```

- Continuous day folders created lazily.
- Session files rotate at 50 MB (`shouldRotateSessionFile`).
- `enforceCapDeletingContinuousIfOver` evicts oldest day folders until under cap.
- `deleteContinuous()` wipes the entire continuous tree (Settings → "Clear all continuous").

### Default per-sensor configuration (`LoggingConfiguration.default`)
Highlights:
- GPS / heading: continuous JSONL @ 60 s, session SQLite @ 1 s.
- Battery / thermal / low power / orientation / pedometer / activity / Bluetooth state / cellular: continuous + session, event-driven (`intervalMs: 0`).
- Accelerometer / gyroscope / magnetometer / deviceMotion: session SQLite @ 100 ms; continuous off.
- Altimeter: session SQLite @ 1 s; continuous off.
- Brightness / disk / uptime: session CSV @ 2 s; continuous off.
- Bluetooth scan / camera / proximity / audio / torch: session JSONL event-driven; continuous off.
- Health: session CSV event-driven; continuous off.

### Configuration UI
`LoggerOverviewView`:
- Status header (`LoggerStatusHeaderView`) showing # continuous-active sensors, session record state, elapsed timer (HH:MM:SS), and a storage progress bar (`used / cap MB`).
- Start/Stop session buttons wired to `loggingService.startSessionFromUI` / `stopSessionFromUI`.
- Per-sensor list grouped by category, each row showing two pills (continuous / session) summarizing format + interval.
- Toolbar buttons: Data Viewer (chart icon), Settings (gear icon).

Global controls:
- Floating Start/Stop session button is available after the permission flow across all app tabs.
- Logger Settings includes the same Start/Stop session control.
- Siri/App Shortcuts expose Start/Stop sensor recording shortcuts.

`SensorLogConfigView`:
- Two `Form` sections (continuous, session) with Toggle, Format picker (sqlite/jsonl/csv), Interval picker.
- Interval presets: every-sample, 10, 50, 100, 250, 500, 1 000, 2 000, 5 000, 10 000, 30 000, 60 000 ms — filtered by `sensorID.minIntervalMs`.
- Live data-rate estimate (`≈ X.X KB/min · Y.Y MB/day`).
- Edits persist via `LoggingConfigStore`.

`LoggerSettingsView`:
- Storage cap stepper (256–10 240 MB, step 256).
- "Clear all continuous" destructive action with confirmation.
- Toggles: disable auto-lock during session, pause continuous on low battery, pause continuous on thermal, show export warning.
- All toggles backed by `@AppStorage("logger.*")`.

### Coordinator & event bus
- `SensorEventBus` collects `SensorSample` from every manager's `samplePublisher` (Combine).
- `LoggingCoordinator` ingests samples, applies per-stream config, batches writes.
- `SensorManager.loggingCoordinator` is wired so thermal/low-power throttle propagates as `setThrottled(true/false)`.
- `LoggingService.bootstrap()` registers an `applicationWillResignActive` observer that calls `flush()` to drain pending writes.

### Privacy-aware export
`LoggingService.exportSessionStrippingLocation(_:)`:
1. Copies `<sessionsRoot>/<UUID>/` → `<sessionsRoot>/<UUID>-stripped/`.
2. Removes any `gps`/`heading`/`location` flat files (jsonl/csv).
3. Runs `DELETE FROM entries WHERE sensor_id LIKE 'location.%'` + `VACUUM` on `log.sqlite`.
4. Returns the sanitized folder URL for sharing.

---

## 8. Data viewer & file browser

`DataViewerView` (sheet) — segmented control with three tabs:

### `SessionsListView`
- Lists every session folder under `sessions/`.
- Per-row: note or short UUID, started/ended timestamps, entry count (`SensorLogEntry.fetchCount`), folder size.
- Active session shows red "active" indicator.
- Swipe-to-delete removes the entire session directory.
- `NavigationLink` to `SessionDetailView`.

### `SessionDetailView`
- Metadata section: ID, started/ended, device model, iOS version, app version, note.
- Per-sensor row table grouped by `sensor_id` with row counts (`GROUP BY sensor_id`).
- Toolbar share button → `UIActivityViewController` over the session folder.

### `SensorDataView`
- Sensor picker (every `SensorID`) and source picker (Continuous / Latest session).
- Swift Charts line chart auto-derived from JSON payloads (x/y/z triples, or scalar keys: `level`, `relative`, `pressure`, `value`, `rssi`, `trueHeading`, `magneticHeading`, `alt`).
- Paginated list (100 entries/page) of `SensorLogEntry` rows with payload kind, wall-time timestamp, monospaced JSON preview.
- Tap row → `LogEntryDetailView` for full payload inspection.

### `FilesBrowserView`
- Recursive enumeration of every file under `SensorLogs/`.
- Per-row: filename (monospaced), size, file/folder icon.
- Swipe actions: Share (UIActivityViewController) and Delete.

---

## 9. Diagnostics

`DiagnosticManager` (`Services/SensorManager.swift`) drives `DiagnosticView`:

- **12 hardware tests:** accelerometer, gyroscope, magnetometer, GPS, compass, barometer, proximity, brightness, battery, bluetooth, network, camera.
- **States:** `notStarted`, `inProgress`, `active`, `unavailable`, `permissionDenied`, `skipped`.
- **Run all** sequentially (300 ms visual delay between tests).
- **Run single** by tapping a row.
- **Per-test duration** captured.
- **Overall score** = active / scorable (excludes `unavailable`), shown as 0–100% circle.
- **Text report** generation with device model, iOS version, date, and per-test status icons; shareable via system share sheet.

---

## 10. App Intents & Siri

Defined across `App/iPhoneSensorsApp.swift` and `Services/Logging/LoggerIntents.swift`:

| Intent | Purpose |
|---|---|
| `GetSensorReadingIntent` | Returns current value as `String` for one of 7 `SensorType`s |
| `StartRecordingIntent` | Starts an in-memory recording for a chosen `SensorType` |
| `ExportSensorDataIntent` | Triggers CSV export confirmation |
| `StartLoggerSessionIntent` | Calls `LoggingService.startSessionFromUI(note: "Siri")` |
| `StopLoggerSessionIntent` | Calls `LoggingService.stopSessionFromUI()` |

`SensorType` `AppEnum`: accelerometer, gyroscope, magnetometer, gps, compass, barometer, battery.

---

## 11. Future widget scaffold

`iPhoneSensors/iPhoneSensorsWidget/` contains a WidgetKit scaffold, but `xcodebuild -list` currently exposes only the app and test targets. It is not a shipping v1 feature until a real extension target, matching App Group entitlements, and app-side `widget_sensor_*` writes are added.

---

## 12. Localization

`Services/LocalizationManager.swift`:
- **12 languages:** English, Thai, Chinese, Japanese, Korean, Spanish, French, German, Portuguese, Arabic, Italian, Russian (`AppLanguage` enum).
- **~360 keys per language** (≈4 372 quoted entries / 12).
- All UI text routed through `locManager.t(key)`; English fallback on missing key.
- Dynamic switch without app restart.
- RTL handled for Arabic.
- New Phase 4/5 keys: `tab.logger`, `logger.title`, `logger.start/stop`, `logger.continuousActive`, `logger.sessionRecording/Idle`, `logger.storage`, `logger.format`, `logger.interval`, `logger.interval.everySample`, `logger.enabled`, `logger.stream.continuous/session`, `logger.format.sqlite/jsonl/csv`, `logger.settings.*`, `logger.inlineCard.*`, `dataviewer.*`, plus `sensor.<sensorID>` keys for every new SensorID.

---

## 13. Theme & UI system

`ThemeManager`:
- `AppTheme` enum: `system`, `light`, `dark`.
- Drives `.preferredColorScheme()` at the app root.
- Persisted via `@AppStorage`.

UI primitives:
- Glass-morphism cards (frosted material, subtle borders).
- Category accent colors (motion=blue, location=green, etc.).
- Cream/light vs. deep-dark backgrounds.
- Shared `ShareSheet` and `ActivityView` `UIViewControllerRepresentable` wrappers for `UIActivityViewController`.

---

## 14. Permissions

`PermissionManager` + `PermissionRequestView` + `PermissionGate`:

### 7-step onboarding
| Step | Permission | Used by |
|---|---|---|
| 0 | Welcome | — |
| 1 | Location | GPS, Compass, Altitude |
| 2 | Motion | Accelerometer, Gyroscope, Pedometer |
| 3 | Camera | Camera info, Torch |
| 4 | Microphone | Audio session |
| 5 | Bluetooth | BLE scan & state |
| 6 | All Set | — |

### `Info.plist` purpose strings (7 entries)
- `NSLocationWhenInUseUsageDescription`
- `NSMotionUsageDescription`
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSBluetoothAlwaysUsageDescription`
- `NSHealthShareUsageDescription`

### Behaviors
- Per-step "Not Now" skip.
- Settings deep-link if denied.
- `PermissionGate` reusable wrapper for any feature that needs auth.
- `LoggerInlineCard` summarizes per-sensor logger state inside detail views and links to per-sensor logger configuration.

---

## 15. Privacy & compliance

- All data local; no analytics SDKs, no servers, no advertising IDs.
- In-app privacy policy + `docs/privacy-policy.md`.
- Privacy manifest at `iPhoneSensors/PrivacyInfo.xcprivacy`.
- Session export can strip location (see §7).
- Compliance docs in `docs/`: `appstore-info.md`, `app-store-metadata.md`, `features.md`, `testflight-beta.md`, `never-reject.md`, `privacy-policy.md`, plus per-feature briefs in `docs/features/` (purpose strings, vibration alarms, inclinometer, environmental delta, real-time charts, recording session, anti-fingerprinting, WiFi SSID gate, App Intents, liquid-glass design, diagnostic 3-state, power efficiency, TestFlight beta, etc.).

---

## 16. Power & thermal management

`SensorManager.updateThrottleState`:
- Watches `ProcessInfo.thermalState` (`.serious`/`.critical`) and `isLowPowerModeEnabled`.
- On throttle: calls `motionManager.setThrottle(true)`, stops in-memory recording, sets `throttleReason`, propagates to `LoggingCoordinator.setThrottled(true)`.
- Logger Settings toggles let the user opt continuous logging in/out of pause-on-low-battery and pause-on-thermal.
- `disableAutoLock` toggle keeps the device awake during sessions.

---

## 17. Tests

`iPhoneSensorsTests/` (XCTest):
- `CSVLogWriterTests`
- `DatabaseSchemaTests`
- `JSONLogWriterTests`
- `LogFormatTests`
- `LoggingConfigStoreTests`
- `LoggingConfigurationTests`
- `LoggingCoordinatorTests`
- `LogStoragePathsTests`
- `LogStorageRotationTests`
- `SensorIDTests`
- `SensorPayloadTests`
- `SessionLifecycleTests`
- `SQLiteLogWriterTests`
- `SmokeTests`

Coverage centers on the logging stack: writer round-trips, schema migrations, rotation, config persistence, end-to-end session lifecycle.

---

## 18. Repository structure

```
iPhoneSensors/iPhoneSensors/
├── App/
│   ├── ContentView.swift           # 6-tab shell, permission gate
│   └── iPhoneSensorsApp.swift      # @main, env objects, AppDelegate, intents
├── Models/
│   └── Logging/                    # 9 model files (SensorID, LogFormat, …)
├── Services/
│   ├── CameraSensorManager.swift
│   ├── ConnectivitySensorManager.swift
│   ├── EnvironmentSensorManager.swift
│   ├── HealthSensorManager.swift
│   ├── LocalizationManager.swift   # 12 languages, ~360 keys
│   ├── LocationSensorManager.swift
│   ├── MotionSensorManager.swift
│   ├── PermissionManager.swift
│   ├── SensorManager.swift         # SensorManager + DataExportManager + SensorRecorder + DiagnosticManager
│   ├── SystemSensorManager.swift
│   └── Logging/
│       ├── DatabaseSchema.swift
│       ├── LoggerIntents.swift
│       ├── LoggingConfigStore.swift
│       ├── LoggingCoordinator.swift
│       ├── LoggingService.swift
│       ├── LogStorageManager.swift
│       ├── SensorEventBus.swift
│       ├── SessionManager.swift
│       └── Writers/
│           ├── CSVLogWriter.swift
│           ├── JSONLogWriter.swift
│           ├── LogWriter.swift
│           └── SQLiteLogWriter.swift
└── Views/
    ├── Components/                 # PermissionGate, PermissionRequestView, SensorComponents, LoggerInlineCard
    ├── Dashboard/                  # 6 category card files + 4 tab views (Dashboard/SystemInfo/Environment/Health)
    ├── Logger/                     # 10 logger views (Overview, Settings, SensorLogConfig, DataViewer, Sessions, SessionDetail, SensorData, Files, LogEntryDetail, StatusHeader)
    └── Sensors/                    # 21 detail views

iPhoneSensorsWidget/                # Future WidgetKit scaffold (not in current target)
iPhoneSensorsTests/                 # 14 test files, logger-focused
docs/                               # Privacy, App Store metadata, feature briefs, logging spec
screenshots/                        # iPhone (6.7"/6.5"/5.5") + iPad (12.9"/11"/9th gen)
```

---

## What this catalog supersedes

`docs/current-allsensors-features.md` (2026-05-06) was correct for Phase 3 and earlier but predates:
- The 6th **Logger** tab and its view stack.
- The dual continuous/session logging model with sqlite/jsonl/csv writers.
- `DataViewerView`, `SessionsListView`, `SessionDetailView`, `SensorDataView`, `FilesBrowserView`, `LogEntryDetailView`, `LoggerSettingsView`, `SensorLogConfigView`, `LoggerStatusHeaderView`, `LoggerInlineCard`.
- `StartLoggerSessionIntent` / `StopLoggerSessionIntent` Siri intents.
- Strip-location export, storage cap enforcement, session-file rotation.
- Logger-aware throttle integration (low-power / thermal pause).
- The 14-file logger test suite under `iPhoneSensorsTests/`.

Items kept because they are still accurate: sensor coverage list, dashboard cards, detail views, in-memory `SensorRecorder`, diagnostic suite, future widget source scaffold, localization (still 12 languages), permission flow, and privacy posture.
