# All Sensors - iPhone Sensor Viewer

A comprehensive iOS app that displays real-time data from **all available iPhone sensors** with beautiful UI visualizations.

Built with **SwiftUI** and powered by **Xiaomi MiMo 2.5 Pro** AI assistant.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

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

### UI Features

- **Real-time data** with live updates as you move your device
- **Beautiful visualizations**: circular gauges, 3D phone orientation, compass dial
- **Permission flow**: guided UI explaining why each sensor needs access
- **Search**: find any sensor quickly
- **Multi-language**: English, ไทย (Thai), 中文 (Chinese)
- **Dark mode** support
- **Diagnostic logging** for debugging

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
│   ├── iPhoneSensorsApp.swift    # App entry point
│   └── ContentView.swift         # Main tab view
├── Views/
│   ├── Dashboard/                # Main sensor dashboard
│   ├── Sensors/                  # Individual sensor detail views
│   └── Components/               # Reusable UI components
├── Services/
│   ├── SensorManager.swift       # Central sensor coordinator
│   ├── MotionSensorManager.swift # Accelerometer, Gyroscope, etc.
│   ├── LocationSensorManager.swift # GPS, Compass
│   ├── EnvironmentSensorManager.swift # Barometer, Proximity
│   ├── SystemSensorManager.swift # Battery, Processor, Memory
│   ├── ConnectivitySensorManager.swift # Bluetooth, Network
│   ├── CameraSensorManager.swift # Camera, Torch
│   ├── PermissionManager.swift   # Permission handling
│   └── LocalizationManager.swift # Multi-language support
├── Models/
│   └── SensorCategory.swift      # Data models
└── Resources/
    └── Info.plist                 # App configuration
```

## Permissions

The app requests the following permissions:

| Permission | Purpose |
|------------|---------|
| Location | GPS coordinates, altitude, compass heading |
| Motion & Fitness | Accelerometer, gyroscope, pedometer, activity data |
| Camera | Camera capabilities, torch control |
| Microphone | Audio input information |

All permissions are optional — you can skip any during the onboarding flow.

## Architecture

- **SwiftUI** for declarative UI
- **ObservableObject** pattern with `@EnvironmentObject` for reactive data binding
- **CoreMotion** for motion sensors
- **CoreLocation** for GPS and compass
- **CoreBluetooth** for BLE scanning
- **AVFoundation** for camera/audio

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
