# Feature 04: Add Real-Time Line Charts

## Checklist

- [ ] Create reusable SensorChartView component
- [ ] Add to AccelerometerDetailView (X, Y, Z lines)
- [ ] Add to GyroscopeDetailView (X, Y, Z lines)
- [ ] Add to MagnetometerDetailView (X, Y, Z + total)
- [ ] Add to DeviceMotionDetailView (roll, pitch, yaw)
- [ ] Add to BarometerDetailView (pressure over time)
- [ ] Implement rolling window (last 100 data points)
- [ ] Color-code lines (red=X, green=Y, blue=Z)
- [ ] Add play/pause toggle for chart updates
- [ ] Test performance on physical device

## Details

**New File:** `Views/Components/SensorChartView.swift`

**Requirements:**
- Use Swift Charts framework (`import Charts`)
- Rolling buffer of 100-200 data points
- Update at 10Hz (matching sensor update rate)
- Show legend for each axis
- Smooth line interpolation
- Dark/light theme support

**Data Structure:**
```swift
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}
```

**Modified Files:**
- `Views/Sensors/AccelerometerDetailView.swift`
- `Views/Sensors/GyroscopeDetailView.swift`
- `Views/Sensors/MagnetometerDetailView.swift`
- `Views/Sensors/DeviceMotionDetailView.swift`
- `Views/Sensors/BarometerDetailView.swift`

## Why This Matters
Every successful competitor (Sensor Kinetics, Physics Toolbox) has real-time oscilloscope-style graphs. This is the #1 feature users expect and Apple reviewers look for to judge "app-like" quality.
