# Feature: Sensor Data Logging & Log Viewer

> **Status:** Planned | **Priority:** High | **Estimated Effort:** 2-3 days
> **Target:** iOS 17+ | **Last Updated:** 2026-05-06

---

## 1. Overview

Add comprehensive sensor data logging with per-sensor controls, configurable intervals, and a built-in log viewer. This transforms the app from a real-time monitor into a true data logger — a key differentiator for researchers, developers, and diagnostic technicians.

### Why This Matters
- **Research/Science:** Users need historical data for experiments
- **Diagnostics:** Technicians need logs to verify intermittent sensor issues
- **Debugging:** Developers need sensor timelines to debug motion/location bugs
- **Compliance:** Some industrial use cases require data logging

---

## 2. Architecture Decisions

### 2.1 Storage Backend: Plain JSON Files (Recommended)

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **JSON Files** | Fast append, human-readable, easy export, no migration | Larger file size than binary | **Best for this app** |
| Core Data | Relationships, queries, efficient | Complex setup, migration headaches, slower append | Overkill |
| SwiftData | Modern, easy setup | iOS 17+ only, slower for high-frequency writes | Good alternative |
| SQLite | Fast, compact | Complex schema, harder to export | Not needed |
| OSLog/unified logging | System-integrated | Not user-accessible, no control | Wrong tool |

**Decision:** Use daily-rotated JSON files in `Documents/Logs/` directory. Each sensor gets its own file per day.

```
Documents/
  Logs/
    2026-05-06/
      accelerometer.jsonl
      gyroscope.jsonl
      gps.jsonl
      barometer.jsonl
      ...
```

**Format:** JSON Lines (`.jsonl`) — one JSON object per line for fast append:
```json
{"ts":"2026-05-06T14:32:01.123Z","x":0.123,"y":-0.456,"z":9.81}
```

### 2.2 Memory Strategy

- **In-memory buffer:** Ring buffer of last 1000 entries (for live viewer)
- **Disk flush:** Every 5 seconds OR when buffer reaches 500 entries
- **File rotation:** New file per day per sensor
- **Retention:** Keep last 30 days (configurable in settings)

### 2.3 Threading

- Logger runs on **background queue** (not MainActor)
- Sensor managers post values to logger via `async` call
- File I/O is serial per sensor to prevent corruption

---

## 3. Implementation Checklist

### Phase 1: Data Model & Storage Layer

#### 3.1 Create Log Entry Model
- [ ] Create `Models/LogEntry.swift` with protocol-based design
- [ ] Define `LogEntry` protocol with `timestamp: Date` and `sensorType: SensorType`
- [ ] Create struct per sensor: `AccelerometerLogEntry`, `GPSLogEntry`, `BarometerLogEntry`, etc.
- [ ] All entries conform to `Codable`

#### 3.2 Create Logger Service
- [ ] Create `Services/SensorLogger.swift` as a Swift `actor` (NOT `@MainActor`)
- [ ] Implement `log(_ entry: LogEntry)` method
- [ ] Implement `startLogging(sensor: SensorType)` / `stopLogging(sensor: SensorType)`
- [ ] Implement `getLogFiles(for sensor: SensorType) -> [URL]`
- [ ] Implement `purgeOldLogs(olderThan days: Int)`

#### 3.3 Create Per-Sensor File Logger
- [ ] Create `Services/SensorFileLogger.swift` as an `actor`
- [ ] In-memory buffer: hold up to 500 entries before flush
- [ ] Auto-flush every 5 seconds via `Timer`
- [ ] File rotation: new file per day OR when > 10MB
- [ ] Write in JSON Lines format (append, don't rewrite)

#### 3.4 File Management
- [ ] Create `Documents/Logs/` directory on first launch
- [ ] Daily file naming: `accelerometer_2026-05-06.jsonl`
- [ ] File size check before write (rotate if > 10MB)
- [ ] Cleanup on app launch: delete files older than retention period
- [ ] Exclude Logs directory from iCloud backup

---

### Phase 2: Settings & Configuration

#### 3.5 Create Log Settings Model
- [ ] Create `Models/LogSettings.swift` with `Codable`
- [ ] `globalEnabled: Bool` — master toggle
- [ ] `retentionDays: Int` — default 30
- [ ] `sensorSettings: [SensorType: SensorLogSettings]` — per-sensor config
- [ ] `SensorLogSettings` contains: `enabled`, `interval`, `lastLoggedTimestamp`

#### 3.6 Define Sensible Default Intervals

| Sensor | Default Interval | Configurable Range | Rationale |
|--------|-----------------|-------------------|-----------|
| Accelerometer | 0.05s (20Hz) | 0.01-1s | Physics experiments need high freq |
| Gyroscope | 0.05s (20Hz) | 0.01-1s | Matches accelerometer |
| Magnetometer | 0.1s (10Hz) | 0.05-2s | Lower natural update rate |
| Device Motion | 0.05s (20Hz) | 0.01-1s | Fused data, same as raw motion |
| GPS/Location | 1.0s (1Hz) | 0.5-60s | GPS hardware updates ~1Hz |
| Barometer | 1.0s (1Hz) | 0.5-10s | Slow environmental changes |
| Proximity | 0.5s (2Hz) | 0.1-5s | Binary state, fast enough |
| Light (Screen) | 2.0s (0.5Hz) | 0.5-10s | User doesn't change brightness fast |
| Battery | 10.0s (0.1Hz) | 1-300s | Slow changing |
| CPU/Memory | 5.0s (0.2Hz) | 1-60s | System stats don't need high freq |
| Thermal | 10.0s (0.1Hz) | 1-300s | Very slow changing |
| Bluetooth | 5.0s (0.2Hz) | 1-30s | Device discovery is slow |
| Network | 5.0s (0.2Hz) | 1-30s | Connection state is stable |
| Camera Info | 10.0s (0.1Hz) | 1-60s | Static info (availability) |
| Pedometer | 1.0s (1Hz) | 1-60s | Step counting needs reasonable freq |
| Altimeter | 1.0s (1Hz) | 0.5-10s | Same as barometer |
| Activity | 5.0s (0.2Hz) | 1-30s | Activity changes are slow |
| Heading/Compass | 0.5s (2Hz) | 0.1-5s | Heading changes with movement |

#### 3.7 Create Logging Settings View
- [ ] Create `Views/Settings/LoggingSettingsView.swift`
- [ ] Master toggle: "Enable Data Logging"
- [ ] Per-sensor toggles grouped by category (Motion, Location, Environment, etc.)
- [ ] Interval picker per sensor (Picker with sensible steps)
- [ ] Retention period picker: 7 / 14 / 30 / 60 / 90 days
- [ ] Storage used indicator (sum all log file sizes)
- [ ] "Purge All Logs" button with confirmation alert

#### 3.8 Integrate Settings with Logger
- [ ] Save settings to `UserDefaults` via `JSONEncoder`
- [ ] Check `enabled` flag before writing each entry
- [ ] Check `interval` — skip if last log was within interval
- [ ] Reload settings when app returns from background

---

### Phase 3: Hook Logger into Sensor Pipeline

#### 3.9 Add Logger Calls to Each Manager
- [ ] `MotionSensorManager` — log acc, gyro, mag, device motion, pedometer, altimeter, activity
- [ ] `LocationSensorManager` — log GPS coords, heading
- [ ] `EnvironmentSensorManager` — log pressure, brightness, proximity
- [ ] `SystemSensorManager` — log battery, thermal, CPU, memory
- [ ] `ConnectivitySensorManager` — log BT state, network type
- [ ] `CameraSensorManager` — log torch level, camera availability

**Pattern for each manager:**
```swift
private let logger = SensorLogger.shared

// In update callback:
Task {
    await logger.log(AccelerometerLogEntry(
        timestamp: Date(),
        x: data.acceleration.x,
        y: data.acceleration.y,
        z: data.acceleration.z,
        magnitude: mag
    ))
}
```

#### 3.10 Add Logger to SensorManager Coordinator
- [ ] Inject logger singleton into `SensorManager`
- [ ] Start logger when sensors start (`startAllSensors()`)
- [ ] Stop logger when sensors stop (`stopAllSensors()`)
- [ ] Pass logger reference to all sub-managers

---

### Phase 4: Log Viewer UI

#### 3.11 Create Log Viewer Main View
- [ ] Create `Views/Logging/LogViewerView.swift`
- [ ] NavigationStack with list of available log files
- [ ] Group by date: Today / Yesterday / Earlier
- [ ] Each row shows: sensor icon, entry count, file size, time range
- [ ] Swipe to delete individual files
- [ ] Search/filter by sensor type

#### 3.12 Create Log Detail View
- [ ] Create `Views/Logging/LogDetailView.swift`
- [ ] Show entries in scrollable list/table
- [ ] Columns: Timestamp, X, Y, Z (or single value)
- [ ] Tap row to expand full JSON
- [ ] Highlight min/max values per axis

#### 3.13 Create Live Log Stream View
- [ ] Create `Views/Logging/LiveLogView.swift`
- [ ] Show last 100 entries updating in real-time
- [ ] Pause/resume button
- [ ] Filter by sensor type
- [ ] Auto-scroll to bottom

#### 3.14 Export from Log Viewer
- [ ] Export single log file via share sheet
- [ ] Export date range (merge multiple files)
- [ ] Export formats: JSON Lines, CSV, JSON
- [ ] Background export with progress for large files

---

### Phase 5: Performance & Edge Cases

#### 3.15 Performance Optimizations
- [ ] Batch writes: buffer 500 entries before disk flush
- [ ] Background queue: all file I/O off main thread
- [ ] Lazy loading: only read file metadata, not full content
- [ ] Pagination: load 100 entries at a time in viewer
- [ ] Compression: gzip old files (optional post-MVP)

#### 3.16 Edge Cases
- [ ] Low disk space (< 500MB): stop logging, show warning, offer cleanup
- [ ] App termination: flush buffer in `applicationWillTerminate`
- [ ] Battery saving: halve logging frequency in Low Power Mode
- [ ] Background: stop logging when app backgrounds (unless location background is on)
- [ ] iCloud backup: exclude Logs directory
- [ ] Simulator: reduce default intervals by 10x to avoid massive files

#### 3.17 Testing Scenarios
- [ ] Log all sensors for 1 hour — verify stable memory
- [ ] Log accelerometer at max rate for 10 minutes — verify no drops
- [ ] Kill app mid-log — verify no file corruption
- [ ] Fill disk to 95% — verify graceful stop
- [ ] Open viewer with 100,000 entries — verify smooth scroll
- [ ] Background/foreground 20 times — verify no duplicate loggers

---

## 4. UI Mockup

### Logging Settings Screen
```
+─────────────────────────────+
|  Logging Settings           |
+─────────────────────────────+
| [✓] Enable Data Logging     |
|                             |
| Storage Used: 12.4 MB       |
| Retention: 30 days     >    |
|                             |
| ── Motion ──                |
| [✓] Accelerometer   20Hz  > |
| [✓] Gyroscope       20Hz  > |
| [ ] Magnetometer    10Hz  > |
| [✓] Device Motion   20Hz  > |
|                             |
| ── Location ──              |
| [✓] GPS              1Hz  > |
| [✓] Compass          2Hz  > |
|                             |
| ── Environment ──           |
| [✓] Barometer        1Hz  > |
| [ ] Proximity        2Hz  > |
|                             |
| [ Purge All Logs ]          |
+─────────────────────────────+
```

### Log Viewer Screen
```
+─────────────────────────────+
|  Log Files                  |
+─────────────────────────────+
| Today                       |
| ▸ Accelerometer  2.1 MB     |
|   14:00-14:32  38,400 pts   |
| ▸ GPS            0.1 MB     |
|   14:00-14:32   1,920 pts   |
|                             |
| Yesterday                   |
| ▸ Accelerometer  4.8 MB     |
|   ...                       |
|                             |
| [Search]  [Filter]          |
+─────────────────────────────+
```

---

## 5. Files to Create/Modify

### New Files
```
iPhoneSensors/
├── Models/
│   ├── LogEntry.swift              # Protocol + entry types
│   └── LogSettings.swift           # Configuration model
├── Services/
│   ├── SensorLogger.swift          # Main logger actor
│   ├── SensorFileLogger.swift      # Per-sensor file writer
│   └── LogFileManager.swift        # Cleanup & rotation
└── Views/
    └── Logging/
        ├── LoggingSettingsView.swift
        ├── LogViewerView.swift
        ├── LogDetailView.swift
        └── LiveLogView.swift
```

### Modified Files
```
iPhoneSensors/
├── Services/
│   ├── SensorManager.swift
│   ├── MotionSensorManager.swift
│   ├── LocationSensorManager.swift
│   ├── EnvironmentSensorManager.swift
│   ├── SystemSensorManager.swift
│   ├── ConnectivitySensorManager.swift
│   └── CameraSensorManager.swift
├── Views/
│   ├── Components/
│   │   └── SettingsSheet.swift
│   └── Dashboard/
│       └── DashboardView.swift
└── App/
    └── iPhoneSensorsApp.swift
```

---

## 6. Privacy & Compliance

### Data Handling
- [ ] All logs stay in app sandbox (`Documents/Logs/`)
- [ ] No automatic cloud sync
- [ ] Logs excluded from iCloud backup via `isExcludedFromBackupKey`
- [ ] Auto-purged on app deletion (sandbox behavior)

### App Store Review Notes
Add to review notes:
```
LOGGING FEATURE:
This app logs sensor data locally to JSON files in the app sandbox.
- No data is sent to external servers
- Logs are stored in Documents/Logs/ and excluded from iCloud backup
- Users can configure per-sensor logging intervals and retention
- Users can view, export, and delete logs from within the app
- Logging pauses when app is not in foreground
```

---

## 7. Future Enhancements (Post-MVP)

- [ ] Historical graph viewer: plot logged data over time
- [ ] Annotations: add text notes at specific timestamps
- [ ] Threshold triggers: auto-start logging when sensor exceeds value
- [ ] Cloud export: iCloud Drive, Dropbox, Google Drive
- [ ] CSV export format in addition to JSON Lines
- [ ] Session tags: group logs by activity name
- [ ] Compare mode: overlay two log sessions
- [ ] Apple Watch companion: log watch sensors

---

## 8. Estimated Timeline

| Phase | Duration | Risk |
|-------|----------|------|
| Phase 1: Storage Layer | 4-6 hours | Low |
| Phase 2: Settings UI | 3-4 hours | Low |
| Phase 3: Sensor Hooks | 2-3 hours | Medium |
| Phase 4: Log Viewer | 4-6 hours | Medium |
| Phase 5: Polish & Edge Cases | 2-3 hours | Low |
| **Total** | **15-22 hours** | |

---

*Document Version: 1.0*
*Last Updated: 2026-05-06*
