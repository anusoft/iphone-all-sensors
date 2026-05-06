# Sensor Logger & Records — Design Spec

**Status:** Approved
**Date:** 2026-05-06
**Target:** iOS 17+
**Predecessor:** `docs/logging.md` (planning notes; superseded by this spec)

---

## 1. Goals & Use Case

Personal data-collection / research workflow:

- Long sessions, possibly hours.
- App Store distribution intended; background modes scrutinized.
- Export-first formats (JSON Lines, CSV, SQLite) for offline analysis in Python / Excel / DB Browser.
- Per-sensor control: on/off, format, interval, in two parallel streams.

## 2. Streams

Two parallel logging streams:

| Stream | Trigger | Purpose | Default sensors |
|---|---|---|---|
| **Continuous** | Always on while app/session is alive | Low-rate ambient/event monitoring | GPS@1/min, battery, thermal, lowPower, network, orientation, pedometer, motionActivity |
| **Session** | Explicit Start / Stop, with metadata | High-rate experiments | All sensors above + IMU, altimeter, BLE scan, audio session, brightness/disk/uptime, HealthKit snapshots |

Each sensor's `LoggingConfiguration` carries independent `continuous` and `session` settings (`off` or `on(format, intervalMs, options)`).

## 3. Formats

- **JSON Lines (`.jsonl`)** — append-friendly, one JSON object per line.
- **CSV (`.csv`)** — per-sensor schema (different columns per sensor); header on first write; configurable delimiter.
- **SQLite (`.sqlite`)** — single shared DB per stream/session; sensorID is a column. Backed by **GRDB.swift** (SPM dependency, pinned to 7.x).

The on-disk SQLite file *is* the export — opens directly in DB Browser / `sqlite3` CLI / pandas. No special exporter step.

## 4. Storage Layout

```
Documents/SensorLogs/
├── continuous/
│   ├── continuous.sqlite
│   ├── 2026-05-06/
│   │   ├── battery.jsonl
│   │   ├── gps.jsonl
│   │   └── …
│   └── 2026-05-07/…
└── sessions/
    └── <sessionUUID>/
        ├── session.json     (metadata: start, end, device, OS, app version, note, sensor list)
        ├── README.txt       (schema reference, time-zone, privacy notice)
        ├── log.sqlite
        ├── accelerometer.jsonl
        ├── gps.csv
        └── …
```

Rotation:
- Continuous JSONL/CSV: one folder per calendar day.
- Continuous SQLite: single DB, no rotation in v1; manual prune in Phase 5.
- Session JSONL/CSV: rotate at 50 MB → `<sensor>.0.jsonl`, `<sensor>.1.jsonl`, …
- Session SQLite: never rotates within a session; WAL checkpoint per flush.

`Info.plist` sets `UIFileSharingEnabled=YES` and `LSSupportsOpeningDocumentsInPlace=YES` so logs are visible in the iOS Files app.

## 5. Engine Architecture

```
sensor managers (existing)
    │ samplePublisher: PassthroughSubject<SensorSample, Never>   ← new, one per manager
    ▼
SensorEventBus  (actor, fan-in)
    ▼
LoggingCoordinator  (actor, owns per-sensor state, throttle, routing)
    ▼
LogWriter actors:  SQLiteLogWriter | JSONLogWriter | CSVLogWriter
    (per (sensorID × format × stream) tuple; SQLite writers share one DB pool per stream)
    ▼
disk
```

### Properties

- One sample can fan out to **two writers** (continuous + session) if both configured.
- Throttle: `lastWrittenAt[sensorID][stream]` drops samples that arrive faster than `intervalMs`.
- Backpressure ignored — `subject.send` is non-blocking; writers buffer in RAM and flush every 1 s / 100 entries / on backgrounding.
- App lifecycle: `willResignActive` → flush all writers; terminate-handler (added via `UIApplicationDelegateAdaptor`) flushes synchronously up to 200 ms.
- Throttle pause: subscribes to existing `SensorManager.isThrottled`. Thermal/low-power → session writes pause, continuous keeps going. UI banner.

### Concurrency model

Actors throughout the engine. `SensorEventBus`, `LoggingCoordinator`, and each `LogWriter` are independent actors. The Combine `PassthroughSubject` per manager bridges into actor land via `Task { await bus.receive(sample) }` inside the sink — the only Combine→actor boundary.

Test seams:
- `LoggingConfigStore` accepts a `UserDefaults` instance.
- `LogStorageManager` accepts a base directory URL.
- Coordinator accepts an injectable clock for deterministic throttle tests.

## 6. Data Model

### 6.1 In-memory sample

```swift
struct SensorSample: Sendable {
    let sensorID: SensorID
    let wallTime: Date
    let monotonicNs: UInt64
    let payload: SensorPayload
}
```

### 6.2 Payload (typed enum, not `[String: Any]`)

```swift
enum SensorPayload: Codable, Sendable {
    case acceleration(x: Double, y: Double, z: Double)
    case rotationRate(x: Double, y: Double, z: Double)
    case magneticField(x: Double, y: Double, z: Double, accuracy: Int)
    case deviceMotion(DeviceMotionPayload)
    case altitude(relative: Double, pressure: Double)
    case pedometer(PedometerPayload)
    case activity(ActivityPayload)
    case location(LocationPayload)
    case heading(true: Double?, magnetic: Double, accuracy: Double)
    case proximity(near: Bool)
    case brightness(level: Double)
    case torch(level: Float)
    case audio(AudioPayload)
    case battery(level: Double, state: String)
    case thermal(state: String)
    case lowPower(enabled: Bool)
    case orientation(name: String)
    case disk(total: Int64, free: Int64)
    case uptime(seconds: Double)
    case bluetoothState(state: String)
    case bluetoothDevice(name: String?, uuid: String, rssi: Int)
    case network(type: String, connected: Bool)
    case cellular(carrier: String, radio: String)
    case cameraSnapshot(CameraPayload)
    case health(metric: String, value: Double, unit: String, ts: Date)
    case sessionMarker(SessionMarkerPayload)
}
```

The payload is the single source of truth for serialization. CSV writer asks the payload "what columns?" and "what row values?"; JSON/SQLite writers serialize via `Codable`.

### 6.3 SQLite schema (per database file)

```sql
CREATE TABLE sessions (
  id BLOB PRIMARY KEY, started_at REAL NOT NULL, ended_at REAL,
  device_model TEXT, os_version TEXT, app_version TEXT, note TEXT
);

CREATE TABLE entries (
  id BLOB PRIMARY KEY,
  session_id BLOB,            -- NULL for continuous DB
  sensor_id TEXT NOT NULL,
  wall_time REAL NOT NULL,
  monotonic_ns INTEGER NOT NULL,
  payload_kind TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX idx_entries_sensor_time ON entries(sensor_id, wall_time);
CREATE INDEX idx_entries_time ON entries(wall_time);
```

WAL mode. Migrations via GRDB `DatabaseMigrator`.

### 6.4 Configuration

```swift
struct LoggingConfiguration: Codable, Equatable {
    var continuous: PerStreamConfig
    var session:    PerStreamConfig
}
enum PerStreamConfig: Codable, Equatable {
    case off
    case on(format: LogFormat, intervalMs: Int, options: FormatOptions)
}
enum LogFormat: String, Codable, CaseIterable { case sqlite, jsonl, csv }
struct FormatOptions: Codable, Equatable {
    var csvDelimiter: String = ","
    var sqliteBatchSize: Int = 100
}
```

Persisted as JSON in `UserDefaults` under key `loggingConfig.v1`, keyed by `SensorID.RawValue`. Wrapped in `LoggingConfigStore` (`@MainActor ObservableObject`), exposed as `EnvironmentObject` to UI; observed by `LoggingCoordinator` via Combine.

### 6.5 Time alignment

Every sample carries `wallTime` (Date) **and** `monotonicNs` (mach absolute time). For cross-sensor analysis, join on `monotonicNs` to be robust against wall-clock skew (e.g., NTP correction mid-session). Documented in each session's `README.txt`.

## 7. UI

### 7.1 Tab placement

New 6th tab **Logger** in `ContentView.swift` (icon `record.circle`).

### 7.2 Screens

```
LoggerOverviewView (root)
  ├── Status header (continuous active, session timer, storage bar)
  ├── Start/Stop session
  ├── List grouped by SensorCategory (existing)
  │     each row → SensorLogConfigView
  └── Toolbar: gear → LoggerSettingsView; chart icon → DataViewerView

SensorLogConfigView (per sensor)
  ├── Section "Continuous stream": on/off, format, interval, advanced (CSV delimiter, batch size)
  ├── Section "Session stream":    same fields
  └── Footer: estimated rate (≈ KB/min, MB/day)

DataViewerView (segmented)
  ├── By Sensor → SensorDataView (paginated GRDB rows; filters: time, session, source) → LogEntryDetailView
  ├── By Session → SessionsListView → SessionDetailView (export, share, delete)
  └── Files → FilesBrowserView (raw browser of Documents/SensorLogs/)

LoggerSettingsView
  ├── Storage cap (default 1 GB)
  ├── Disable auto-lock during session (default on)
  ├── Pause continuous on low battery / thermal (defaults off / on for sessions)
  ├── Show export warning (default on)
  └── Clear all continuous data
```

Localization: extend `LocalizationManager.swift` with `logger.*` and `dataviewer.*` keys (en + th).

Reuse: existing `SensorCard`, `SensorComponents`, `ShareSheet`.

Phase 5: optional `LoggerInlineCard` embedded in existing per-sensor detail views.

## 8. Background Behavior (App Store)

### 8.1 Background modes (`UIBackgroundModes`)

| Mode | Status | Justification |
|---|---|---|
| `location` | Already enabled | Continuous location logging during a session |
| `bluetooth-central` | Add (conditional honor) | Logs nearby BLE devices when BT-scan logging is enabled |
| `processing` | NOT added | Reviewers question for "logger" framing; not needed |
| `audio` | NOT added | We read audio session metadata only |

### 8.2 Sensor behavior in background

- Wake-driving sensors (GPS, heading) keep the process alive; motion sensors run while the app is woken (samples may be sparse — documented).
- Notification-driven sensors (battery, thermal, network, orientation) keep firing in background.
- Snapshot APIs (brightness, proximity, audio session, camera caps) pause in background.
- HealthKit one-shot at session start/end + on background delivery.

UI marks each sensor with a "background-capable" indicator.

### 8.3 Session lifecycle

1. Start → coordinator creates UUID, opens DB pool + flat files, starts location updates if needed, sets `isIdleTimerDisabled = true` if "Disable auto-lock" is on.
2. Background → `willResignActive` flushes; location keeps process awake; coordinator continues writing as samples arrive.
3. Killed → on next launch, detect unfinished session (no `ended_at`) and prompt user to resume or finalize.
4. Stop → write `ended_at`, flush, close pool, release idle timer.

### 8.4 Throttle integration

Subscribes to `SensorManager.isThrottled`. Thermal/low-power: session writes pause, continuous continues, banner displayed. User-configurable: pause continuous on low battery (default off), pause continuous on thermal (default off — sessions always pause).

## 9. Storage & Retention

- Default cap: 1 GB total under `Documents/SensorLogs/`. Configurable.
- 80% — UI banner warning.
- 95% — auto-delete oldest **continuous** day-folder until <90%; **sessions never auto-deleted**.
- 100% with no continuous to delete — pause session writes, surface modal listing oldest sessions for manual delete.
- Continuous JSONL/CSV rotate by calendar day; session files rotate at 50 MB.
- Per-session `README.txt` written on session end (schema, time-zone, privacy notice).

## 10. Privacy on Export

- One-time consent sheet on first share: "This data may include precise location and HealthKit metrics."
- Privacy header in each session's `README.txt`.
- Phase 5: "Strip location" toggle for export copies.

## 11. Migration & Coexistence

- `SensorRecorder` (in-memory, single-sensor "Record" buttons): unchanged in v1. Phase 5 migration to a thin shim over `LoggingService`.
- `DataExportManager` (one-shot snapshots): unchanged in v1. Phase 5 routed through `LoggingService.exportSnapshot()`.
- New code is purely additive: each existing manager gains `samplePublisher` and one `.send(...)` call per existing callback. No behavior change for current consumers.

## 12. File Plan

### New files

`Models/Logging/`
- `SensorID.swift`, `LogFormat.swift`, `LogStream.swift`, `LoggingConfiguration.swift`, `FormatOptions.swift`, `SensorSample.swift`, `SensorPayload.swift`, `SensorLogEntry.swift` (GRDB Record), `SensorLogSession.swift` (GRDB Record)

`Services/Logging/`
- `LoggingService.swift` (UI facade), `LoggingCoordinator.swift` (actor), `SensorEventBus.swift` (actor), `LoggingConfigStore.swift`, `LogStorageManager.swift`, `SessionManager.swift`, `SensorPayloadEncoder.swift`, `DatabaseSchema.swift`
- `Writers/LogWriter.swift`, `Writers/SQLiteLogWriter.swift`, `Writers/JSONLogWriter.swift`, `Writers/CSVLogWriter.swift`

`Views/Logger/`
- `LoggerOverviewView.swift`, `LoggerStatusHeaderView.swift`, `SensorLogConfigView.swift`, `SessionsListView.swift`, `SessionDetailView.swift`, `DataViewerView.swift`, `SensorDataView.swift`, `LogEntryDetailView.swift`, `FilesBrowserView.swift`, `LoggerSettingsView.swift`

`Views/Components/`
- `LoggerInlineCard.swift` (Phase 5)

### Existing files edited

- `App/iPhoneSensorsApp.swift` — instantiate `LoggingService` + `LoggingConfigStore`; add `UIApplicationDelegateAdaptor` for terminate-flush.
- `App/ContentView.swift` — add 6th Logger tab.
- `Services/SensorManager.swift` — wire throttle events into coordinator.
- `Services/MotionSensorManager.swift` — add publisher; `.send(...)` in 7 callbacks.
- `Services/LocationSensorManager.swift` — 2 sites.
- `Services/EnvironmentSensorManager.swift` — 4 sites.
- `Services/SystemSensorManager.swift` — 4 sites.
- `Services/ConnectivitySensorManager.swift` — 3 sites.
- `Services/CameraSensorManager.swift` — 1 site.
- `Services/HealthSensorManager.swift` — emit per metric in each query completion.
- `Services/LocalizationManager.swift` — add `logger.*` / `dataviewer.*` keys (en + th).
- `Info.plist` — add `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, conditional `bluetooth-central` background mode.
- `iPhoneSensors.xcodeproj/project.pbxproj` — register new files.

### New SPM dependency

- `https://github.com/groue/GRDB.swift` pinned to 7.x. `Package.resolved` committed.

## 13. Testing

New `iPhoneSensorsTests` target.

**Tier 1 — pure unit (no device):**
- `SensorPayloadEncoderTests` — payload → CSV columns/values; Codable round-trip.
- `LoggingConfigurationTests` — Codable round-trip, defaults, UserDefaults persistence, migration of `loggingConfig.v1`.
- `LoggingCoordinatorThrottleTests` — synthetic samples at 100 Hz with `intervalMs=100` → exactly 10/sec; `intervalMs=0` → all written; throttle pause drops correctly.
- `LogStorageManagerTests` — rotation at 50 MB, day-boundary rotation, cap enforcement at 80/95/100 %.
- `DatabaseSchemaTests` — migrator runs cleanly from empty.

**Tier 2 — integration (real GRDB on `:memory:` and tmp files):**
- `SQLiteLogWriterTests`, `JSONLogWriterTests`, `CSVLogWriterTests`
- `SessionLifecycleTests` — start, write, simulate kill, resume.

**Tier 3 — manual smoke checklist** (foreground 60 s, background 5 min walk, thermal trigger, storage cap reached, export round-trip via AirDrop).

## 14. Phases

Each phase is independently shippable.

| Phase | Scope |
|---|---|
| 1 | Foundation: GRDB dep, models, skeletons, accelerometer → JSONLogWriter → continuous stream. No UI. Tier 1 tests for what exists. |
| 2 | All writers (SQLite, CSV), all sensors, both streams, SessionManager start/stop/resume, `LogStorageManager` rotation + cap. Tier 2 tests. |
| 3 | Configuration UI: Logger tab, OverviewView, SensorLogConfigView, LoggerSettingsView, localization keys. |
| 4 | Data Viewer UI: DataViewerView, SensorDataView, LogEntryDetailView, SessionsListView, SessionDetailView, FilesBrowserView, export, privacy warning, README writer. |
| 5 | Polish: charts, `LoggerInlineCard` in detail views, migrate `SensorRecorder` shim, "Strip location" export, AppIntents, Shortcuts donations. |

## 15. Out of Scope

- iCloud sync.
- Cross-device session merging.
- Real-time export to a server.
- Heatmaps / advanced analytics in-app.
- HealthKit write.
- App Group sharing with `iPhoneSensorsWidget`.

## 16. Risks

- GRDB dep is the only meaningful new attack surface; pinned major; `Package.resolved` committed.
- App Store: each background mode tied to a visible feature; sessions explicit; continuous reuses existing `location` mode; no `processing`.
- High-rate IMU sessions (interval ≤ 50 ms) can produce large files — UI warns at config time.
- Background motion sensor coverage is "best effort" — explicitly documented.

## 17. Open Items Resolved During Brainstorming

| # | Resolution |
|---|---|
| Use case | Personal data collection / research; export-first |
| Backgrounding | Required; long sessions; App Store distribution |
| Formats | JSONL + CSV + SQLite (drop "raw") |
| Session model | Hybrid (continuous + explicit sessions) |
| Default sensor allocation | Per Section 2 table |
| UI placement | New 6th tab |
| Storage policy | Hybrid retention: continuous auto-deletes oldest; sessions never auto-deleted |
| Existing recorder | Coexist v1; migrate Phase 5 |
| Storage backend | GRDB + actor pipeline |
