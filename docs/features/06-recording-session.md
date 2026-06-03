# Feature 06: Add Sensor Recording Session

## Checklist

- [ ] Create SensorRecorder service
- [ ] Record button (red circle) in detail views
- [ ] Stop button (square) when recording
- [ ] Recording indicator (pulsing red dot)
- [ ] Timestamped data points in memory buffer
- [ ] Session list view (history of recordings)
- [ ] Play back recording as animation
- [ ] Export recording to CSV/JSON
- [ ] Delete recording
- [ ] Show recording duration
- [ ] Battery drain warning for long recordings

## Details

**New File:** `Services/SensorRecorder.swift`

**New File:** `Views/Sensors/RecordingListView.swift`

**Recording Model:**
```swift
struct SensorRecording: Identifiable {
    let id = UUID()
    let sensorName: String
    let startTime: Date
    let endTime: Date?
    var dataPoints: [SensorDataPoint]
}

struct SensorDataPoint {
    let timestamp: Date
    let values: [String: Double]
}
```

**UI Flow:**
1. User taps red record button in detail view
2. Pulsing red indicator appears in toolbar
3. Data points collected at sensor update rate
4. User taps stop (square button)
5. Recording saved to session list
6. User can play back, export, or delete

**Modified Files:**
- All `*DetailView.swift` files (add record/stop button)
- `SensorManager.swift` (integrate recorder)
- `LocalizationManager.swift` (add recording labels)

## App Store Guideline
Section 2.5.14 — Apps must request explicit user consent and provide a clear visual indication when recording, logging, or making a record of user activity.
