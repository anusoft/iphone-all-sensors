# All Sensors — Complete Feature Catalog

> **App:** All Sensors (com.1moby.iPhoneSensors)  
> **Platform:** iOS 17+ (iPhone & iPad)  
> **Last Updated:** 2026-05-06  
> **Total Features:** 60+ across 9 categories

---

## Table of Contents

1. [Sensor Coverage](#1-sensor-coverage-21-sensors)
2. [Real-Time Dashboard](#2-real-time-dashboard)
3. [Sensor Detail Views](#3-sensor-detail-views-22-screens)
4. [Data Visualization](#4-data-visualization)
5. [Data Export & Sharing](#5-data-export--sharing)
6. [Sensor Recording](#6-sensor-recording)
7. [Device Diagnostics](#7-device-diagnostics)
8. [App Intents & Siri](#8-app-intents--siri-shortcuts)
9. [Widget Extension](#9-widget-extension)
10. [Localization](#10-localization--12-languages)
11. [UI/UX Features](#11-uiux-features)
12. [Permission System](#12-permission-system)
13. [Settings & Customization](#13-settings--customization)
14. [Privacy & Compliance](#14-privacy--compliance)
15. [Developer/Debug Features](#15-developer--debug-features)

---

## 1. Sensor Coverage (21 Sensors)

### Motion & Activity (7 sensors)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **Accelerometer** | CoreMotion | X, Y, Z (G) | 10 Hz |
| **Gyroscope** | CoreMotion | X, Y, Z (rad/s) | 10 Hz |
| **Magnetometer** | CoreMotion | X, Y, Z (µT) | 10 Hz |
| **Device Motion** | CoreMotion | Roll, Pitch, Yaw, Gravity, User Accel, Quaternion, Rotation Matrix | 10 Hz |
| **Pedometer** | CoreMotion | Steps, Distance, Floors, Pace, Cadence | Event-driven |
| **Altimeter** | CoreMotion | Relative Altitude, Pressure (kPa) | ~1 Hz |
| **Activity Recognition** | CoreMotion | Walking, Running, Cycling, Automotive, Stationary | Event-driven |

### Location & Navigation (2 sensors)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **GPS / Location** | CoreLocation | Lat, Long, Altitude, Speed, Course, Accuracy, Floor | ~1 Hz |
| **Compass / Heading** | CoreLocation | True Heading, Magnetic Heading, Accuracy | ~1 Hz |

### Environment (3 sensors)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **Barometer** | CoreMotion | Pressure (kPa), Relative Altitude | ~1 Hz |
| **Proximity** | UIDevice | Near/Far state | Event-driven |
| **Ambient Light** | UIScreen | Screen Brightness (0-1) | Event-driven |

### System (6 sensors)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **Battery** | UIDevice | Level (%), State (charging/full/unplugged) | 2s timer + events |
| **Processor** | ProcessInfo | Core count, Active cores | Static + 2s timer |
| **Memory** | ProcessInfo | Physical memory, Uptime | 2s timer |
| **Storage** | FileManager | Total, Free, Used disk space | 2s timer |
| **Thermal State** | ProcessInfo | Nominal/Fair/Serious/Critical | Event-driven |
| **Screen** | UIScreen | Bounds, Scale, Brightness, Captured state | 2s timer |

### Connectivity (2 sensors)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **Bluetooth** | CoreBluetooth | State, Discovered peripherals, Scanning | Event-driven |
| **Network** | Network / CoreTelephony | WiFi/Cellular, Carrier, Radio tech | Event-driven |

### Camera & Audio (1 sensor)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **Camera** | AVFoundation | Front/Rear availability, Flash, Torch, Zoom, Audio session | Static + 10s |

### Health (optional, disabled by default)
| Sensor | Framework | Data Points | Update Rate |
|--------|-----------|-------------|-------------|
| **HealthKit** | HealthKit | Heart rate, Steps, Energy, Blood pressure, etc. | On-demand |

---

## 2. Real-Time Dashboard

### Dashboard Cards (6 categories)
- **Motion & Activity** — Accelerometer, Gyroscope, Magnetometer, Device Motion, Pedometer, Altimeter, Activity
- **Location & Navigation** — GPS coordinates, Compass heading, Speed
- **Environment** — Barometer, Proximity, Screen brightness
- **System** — Battery, CPU, Memory, Storage, Thermal
- **Connectivity** — Bluetooth status, Network type, WiFi/Cellular
- **Camera & Audio** — Camera availability, Torch level, Audio devices

### Dashboard Features
- [x] **Search** — Search any sensor by name (real-time filtering)
- [x] **Availability indicators** — Green dot for active, red for unavailable
- [x] **Quick values** — Latest reading shown on each card
- [x] **Tap to detail** — Navigate to full sensor detail view
- [x] **Pull-to-refresh feel** — Scroll with glass morphism cards

---

## 3. Sensor Detail Views (22 Screens)

### Motion Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Accelerometer** | 3-axis bars, Real-time chart, Circular gauge, Axis visualization | CSV/JSON | Yes |
| **Gyroscope** | 3-axis bars, Real-time chart, Circular gauge, Rotation cube | CSV/JSON | Yes |
| **Magnetometer** | 3-axis bars, Real-time chart, Circular gauge | CSV/JSON | Yes |
| **Device Motion** | Attitude (roll/pitch/yaw), Chart, Gravity vector, Quaternion | CSV/JSON | Yes |
| **Pedometer** | Step count, Distance, Floors, Pace, Cadence | CSV/JSON | Yes |
| **Altimeter** | Pressure, Relative altitude | CSV/JSON | Yes |
| **Activity** | Activity state icons, Confidence level | — | — |

### Location Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **GPS / Location** | Coordinate display, Speed, Course, Accuracy, Floor | CSV/JSON | Yes |
| **Compass / Heading** | Compass dial, True/magnetic heading, Accuracy | — | — |

### Environment Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Barometer** | Pressure gauge, Chart, Altitude | CSV/JSON | Yes |
| **Proximity** | State indicator (Near/Far) | — | — |
| **Light / Brightness** | Brightness slider, Value display | — | — |

### System Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Battery** | Battery gauge, State, Charging status | — | — |
| **Processor** | Core count, Active cores | — | — |
| **Memory** | Usage display, Physical memory | — | — |
| **Storage** | Used/Free/Total with progress bar | — | — |
| **Thermal** | State indicator with color coding | — | — |

### Connectivity Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Bluetooth** | State, Scan toggle, Discovered devices list | — | — |
| **Network** | Connection type, WiFi info, Cellular carrier | — | — |

### Camera Detail Views
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Camera Info** | Front/Rear availability, Flash, Zoom | — | — |
| **Torch** — | Brightness slider, On/Off toggle | — | — |

### Health Detail View
| View | Visualizations | Export | Recording |
|------|---------------|--------|-----------|
| **Health** | Heart rate, Steps, Energy, Body metrics | — | — |

---

## 4. Data Visualization

### Charts (Swift Charts)
- [x] **Real-time line charts** — 3-axis (X=red, Y=green, Z=blue) with Catmull-Rom interpolation
- [x] **Single-value charts** — Line + Area mark for barometer, battery, etc.
- [x] **200-point rolling buffer** — Auto-removes old data to maintain performance
- [x] **Play/Pause toggle** — Pause data collection without stopping sensor
- [x] **Time-based X axis** — Shows timestamps, auto-scales
- [x] **Chart appears on:** Accelerometer, Gyroscope, Magnetometer, Device Motion, Barometer

### Gauges & Meters
- [x] **CircularGauge** — Ring progress indicator for magnitude/total values
- [x] **ThreeAxisView** — Horizontal bar chart for X/Y/Z values
- [x] **CompassDial** — Rotating compass rose with heading indicator

### 3D Visualizations
- [x] **AxisVisualization** — Vertical bars for accelerometer axes
- [x] **RotationCube** — 3D cube showing gyroscope rotation

---

## 5. Data Export & Sharing

### Export Formats
- [x] **CSV** — Comma-separated with headers, compatible with Excel/Numbers
- [x] **JSON** — Structured JSON with metadata (timestamp, sensor, device info)

### Export Sources
- [x] **Sensor detail view** — Export current chart data via toolbar button
- [x] **Recording sessions** — Export recorded data as CSV/JSON
- [x] **Diagnostic report** — Export text report via share sheet

### Sharing
- [x] **System share sheet** — AirDrop, Messages, Mail, Files, Notes
- [x] **Copy to clipboard** — For quick paste into other apps

---

## 6. Sensor Recording

### Recording System
- [x] **10Hz capture rate** — 10 samples per second
- [x] **Multiple sessions** — Record multiple sensors simultaneously
- [x] **Session management** — List all recordings with metadata
- [x] **Duration tracking** — Live timer during recording
- [x] **Data point count** — Shows total samples captured
- [x] **Red recording indicator** — Pulsing dot + "Recording" label

### Recording UI (in AccelerometerDetailView)
- [x] **Start/Stop recording** — Toolbar button toggle
- [x] **Recording list** — All sessions with duration and point count
- [x] **Swipe to delete** — Individual or clear all
- [x] **Export recording** — Share specific session as CSV/JSON

---

## 7. Device Diagnostics

### Diagnostic Test Suite (12 Tests)
| Test | What It Checks |
|------|---------------|
| Accelerometer | Hardware availability |
| Gyroscope | Hardware availability |
| Magnetometer | Hardware availability |
| GPS | Location authorization |
| Compass | Heading data available |
| Barometer | Altimeter availability |
| Proximity | Sensor enabled |
| Brightness | Screen available |
| Battery | Monitoring enabled |
| Bluetooth | Powered on |
| Network | Connected to network |
| Camera | Rear camera available |

### Diagnostic Features
- [x] **Run all tests** — Sequential execution with visual feedback
- [x] **Run single test** — Tap any test to re-run individually
- [x] **Pass/Fail/Skipped states** — Color-coded results
- [x] **Overall score** — Percentage circle (0-100%)
- [x] **Duration tracking** — Per-test timing
- [x] **Text report generation** — Shareable plain text report
- [x] **Report includes:** Device model, iOS version, date, all test results

---

## 8. App Intents & Siri Shortcuts

### Implemented Intents
- [x] **Get Sensor Reading** — "What's the accelerometer value?"
  - Parameters: Sensor type (accelerometer, gyroscope, magnetometer, GPS, compass, barometer, battery)
  - Returns: Current value as string
- [x] **Start Sensor Recording** — "Start recording gyroscope data"
  - Parameters: Sensor type
  - Returns: Confirmation dialog
- [x] **Export Sensor Data** — "Export my sensor data"
  - Returns: Confirmation dialog

### Siri Integration
- [x] **AppEnum for SensorType** — 7 sensor types with display names
- [x] **Short app phrases** — Optimized for voice recognition

---

## 9. Widget Extension

### Widget Configuration (Code Ready)
- [x] **Small widget** — Shows sensor icon, value, unit, active status dot
- [x] **Medium widget** — Shows sensor name, last update time, large value, unit
- [x] **Timeline provider** — Updates every 15 minutes (WidgetKit limit)
- [x] **Data source** — Reads from shared UserDefaults (`group.com.1moby.iPhoneSensors`)
- [x] **Dark/light theme** — Uses `containerBackground` for automatic adaptation

### Widget Files
- `iPhoneSensorsWidget/iPhoneSensorsWidget.swift` — Widget implementation
- `iPhoneSensorsWidget/Info.plist` — Extension configuration
- Status: Code complete, needs manual Xcode target addition

---

## 10. Localization (12 Languages)

### Supported Languages
| Code | Language | Display Name | Flag |
|------|----------|--------------|------|
| en | English | English | 🇺🇸 |
| th | Thai | ไทย | 🇹🇭 |
| zh | Chinese | 中文 | 🇨🇳 |
| ja | Japanese | 日本語 | 🇯🇵 |
| ko | Korean | 한국어 | 🇰🇷 |
| es | Spanish | Español | 🇪🇸 |
| fr | French | Français | 🇫🇷 |
| de | German | Deutsch | 🇩🇪 |
| pt | Portuguese | Português | 🇧🇷 |
| ar | Arabic | العربية | 🇸🇦 |
| it | Italian | Italiano | 🇮🇹 |
| ru | Russian | Русский | 🇷🇺 |

### Localization Coverage
- [x] **321 translation keys** — All UI labels, buttons, descriptions, settings
- [x] **Zero hardcoded strings** — All text routes through `locManager.t()`
- [x] **Dynamic language switch** — Change language without app restart
- [x] **Fallback chain** — Falls back to English if key missing
- [x] **RTL support** — Arabic text direction handled

---

## 11. UI/UX Features

### Visual Design
- [x] **Glass morphism cards** — Frosted glass effect with subtle borders
- [x] **Dark mode support** — Full dark theme with adjusted colors
- [x] **Light mode support** — Clean light theme with cream backgrounds
- [x] **System theme sync** — Auto-follow iOS system theme
- [x] **Manual theme override** — Force light/dark/system in settings
- [x] **Custom color accents** — Category-specific colors (blue=motion, green=location, etc.)

### Navigation
- [x] **Tab bar (5 tabs)** — Sensors, System, Environment, Diagnostic, Health
- [x] **NavigationStack** — Hierarchical navigation for detail views
- [x] **Search** — Global sensor search from dashboard
- [x] **Settings sheet** — Slide-up settings from any screen

### Animation
- [x] **Permission flow transitions** — Smooth page transitions between steps
- [x] **Chart updates** — Animated line drawing
- [x] **Gauge animations** — Smooth value transitions
- [x] **Card hover effects** — Subtle scale/opacity on interaction

---

## 12. Permission System

### Permission Onboarding (7 Steps)
| Step | Permission | Trigger |
|------|-----------|---------|
| 0 | Welcome | — |
| 1 | Location | GPS, Compass, Altitude |
| 2 | Motion | Accelerometer, Gyroscope, Steps |
| 3 | Camera | Camera Info, Torch |
| 4 | Microphone | Audio Input |
| 5 | Bluetooth | Nearby Devices |
| 6 | All Set | — |

### Permission Features
- [x] **Individual permission requests** — Only asks when user taps button
- [x] **Skip option** — "Not Now" button on each permission step
- [x] **Purpose strings** — Clear explanation for each permission
- [x] **Settings redirect** — If denied, offers to open Settings
- [x] **PermissionGate component** — Reusable gate for any permission type
- [x] **Graceful degradation** — App works with missing permissions

### Info.plist Purpose Strings (7 entries)
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription
- NSMotionUsageDescription
- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription

---

## 13. Settings & Customization

### Settings Sheet
- [x] **Language picker** — 12 languages with flags
- [x] **Theme picker** — Light / Dark / System
- [x] **Privacy policy link** — Opens in-app or external URL
- [x] **App version** — Display current version

### Theme System
- [x] **ThemeManager** — Observable object for global theme state
- [x] **AppTheme enum** — Light, Dark, System
- [x] **Color scheme injection** — `.preferredColorScheme()` at app level
- [x] **Glass card backgrounds** — Adaptive opacity for light/dark

---

## 14. Privacy & Compliance

### Privacy-First Design
- [x] **All data local** — No external servers, no analytics SDKs
- [x] **No tracking** — No advertising identifiers
- [x] **No third-party sharing** — Data never leaves device
- [x] **In-app privacy policy** — Accessible from settings
- [x] **Privacy nutrition label** — Accurate App Store Connect declaration

### Compliance Documents
- [x] `docs/privacy-policy.md` — Full privacy policy text
- [x] `docs/appstore-info.md` — Complete App Store Connect guide
- [x] `docs/app-store-metadata.md` — App Store listing copy
- [x] `docs/features.md` — App Store readiness analysis

---

## 15. Developer & Debug Features

### Console Logging
- [x] **Prefixed logs** — `[Motion]`, `[Location]`, `[System]`, etc.
- [x] **Update throttling** — Limits log frequency (e.g., every 100th accelerometer sample)
- [x] **Availability logging** — Logs which sensors are available on device
- [x] **Permission status logging** — Logs auth state changes

### Build Info
- [x] **Bundle ID:** com.1moby.iPhoneSensors
- [x] **Target:** iOS 17.0+
- [x] **Swift version:** 5.9+
- [x] **Architecture:** SwiftUI + Combine + ObservableObject pattern

---

## Feature Summary by Category

| Category | Feature Count | Key Highlight |
|----------|--------------|---------------|
| **Sensors** | 21 | Every iOS hardware sensor |
| **Views** | 22 | Dedicated detail screen per sensor |
| **Charts** | 6 | Real-time Swift Charts with 200-point buffer |
| **Export** | 2 | CSV + JSON with share sheet |
| **Recording** | 1 | 10Hz multi-sensor recording |
| **Diagnostics** | 12 | Full hardware test suite |
| **App Intents** | 3 | Siri shortcuts |
| **Widget** | 2 | Small + Medium (code ready) |
| **Localization** | 12 | 318 keys, 12 languages |
| **UI/UX** | 15 | Glass cards, dark/light, animations |
| **Permissions** | 7 | Guided onboarding flow |
| **Settings** | 3 | Language, theme, privacy |
| **Compliance** | 4 | Privacy policy, metadata, docs |
| **Total** | **~100** | |

---

## Not Yet Implemented (Planned)

| Feature | Status | File |
|---------|--------|------|
| Historical data logging | Planned | `docs/logging.md` (spec complete) |
| Log viewer | Planned | `docs/logging.md` (spec complete) |
| Apple Watch companion | Planned | — |
| Custom product pages | Optional | — |
| In-App Purchases | Not planned | Free app |
| Cloud sync | Not planned | Privacy-first |

---

## App Store Readiness Assets Created

### Screenshots (36 files in `/screenshots/`)
- **iPhone:** 6 screens × 3 sizes (6.7", 6.5", 5.5")
- **iPad:** 6 screens × 3 sizes (Pro 12.9", Pro 11", 9th gen)

### Submission Documentation
- [x] `docs/appstore-info.md` — Complete App Store Connect submission guide (631 lines, 35-point checklist)
- [x] `docs/app-store-metadata.md` — App Store listing metadata (name, subtitle, keywords, description)
- [x] `docs/privacy-policy.md` — In-app privacy policy content
- [x] `docs/features.md` — App Store readiness analysis (LOW risk)
- [x] `docs/logging.md` — Per-sensor logging feature specification (382 lines)
- [x] `docs/current-allsensors-features.md` — This comprehensive feature catalog

---

*Document Version: 1.0*  
*Generated: 2026-05-06*  
*Source: Automated analysis of iPhoneSensors codebase*
