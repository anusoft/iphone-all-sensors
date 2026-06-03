# All Sensors — UI/UX Screen Extraction Document

> App: iPhone hardware sensor viewer displaying 21+ real-time sensor data streams  
> Platform: iOS 17.0+ | Framework: SwiftUI | Architecture: MVVM  
> 4 Tabs • 21 Detail Views • 6-Step Permission Flow • Multi-language (EN/TH/ZH)

---

## SCREEN 1: Permission Onboarding Flow

### 1.1 Welcome Screen (Step 0/5)
- **Primary Objective:** Onboard the user and prepare them for guided permission grants.
- **Layout Strategy:** Full-screen centered layout. Large icon at top, text stack in middle, CTA button + skip at bottom. Page dot indicators.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | App icon | SF Symbol `sensor.tag.radiowaves.forward`, size 80pt | Tinted blue |
  | Title | `Text` H1, bold | "Welcome" / localized |
  | Subtitle | `Text` subheadline, secondary | "All Sensors" |
  | Description | `Text` body, secondary, multiline | Explains value of granting permissions |
  | CTA Button | Primary button, full width, blue bg, white label, 14pt radius | "Get Started" → advances to step 1 |
  | Page Dots | 6 circles (8×8pt) in a row | Active dot filled; inactive dots 30% gray |
- **Data Mapping:** All strings from `LocalizationManager` translation dictionary via `locManager.t("key")`.
- **UI States:**
  | State | Behavior |
  |---|---|
  | Default | All content visible, button enabled |
  | Processing | CTA button shows spinner + disabled (not applicable to welcome) |
- **User Interactions:**
  | Gesture | Action |
  |---|---|
  | Tap CTA | `nextStep()` — advances to step 1 with `.easeInOut` animation |
  | Tap "Not Now" | Not shown on welcome step |

### 1.2 Location Permission (Step 1/5)
- **Primary Objective:** Request When-In-Use location authorization for GPS, compass, and altitude.
- **Layout Strategy:** Same full-screen centered layout as step 0. Icon, text, CTA, "Not Now" skip, page dots.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Icon | SF Symbol `location.fill`, size 80pt | Tinted green |
  | Title | `Text` H1, bold | "Location Access" / localized |
  | Subtitle | `Text` subheadline | "GPS • Compass • Altitude" |
  | Description | `Text` body, secondary | Explains why location is needed |
  | CTA Button | Full width, green bg | "Allow Location Access" → triggers `CLLocationManager.requestWhenInUseAuthorization()` |
  | Skip Button | Text link, subheadline, secondary | "Not Now" → advances to step 2 |
  | Page Dots | 6 circles | Active dot index 1 (green) |
- **Data Mapping:** All strings localized.
- **UI States:**
  | State | Behavior |
  |---|---|
  | Default | Icon, text, buttons visible |
  | Processing (`isProcessing = true`) | CTA shows `ProgressView` spinner + disabled. Skip still tappable |
  | Done | Auto-advances after 1.0s delay via `DispatchQueue.main.asyncAfter` |
- **User Interactions:**
  | Gesture | Action |
  |---|---|
  | Tap CTA | Fires native iOS location permission prompt, sets `isProcessing = true` |
  | Tap "Not Now" | Calls `skipStep()` → advances |

### 1.3 Motion & Fitness Permission (Step 2/5)
- **Primary Objective:** Request motion sensors access (accelerometer, gyroscope, pedometer).
- **Layout Strategy:** Same as steps 0–1.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Icon | SF Symbol `figure.walk`, size 80pt | Tinted blue |
  | Title | `Text` H1 | "Motion & Fitness" |
  | Subtitle | `Text` subheadline | "Accelerometer • Gyroscope • Steps" |
  | Description | `Text` body | Explains motion data usage |
  | CTA Button | Full width, blue bg | "Allow Motion" → triggers CoreMotion |
  | Skip Button | Text link | "Not Now" |
  | Page Dots | 6 circles | Active index 2 |
- **UI States:** Default / Processing (spinner, 0.5s delay) / Done → auto-advance.
- **User Interactions:** Tap CTA → `isProcessing = true` → 0.5s timer → `nextStep()`.

### 1.4 Camera Permission (Step 3/5)
- **Primary Objective:** Request camera access for camera info and torch control.
- **Layout Strategy:** Same as steps 0–2.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Icon | SF Symbol `camera.fill`, size 80pt | Tinted yellow |
  | Title | `Text` H1 | "Camera Access" |
  | Subtitle | `Text` subheadline | "Camera Info • Torch" |
  | Description | `Text` body | Explains camera usage |
  | CTA Button | Full width, yellow bg | "Allow Camera" → native `AVCaptureDevice.requestAccess(for: .video)` |
  | Skip Button | Text link | "Not Now" |
  | Page Dots | 6 circles | Active index 3 |
- **UI States:** Default / Processing / Done.
- **User Interactions:** Tap CTA → native camera permission dialog → completion handler → `nextStep()`.

### 1.5 Microphone Permission (Step 4/5)
- **Primary Objective:** Request microphone access for audio input device info.
- **Layout Strategy:** Same as steps 0–4.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Icon | SF Symbol `mic.fill`, size 80pt | Tinted orange |
  | Title | `Text` H1 | "Microphone Access" |
  | Subtitle | `Text` subheadline | "Audio Input" |
  | Description | `Text` body | Explains microphone usage |
  | CTA Button | Full width, orange bg | "Allow Microphone" → native `AVCaptureDevice.requestAccess(for: .audio)` |
  | Skip Button | Text link | "Not Now" |
  | Page Dots | 6 circles | Active index 4 |
- **UI States:** Default / Processing / Done.
- **User Interactions:** Tap CTA → native mic permission → completion handler → `nextStep()`.

### 1.6 "You're All Set!" — Completion (Step 5/5)
- **Primary Objective:** Confirm setup complete and transition to main app.
- **Layout Strategy:** Same centered layout. Success-themed icon and color.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Icon | SF Symbol `checkmark.circle.fill`, size 80pt | Tinted green |
  | Title | `Text` H1 | "You're All Set!" |
  | Subtitle | Empty string (hidden) | — |
  | Description | `Text` body | Confirms all optional permissions |
  | CTA Button | Full width, green bg | "Start Using App" → sets `showPermissionFlow = false`, writes `hasCompletedPermissionFlow = true` |
  | Skip Button | Not shown | `currentStep == steps.count - 1` |
  | Page Dots | 6 circles | Active index 5 |
- **UI States:** Default only (no processing state).
- **User Interactions:** Tap CTA → dismisses overlay → calls `onComplete()` → `sensorManager.startAllSensors()`.

---

## SCREEN 2: Dashboard (Sensors Tab)

### 2.1 Main Dashboard
- **Primary Objective:** Provide a browsable, searchable overview of all 21+ sensors grouped by category.
- **Layout Strategy:** `NavigationStack` wrapping a `ScrollView` with `LazyVStack`. Sticky top navigation bar with title + language picker. Search bar integrated via `.searchable` modifier. Body is 6 category sections, each containing sensor cards.
- **UI Components:**
  | Component | Type | Data Source | Notes |
  |---|---|---|---|
  | Navigation Title | Inline nav title | `locManager.t("dashboard.title")` → "Sensors" | |
  | Search Bar | `.searchable` modifier | `@State searchText` | Placeholder: "Search sensors..." / localized |
  | Language Button | Toolbar trailing button | `locManager.currentLanguage.flag` (emoji) | Opens `confirmationDialog` with 3 language options (English/Thai/Chinese) each showing flag + displayName + checkmark if active |
  | Section Header | `SensorSection` subview | Icon + title + color per category | `HStack` with SF Symbol + `Text(.headline)`, wrapped in `VStack` with `.ultraThinMaterial` card (16pt radius) |
  | Sensor Cards | `SensorCard` reusable component | See 2.1.1 | Up to 7 cards per section |
- **Category Sections & Sensor Cards:**
  | Section | Color | Card 1 | Card 2 | Card 3 | Card 4 | Card 5 | Card 6 | Card 7 |
  |---|---|---|---|---|---|---|---|---|
  | Motion (`gyroscope`) | Blue | Accelerometer | Gyroscope | Magnetometer | Device Motion | Pedometer | Altimeter | Activity |
  | Location (`location.fill`) | Green | GPS | Compass | — | — | — | — | — |
  | Environment (`thermometer.medium`) | Orange | Barometer | Proximity | Brightness | — | — | — | — |
  | System (`cpu`) | Purple | Battery | Processor | Memory | Storage | Thermal | — | — |
  | Connectivity (`wifi`) | Cyan | Bluetooth | Network | — | — | — | — | — |
  | Camera (`camera.fill`) | Yellow | Camera | Torch | — | — | — | — | — |
- **SensorCard Data Mapping:**
  | Field | Type | Source Example |
  |---|---|---|
  | `title` | `String` | Localized sensor name |
  | `icon` | `String` (SF Symbol) | `"gyroscope"`, `"location.fill"` |
  | `value` | `String` | Real-time numeric value (empty string on dashboard) |
  | `unit` | `String` | "G", "kPa", "m" (empty on dashboard) |
  | `color` | `Color` | Category color |
  | `isAvailable` | `Bool` | Sensor availability flag from manager |
  | `isLoading` | `Bool` | `false` on dashboard |
- **UI States:**
  | State | Visual |
  |---|---|
  | **Full List (Default)** | All 6 sections visible with all cards |
  | **Empty Search** | Centered magnifying glass icon + "No sensors found" headline in `.secondary` |
  | **Filtered Search** | Replaces sections with flat list of matching `SensorCard` components (no section headers) |
  | **Sensor Unavailable** | Card shows "N/A" badge instead of chevron. Row is not tappable |
  | **Waiting for Data** | Card subtitle shows "Waiting for data..." in tertiary italic when `value.isEmpty \|\| value == "0" \|\| value == "0.00"` |
  | **Loading** | Card shows `ProgressView` spinner (scale 0.7) + "Loading..." text in secondary |
  | **Active Data** | Card shows live numeric value + unit |
- **User Interactions:**
  | Gesture | Action |
  |---|---|
  | Tap SensorCard (available) | `NavigationLink` pushes to corresponding Detail View |
  | Tap SensorCard (N/A) | No navigation (row is not wrapped in `NavigationLink`) |
  | Type in Search | Filters all 21 sensors by name, case-insensitive. Clears section groupings |
  | Tap Language Button | Opens language selection `confirmationDialog` |
  | Select Language | Sets `locManager.currentLanguage`, UI re-renders immediately |

---

## SCREEN 3: System Info Tab

### 3.1 System Info Overview
- **Primary Objective:** Display static and dynamic device/hardware information with drill-down access to system sensors.
- **Layout Strategy:** `NavigationStack` wrapping `ScrollView`. Device hero card at top, then device info section, then 5 navigation link rows.
- **UI Components:**
  | Component | Type | Data |
  |---|---|---|
  | Device Hero Card | Card (`.ultraThinMaterial`, 16pt radius) | `iphone.gen3` icon (50pt, blue), `sys.deviceName` (title2 bold), `sys.systemName sys.systemVersion` (headline secondary) |
  | Device Info Section | Card with heading "Device Info" | 5 `DataRow`s: Device Name, Model, System, Identifier, Screen Size, Screen Scale, Brightness, Orientation, Multitasking |
  | Battery Link | NavigationLink row | Icon `battery.100` (green) → "Battery Details" → shows `X%` |
  | Processor Link | NavigationLink row | Icon `cpu` (purple) → "Processor Details" → shows `X cores` |
  | Memory Link | NavigationLink row | Icon `memorychip` (indigo) → "Memory Details" → shows formatted byte count |
  | Storage Link | NavigationLink row | Icon `internaldrive` (teal) → "Storage Details" → shows `X free` |
  | Thermal Link | NavigationLink row | Icon `thermometer.medium` (orange) → "Thermal State" → shows `sys.thermalStateText` |
- **DataRow Data Mapping (Device Info Section):**
  | Label | Value | Icon |
  |---|---|---|
  | Device Name | `sys.deviceName` | `iphone` |
  | Model | `sys.deviceModel` | `cube` |
  | System | `"\(sys.systemName) \(sys.systemVersion)"` | `gear` |
  | Identifier | `sys.deviceIdentifierForVendor` | `number` |
  | Screen Size | `"\(Int(w))×\(Int(h))"` | `rectangle` |
  | Screen Scale | `String(format: "%.0fx", screenScale)` | `arrow.up.left.and.arrow.down.right` |
  | Brightness | `String(format: "%.0f%%", brightness * 100)` | `sun.max.fill` |
  | Orientation | `sys.orientationText` | `rotate.right` |
  | Multitasking | `"Supported" / "Not Supported"` | `square.split.2x2` |
- **UI States:**
  | State | Behavior |
  |---|---|
  | Default | All cards and rows rendered with current data |
  | Data Update | `sys` properties update via `@Published` → SwiftUI re-renders affected rows |
- **User Interactions:**
  | Gesture | Action |
  |---|---|
  | Tap any NavigationLink row | Pushes to corresponding Detail View |
  | Tab Switch | `onAppear` calls `sensorManager.systemManager.startUpdates()` |

---

## SCREEN 4: Environment Tab

### 4.1 Environment Overview
- **Primary Objective:** Display key environmental sensor values with drill-down to detailed views.
- **Layout Strategy:** `NavigationStack` wrapping `ScrollView`. Two `CircularGauge`s side-by-side at top, then 3 navigation link rows, then audio info section.
- **UI Components:**
  | Component | Type | Data |
  |---|---|---|
  | Pressure Gauge | `CircularGauge` (size 120, orange) | `env.pressure`, maxValue=120, unit="kPa" |
  | Altitude Gauge | `CircularGauge` (size 120, cyan) | `env.relativeAltitude`, maxValue=100, unit="m" |
  | Barometer Link | NavigationLink row | Icon `barometer` (orange) → "Barometer" → shows `X kPa` |
  | Proximity Link | NavigationLink row | Icon `sensor.tag.radiowaves.forward` (red) → "Proximity Sensor" → shows "Near"/"Far" |
  | Brightness Link | NavigationLink row | Icon `sun.max.fill` (yellow) → "Screen Brightness" → shows `X%` |
  | Audio Card | Card with heading "Audio" | Output Volume, Category, Other Audio Playing, Output Devices list |
- **Audio DataRow Mapping:**
  | Label | Value | Source |
  |---|---|---|
  | Output Volume | `"X%"` | `env.audioVolume * 100` |
  | Category | String | `env.audioSessionCategory` |
  | Other Audio Playing | "Yes"/"No" | `env.isAudioSessionActive` |
  | Output (per device) | Device name string | `env.audioOutputDevices` array |
- **UI States:**
  | State | Behavior |
  |---|---|
  | Default | Gauges animate with `.easeOut` 0.5s trim animation on value change |
  | Proximity Near | `env.proximityState == true` → row shows "Near" |
  | Proximity Far | `env.proximityState == false` → row shows "Far" |
- **User Interactions:**
  | Gesture | Action |
  |---|---|
  | Tap Barometer/Proximity/Brightness rows | Pushes to corresponding Detail View |
  | Tab Switch | `onAppear` calls `sensorManager.environmentManager.startUpdates()` |

---

## SCREEN 5: Health Tab

### 5.1 Health — Disabled State (Default)
- **Primary Objective:** Inform user that HealthKit is disabled and preview available data.
- **Layout Strategy:** `NavigationStack` with `ScrollView`. Centered disabled-state content with preview card.
- **UI Components:**
  | Component | Type | Notes |
  |---|---|---|
  | Disabled Icon | SF Symbol `heart.slash`, 60pt, red | |
  | Title | `Text` title2, bold | "Health Sensors Disabled" |
  | Explanation | `Text` subheadline, secondary, multiline, centered | Explains Developer account requirement |
  | Preview Card | Card with heading "Available when enabled:" | Lists 8 `DataRow`s showing metric name + unit: Heart Rate (bpm), HRV (ms), SpO2 (%), Steps (count), Distance (m), Blood Pressure (mmHg), Body Temp (°C), Respiratory Rate (br/min) |
- **Data Mapping:** Static strings (no live data).
- **UI States:** Single static state.
- **User Interactions:** None (informational only).

### 5.2 Health — Enabled State (HealthKit activated)
- **Primary Objective:** Display all HealthKit metrics in organized sections.
- **Layout Strategy:** `ScrollView` with 4 categorized card sections.
- **UI Components & Data Mapping:**
  | Section | `DataRow`s |
  |---|---|
  | **Vitals** (headline, icon `heart.fill`) | Heart Rate: `"%.0f bpm"`, HRV: `"%.0f ms"`, SpO2: `"%.0f%%"`, Respiratory Rate: `"%.0f br/min"`, Body Temp: `"%.1f°C"`, Blood Pressure: `"%.0f/%.0f mmHg"` |
  | **Activity Today** (headline) | Steps: `"%.0f"`, Distance: `"%.1f m"`, Flights Climbed: `"%.0f"`, Active Energy: `"%.0f kcal"`, Exercise Time: `"%.0f min"`, Stand Time: `"%.0f min"` |
  | **Body Measurements** (headline) | Height: `"%.2f m"`, Weight: `"%.1f kg"`, BMI: `"%.1f"`, Body Fat: `"%.1f%%"`, Lean Mass: `"%.1f kg"` |
  | **Profile** (headline) | Biological Sex (string), Blood Type (string), Date of Birth (formatted `.abbreviated`) |
- **UI States:** Default (live data). Empty values show "0" or system default string.
- **User Interactions:** None (read-only display). Tab switch triggers no explicit start (disabled by default).

---

## SCREEN 6–26: Sensor Detail Views (21 screens)

All 21 detail views share a common structural template. Each is described below with its unique components.

### Common Detail View Template
- **Navigation:** `NavigationStack` with inline title and back chevron.
- **Layout Strategy:** `ScrollView` → `VStack(spacing: 20)` → `.padding()`.
- **Background:** `Color(.systemGroupedBackground)`.
- **Card Style:** Each logical block is wrapped in `VStack`/`HStack` → `.padding()` → `.background(.ultraThinMaterial)` → `.clipShape(RoundedRectangle(cornerRadius: 16))`.
- **Data Update Rate:** Motion sensors update at **10 Hz** (100ms). System sensors update every **2 seconds**. All via `@Published` → automatic SwiftUI re-render.

### 6. Accelerometer Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| X/Y/Z Axes | `ThreeAxisView` (colored: red/green/blue, unit: "G") | `motion.accX/Y/Z` |
| Magnitude | `CircularGauge` (maxValue=4, size=140, blue) | `sqrt(accX² + accY² + accZ²)` |
| Detailed Axes | 5× `DataRow` (X, Y, Z, Magnitude, Status) | Formatted to 4 decimal places |
| Axis Bars | `AxisVisualization` with 3 vertical `AxisBar`s (height 200pt) | Normalized ±2.0G range |
- **States:** Default (streaming). Unavailable → Status row shows "Unavailable".
- **Interaction:** Scroll only (read-only).

### 7. Gyroscope Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| X/Y/Z Axes | `ThreeAxisView` (unit: "rad/s") | `motion.gyroX/Y/Z` |
| Magnitude | `CircularGauge` (maxValue=10, size=140, indigo) | `sqrt(gyroX² + gyroY² + gyroZ²)` |
| Conversion | `DataRow` showing rad/s + degrees/s | `gyro * 57.2958` |
| 3D Visualization | `RotationCube` with `rotation3DEffect` driven by gyro angles | Animated in real-time |

### 8. Magnetometer Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| X/Y/Z Axes | `ThreeAxisView` (unit: "µT", purple) | `motion.magX/Y/Z` |
| Total Field | `CircularGauge` (maxValue=100, size=140, purple) | `sqrt(magX² + magY² + magZ²)` |
| Raw Field | 3× `DataRow` | Raw X/Y/Z |
| Calibrated Field | 3× `DataRow` | `motion.calMagX/Y/Z` |
| Compass | `CompassView` (170×170pt) with rotating dial, N/E/S/W labels, heading pointer, numeric heading display | `loc.trueHeading` |

### 9. Device Motion Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Attitude Angles | 3× `CircularGauge` (roll/pitch/yaw, orange/pink/sky blue) | `motion.roll/pitch/yaw` (radians → degrees) |
| 3D Phone | Phone icon with `rotation3DEffect` by attitude | Animated |
| Gravity Vector | `DataRow` × 3 | `motion.gravityX/Y/Z` |
| User Acceleration | `DataRow` × 3 | `motion.userAccelX/Y/Z` |
| Rotation Rate | `DataRow` × 3 | `motion.rotRateX/Y/Z` |
| Quaternion | `DataRow` × 4 (x, y, z, w) | `motion.quatX/Y/Z/W` |
| Rotation Matrix | 9× `DataRow` (m11–m33) | 3×3 matrix values |

### 10. Pedometer Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Steps | `CircularGauge` (green) | `motion.stepCount` |
| Distance | `CircularGauge` (blue) | `motion.distance` (meters) |
| Floors Ascended | `StatBox` (green icon) | `motion.floorsAscended` |
| Floors Descended | `StatBox` (orange icon) | `motion.floorsDescended` |
| Pace | `DataRow` (seconds/meter) | `motion.currentPace` |
| Cadence | `DataRow` (steps/second) | `motion.currentCadence` |
- **States:** Unavailable → all values show "0" or "N/A".

### 11. Altimeter Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Relative Altitude | `CircularGauge` (cyan, maxValue=100) | `motion.relativeAltitude` (meters) |
| Pressure | `CircularGauge` (orange, maxValue=120) | `motion.pressure` (kPa) |
| Data Table | `DataRow`s with unit conversions | Altitude in m/ft, Pressure in kPa/hPa/inHg/mbar |

### 12. Activity Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Current Activity | `Text` (large, bold) | `motion.currentActivity` string (Walking/Running/Cycling/Automotive/Stationary/Unknown) |
| Activity Grid | 5× `ActivityTile` in 2-row grid | Each tile has SF Symbol + label, active tile highlighted with filled color + bold |

### 13. GPS Location Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Coordinates | Large coordinate display (lat/lon) | `loc.latitude`, `loc.longitude` |
| Position | `DataRow`s: Lat, Lon, Alt (m), Speed (m/s), Course (°) | Values formatted to 6 decimal places |
| Accuracy | `DataRow`s: Horizontal (m), Vertical (m), Speed (m/s), Course (°) | Accuracy values |
| Authorization | `DataRow` + `StatusBadge` | `loc.authorizationStatus` |
- **States:** Unauthorized → shows "Not Authorized" status badge. No sensor data.

### 14. Heading / Compass Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Compass | `CompassView` (170×170pt) | `loc.trueHeading` |
| Headings | `DataRow`s: True Heading, Magnetic Heading | True + magnetic in degrees |
| Accuracy | `DataRow` | Heading accuracy |
| Cardinal | `DataRow` | Cardinal direction string (N/NE/E/SE/S/SW/W/NW) |

### 15. Barometer Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Pressure | `CircularGauge` (orange, maxValue=120) | `env.pressure` (kPa) |
| Altitude | `CircularGauge` (cyan, maxValue=100) | `env.relativeAltitude` (m) |
| Conversions | `DataRow`s | Pressure: kPa, hPa, inHg, mbar. Altitude: m, ft |

### 16. Proximity Sensor Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| State Icon | SF Symbol, color changes with state (red=near, green=far) | `env.proximityState` |
| Status Badge | `StatusBadge` ("NEAR" red / "FAR" green) | `env.proximityState` |
| Monitoring | `DataRow` | `env.isProximityMonitoringEnabled` |

### 17. Screen Brightness Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Brightness Icon | SF Symbol `sun.max.fill`, yellow | |
| Brightness Value | Large percentage text | `env.screenBrightness * 100` |
| Slider | Interactive `Slider` (0–1) | Controls `UIScreen.main.brightness` |
- **Interaction:** Drag slider → adjusts actual device screen brightness in real-time.

### 18. Battery Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Battery Icon | SF Symbol by level + charging state | Filled proportionally |
| Level | Large percentage display | `sys.batteryLevel * 100` |
| State Badge | `StatusBadge` ("Charging" green / "Full" green / "Unplugged" yellow / "Unknown" gray) | `sys.batteryStateText` |
| Monitoring | `DataRow` | `sys.isBatteryMonitoringEnabled` |
| Low Power | `DataRow` | `sys.isLowPowerModeEnabled ? "Yes" : "No"` |

### 19. Processor Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Active Cores | `CircularGauge` (purple, maxValue=total count) | `sys.activeProcessorCount` |
| Total Cores | `CircularGauge` (indigo) | `sys.processorCount` |
| Uptime | `DataRow` | `sys.systemUptime` formatted as time interval |
| Low Power | `DataRow` | `sys.isLowPowerModeEnabled` |

### 20. Memory Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Memory Icon | SF Symbol `memorychip`, indigo | |
| Physical Memory | Large text | `sys.physicalMemory` formatted via `ByteCountFormatter` |
| Additional Info | `DataRow`s | Any additional memory metrics from `sys` |

### 21. Storage / Disk Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Free Space | Large text | `sys.freeDiskSpace` formatted |
| Usage Bar | Gradient progress bar (blue → purple) | Free / Total ratio |
| Total / Free / Used | 3× `DataRow` | ByteCountFormatter |

### 22. Thermal State Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Thermometer Icon | SF Symbol, color-coded by state | Green (Normal) / Yellow (Fair) / Orange (Serious) / Red (Critical) |
| State Badge | `StatusBadge` | `sys.thermalStateText` |
| Info | `DataRow`s | Additional thermal info |

### 23. Bluetooth Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Antenna Icon | SF Symbol, blue when powered on, gray otherwise | `conn.bluetoothState` |
| State Text | `Text` title bold | `conn.bluetoothStateText` |
| Status Badge | `StatusBadge` | Green (poweredOn) / Red (other) |
| Info | `DataRow`s: State, Scanning, Discovered Devices count | |
| Scan Button | Primary button, full width | Toggles `startScanning()` / `stopScanning()`. Red when scanning, blue when idle |
| Device List | `ForEach` list of discovered peripherals | Name + UUID string per device |
- **States:**
  | State | Behavior |
  |---|---|
  | Bluetooth Off | Scan button hidden. Devices count = 0 |
  | Scanning | Button shows "Stop Scanning", red bg |
  | Idle | Button shows "Start Scanning", blue bg |
  | Devices Found | List section appears with `ForEach` peripheral list |
  | No Devices | "Discovered Devices" section hidden |
- **User Interactions:**
  - Tap Scan Button → starts/stops BLE scanning
  - Scroll device list

### 24. Network Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Network Icon | SF Symbol `network`, cyan | |
| Connection Type | `Text` title + `StatusBadge` | "Connected" green / "Disconnected" red |
| WiFi | `DataRow`: SSID, BSSID, Signal | `conn.wifiSSID/BSSID/signal` |
| Cellular | `DataRow`: Carrier, Radio Tech | `conn.cellularCarrierName/radioAccessTechnology` |
| Monitor | `DataRow` | `conn.isNetworkConnected` |
- **States:** Connected / Disconnected → status badge + connection type text changes.

### 25. Camera Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Camera Icon | SF Symbol `camera.fill`, yellow | |
| Availability | `DataRow`s: Rear Camera, Front Camera, Flash, Torch, Max Zoom | Boolean flags from `cam` |
| Access | `DataRow`s: Camera Access, Microphone Access | Authorization status |
| Audio Session | `DataRow`s: Category, Sample Rate, Input Channels | `AVAudioSession` properties |

### 26. Torch / Flashlight Detail View
| Metric | Visualization | Data Source |
|---|---|---|
| Torch Icon | SF Symbol, filled when on, outlined when off | `cam.isTorchActive` |
| Status | `StatusBadge` ("ON" yellow / "OFF" gray) | |
| Torch Level | Interactive `Slider` (0.0–1.0) | Controls `AVCaptureDevice.torchMode` |
| Availability | `DataRow` | `cam.isTorchAvailable` |
- **Interaction:** Drag slider → sets `setTorchModeOn(level:)` on `AVCaptureDevice`.

---

## REUSABLE COMPONENTS (System-Wide)

### SensorCard
| Property | Type | Description |
|---|---|---|
| `title` | `String` | Sensor name |
| `icon` | `String` | SF Symbol name |
| `value` | `String` | Current reading |
| `unit` | `String` | Measurement unit |
| `color` | `Color` | Tint color |
| `isAvailable` | `Bool` | Sensor hardware flag |
| `isLoading` | `Bool` | Shows ProgressView spinner |
- **States:**
  | State | Right Accessory |
  |---|---|
  | Available, no data | Chevron right |
  | Available, has data | Value + unit + chevron |
  | Unavailable | "N/A" tertiary text (no chevron) |
  | Loading | `ProgressView` + "Loading..." |
  | Waiting | "Waiting for data..." italic tertiary |

### CircularGauge
| Property | Type | Description |
|---|---|---|
| `value` | `Double` | Current value |
| `maxValue` | `Double` | Scale maximum |
| `title` | `String` | Gauge label below |
| `unit` | `String` | Unit label inside |
| `color` | `Color` | Trim + text color |
| `size` | `CGFloat` | Diameter in points (default 120) |
- **Animation:** Trim animates with `.easeOut 0.5s`. Value text is `.monospacedDigit()` with dynamic formatting (2 decimals for <10, 1 decimal for <100, integer for >=1000).

### ThreeAxisView + AxisValue
| Axis | Color | Data Source Pattern |
|---|---|---|
| X | Red | `sensor.x` |
| Y | Green | `sensor.y` |
| Z | Blue | `sensor.z` |
- Each axis shows: bold colored label, 3-decimal `monospacedDigit` value, unit caption.

### DataRow
| Property | Type | Description |
|---|---|---|
| `label` | `String` | Row label (secondary color) |
| `value` | `String` | Row value (medium weight, monospacedDigit) |
| `icon` | `String?` | Optional SF Symbol (blue, 24pt frame) |

### StatusBadge
| Property | Type | Description |
|---|---|---|
| `text` | `String` | Badge text (uppercase style) |
| `color` | `Color` | Foreground + 15% opacity bg |
- **Style:** Capsule shape, `.caption` `.semibold` font, 10pt horizontal / 4pt vertical padding.

### CompassView
- **Size:** 170×170pt
- **Components:** Outer circle stroke, 72 tick marks (major every 18°, medium every 6°), N (red, bold), E/S/W labels, animated rotation driven by `heading`, red/gray triangle pointer, center dot, numeric heading display, cardinal direction text.
- **Animation:** `.easeOut 0.2s` rotation on heading change.

### AxisVisualization (Accelerometer bar chart)
- 3× `AxisBar` in `HStack`, each 200pt height
- Normalized range: ±2.0. Color: red/green/blue for X/Y/Z.
- Bar height proportional to absolute value; position above/below center based on sign.

### ActivityTile
- SF Symbol + label for each of 5 activity types
- Active tile: filled background + bold
- Inactive tile: outlined + regular weight

### StatBox (Pedometer floors)
- SF Symbol + numeric count + label ("Floors Up"/"Floors Down")

### ProgressCard
- Icon + title + formatted value
- `ProgressView` bar with tint color

---

## GLOBAL STATES & SYSTEM CONCERNS

### App Launch States
| Scenario | Behavior |
|---|---|
| First launch (`hasCompletedPermissionFlow == false`) | TabView renders but is overlaid by `PermissionRequestView` (zIndex:1, opacity transition) |
| Returning user (`hasCompletedPermissionFlow == true`) | TabView renders. `onAppear` calls `sensorManager.startAllSensors()` |

### Language Switching
- Persisted in `@AppStorage("selectedLanguage")`
- Live toggle via toolbar button → `confirmationDialog` with 3 options (flag + name + checkmark)
- All UI strings from translation dictionary; re-renders instantly on selection

### Dark Mode
- iOS native dark mode supported via `Color(.systemBackground)`, `Color(.systemGroupedBackground)`, `.ultraThinMaterial`

### Error Handling
- No network calls → no HTTP errors
- Sensor unavailability handled per-card via `isAvailable` flag
- Permissions denied → handled by `PermissionGate` + `PermissionDeniedView` with "Open Settings" link

### Data Refresh Rates
| Category | Interval | Mechanism |
|---|---|---|
| Motion (accel, gyro, mag, device motion) | 100ms (10 Hz) | `CMMotionManager.deviceMotionUpdateInterval = 0.1` |
| Pedometer | Event-driven | `CMPedometer.startUpdates` since app launch |
| Altimeter | Event-driven | `CMAltimeter.startRelativeAltitudeUpdates` |
| Location | Event-driven | `CLLocationManagerDelegate` callbacks |
| System (battery, thermal, disk) | 2s timer | `Timer.scheduledTimer` |
| Connectivity (network) | Event-driven | `NWPathMonitor` path update handler |
| Environment | Mixed (100ms + event-driven) | Based on sensor availability |

---

## NAVIGATION MAP

```
 PermissionRequestView (6 steps) ──→ ContentView
                                        │
                                    TabView (4 tabs)
                                        │
              ┌─────────────────────────┼─────────────────────┬──────────────────┐
         [Tab 0]                   [Tab 1]              [Tab 2]             [Tab 3]
       DashboardView           SystemInfoView       EnvironmentView       HealthView
              │                       │                      │                  │
     ┌────────┴────────┐    ┌───────┼───────┐     ┌───────┼──────┐    ┌─────┴──────┐
   21 detail         21    Battery Processor  Memory  Barometer Prox  HealthDisabled
   views        detail   Detail  Detail    Detail   Detail   Light  HealthContent
              views    Disk Thermal       (shared   Detail  Detail   (4 sections)
                    Battery Processor    views)
                    Memory Disk Thermal
```

---

**Total Screens:** 26 distinct UI screens  
- 1 Permission flow (6 steps — treated as 1 composite screen with 6 step states)
- 1 Dashboard (Sensors tab)
- 1 System Info tab
- 1 Environment tab
- 1 Health tab (2 states: disabled / enabled)
- 21 Sensor detail views
