# All Sensors - iPhone Sensor Viewer

A comprehensive iOS app that displays real-time data from **all available iPhone sensors** with beautiful UI visualizations, charts, data export, and hardware diagnostics.

Built with **SwiftUI** and powered by **Xiaomi MiMo 2.5 Pro** AI assistant.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

**🌐 Languages:** English | ไทย (Thai) | 中文 (Chinese) | 日本語 (Japanese) | 한국어 (Korean) | Español (Spanish) | Français (French) | Deutsch (German) | Português (Portuguese) | العربية (Arabic) | Italiano (Italian) | Русский (Russian)

## Features

### Sensors Supported

| Category | Sensors |
|----------|---------|
| **Motion & Activity** | Accelerometer, Gyroscope, Magnetometer, Device Motion (attitude, gravity, rotation, quaternion, rotation matrix), Pedometer (steps, distance, floors), Altimeter (pressure, altitude), Activity Recognition |
| **Location & Navigation** | GPS (coordinates, altitude, speed, course), Compass (true/magnetic heading) |
| **Environment** | Barometer (kPa, hPa, inHg, mbar), Proximity Sensor, Screen Brightness |
| **System** | Battery (level, state), Processor (cores, uptime), Memory, Storage, Thermal State |
| **Connectivity** | Bluetooth (scanning, peripherals), Network (Wi-Fi/Cellular) |
| **Camera & Audio** | Camera info, Torch control, Audio session |
| **Health** | Heart rate, step count (requires Apple Developer account with HealthKit) |

### UI Features

- **Real-time data** with live updates as you move your device
- **Beautiful visualizations**: circular gauges, 3D phone orientation, compass dial
- **Live charts**: Real-time Swift Charts with play/pause and 200-point rolling buffer
- **Data export**: Export sensor readings as CSV or JSON via share sheet
- **Sensor recording**: Record data at 10Hz with session management
- **Diagnostic mode**: Run comprehensive 12-sensor hardware tests with overall health score
- **Permission flow**: Guided UI explaining why each sensor needs access
- **Search**: Find any sensor quickly
- **Multi-language**: 12 languages supported
- **Dark mode** support
- **App Intents**: Siri shortcuts for getting sensor readings, starting recordings, exporting data

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Physical iPhone (most sensors require real hardware)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Open in Xcode:
```bash
open iPhoneSensors.xcodeproj
```

3. Select your iPhone as the target device

4. Sign the app with your Apple ID:
   - Click the project in the navigator
   - Select the "iPhoneSensors" target
   - Under "Signing & Capabilities", select your Team

5. Build and run (`Cmd+R`)

6. On your iPhone, go to **Settings → General → VPN & Device Management** and trust your developer profile

## Project Structure

```
iPhoneSensors/
├── App/
│   ├── iPhoneSensorsApp.swift          # App entry point + App Intents
│   └── ContentView.swift               # Main tab view (5 tabs)
├── Views/
│   ├── Dashboard/                      # Main sensor dashboard
│   │   ├── DashboardView.swift
│   │   ├── SystemInfoView.swift        # + DiagnosticView merged
│   │   ├── EnvironmentView.swift
│   │   └── HealthView.swift
│   ├── Sensors/                        # Individual sensor detail views
│   │   ├── AccelerometerDetailView.swift  # + RecordingListView merged
│   │   └── ... (16 other sensor views)
│   └── Components/                     # Reusable UI components
│       ├── SensorComponents.swift      # + SensorChartView merged
│       ├── PermissionGate.swift
│       └── ...
├── Services/
│   ├── SensorManager.swift             # Central coordinator + Export + Recorder + Diagnostic
│   ├── MotionSensorManager.swift       # Accelerometer, Gyroscope, etc.
│   ├── LocationSensorManager.swift     # GPS, Compass
│   ├── EnvironmentSensorManager.swift  # Barometer, Proximity
│   ├── SystemSensorManager.swift       # Battery, Processor, Memory
│   ├── ConnectivitySensorManager.swift # Bluetooth, Network
│   ├── CameraSensorManager.swift       # Camera, Torch
│   ├── PermissionManager.swift         # Permission handling
│   └── LocalizationManager.swift       # 12-language support (318 keys)
├── Models/
│   └── SensorCategory.swift            # Data models
├── Resources/
│   ├── Assets.xcassets/                # App icon + accent color
│   └── Info.plist                      # App configuration + purpose strings
└── iPhoneSensorsWidget/                # Future WidgetKit scaffold (not part of current target)
    ├── iPhoneSensorsWidget.swift
    ├── Info.plist
    └── Assets.xcassets/
```

## Permissions

The app requests the following permissions with full purpose strings:

| Permission | Purpose |
|------------|---------|
| Location | GPS coordinates, altitude, compass heading |
| Motion & Fitness | Accelerometer, gyroscope, pedometer, activity data |
| Camera | Camera capabilities, torch control |
| Microphone | Audio input information |
| Bluetooth | Discover nearby Bluetooth devices |
| Health | Heart rate, steps (optional, currently disabled) |

All permissions are optional — you can skip any during the onboarding flow.

## Architecture

- **SwiftUI** for declarative UI
- **ObservableObject** pattern with `@EnvironmentObject` for reactive data binding
- **CoreMotion** for motion sensors
- **CoreLocation** for GPS and compass
- **CoreBluetooth** for BLE scanning
- **AVFoundation** for camera/audio
- **Swift Charts** for real-time data visualization
- **App Intents** for Siri shortcuts

## Data Export

Export sensor data in two formats:
- **CSV**: Compatible with Excel, Numbers, Google Sheets
- **JSON**: Structured data for developers and researchers

Access export from any sensor detail view via the toolbar share button.

## Diagnostic Mode

The Diagnostic tab runs comprehensive hardware tests:
- 12 sensor category tests
- Individual pass/fail results
- Overall health score (0-100%)
- Shareable text report
- Perfect for verifying device functionality before purchase or repair

## Diagnostic Logging

The app includes comprehensive logging with prefixed tags:

```
[Motion] 📊 Acc[1]: x=0.123 y=-0.456 z=0.789
[Location] 📍 13.7563, 100.5018 alt=5.2m
[Location] 🧭 #1: true=127.3° mag=131.2°
[System] 🔋 Battery: 85.0% (Charging)
```

View logs in Xcode's console (`Cmd+Shift+Y`) or stream from terminal:
```bash
xcrun devicectl device info log stream --device <DEVICE_ID> 2>&1 | grep -E "\[Motion\]|\[Location\]|\[System\]"
```

## App Store Readiness

This app has been prepared for App Store submission:

- ✅ All required purpose strings in Info.plist
- ✅ Complete UI localization (12 languages)
- ✅ In-app privacy policy
- ✅ App icon (1024x1024)
- ✅ Real-time charts
- ✅ Data export (CSV/JSON)
- ✅ Sensor recording
- ✅ Diagnostic mode
- ✅ App Intents for Siri
- ⚠️ Widget source scaffold excluded from the v1 target and App Store claims

See `docs/app-store-metadata.md` for App Store listing information.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-sensor`)
3. Commit your changes (`git commit -m 'Add amazing sensor'`)
4. Push to the branch (`git push origin feature/amazing-sensor`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with **Xiaomi MiMo 2.5 Pro** AI assistant
- Apple's CoreMotion, CoreLocation, CoreBluetooth, and AVFoundation frameworks
- SwiftUI community for UI patterns and best practices

---

**Note**: Most sensors (accelerometer, gyroscope, etc.) only work on physical iOS devices, not the simulator.
