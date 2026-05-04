# Contributing to All Sensors

Thank you for your interest in contributing! Here's how you can help.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Open `iPhoneSensors/iPhoneSensors.xcodeproj` in Xcode
4. Create a new branch for your feature

## How to Contribute

### Adding a New Sensor

1. Create a new manager in `Services/` (e.g., `NewSensorManager.swift`)
2. Make it an `ObservableObject` with `@Published` properties
3. Add it to `SensorManager.swift`
4. Register it as `@EnvironmentObject` in `iPhoneSensorsApp.swift`
5. Create dashboard card in `Views/Dashboard/`
6. Create detail view in `Views/Sensors/`
7. Add to search list in `DashboardView.swift`

### Reporting Bugs

- Use GitHub Issues
- Include device model and iOS version
- Include console logs if possible
- Steps to reproduce

### Code Style

- Use SwiftUI for all UI
- Use `@EnvironmentObject` for sensor data (not nested access)
- Add `print()` logging with `[Tag]` prefix
- Keep views small and composable

## Testing

- Test on physical device (most sensors don't work in simulator)
- Check all permission states (granted, denied, not determined)
- Verify data updates in real-time

## Questions?

Open an issue or start a discussion!
