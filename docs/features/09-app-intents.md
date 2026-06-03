# Feature 09: Add App Intents for Shortcuts

## Checklist

- [ ] Create AppIntent for "Get Sensor Reading"
- [ ] Create AppIntent for "Start Recording"
- [ ] Create AppIntent for "Stop Recording"
- [ ] Create AppIntent for "Export Sensor Data"
- [ ] Support Siri voice commands
- [ ] Support Shortcuts app automation
- [ ] Localize intent titles and descriptions
- [ ] Add parameter for sensor selection
- [ ] Test with Shortcuts app

## Details

**New File:** `AppIntents/SensorAppIntents.swift`

**Example Intents:**
```swift
struct GetSensorReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Reading"
    static var description = IntentDescription("Get the current value of a specific sensor.")
    
    @Parameter(title: "Sensor", description: "Which sensor to read")
    var sensor: SensorType
    
    func perform() async throws -> some IntentResult {
        let value = await SensorManager.shared.getValue(for: sensor)
        return .result(value: value)
    }
}

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sensor Recording"
    static var description = IntentDescription("Start recording sensor data.")
    
    @Parameter(title: "Sensor", description: "Which sensor to record")
    var sensor: SensorType
    
    func perform() async throws -> some IntentResult {
        await SensorRecorder.shared.startRecording(sensor: sensor)
        return .result(dialog: "Started recording \(sensor.displayName)")
    }
}
```

**Modified Files:**
- `iPhoneSensorsApp.swift` (register intent handlers)
- `Info.plist` (add intent definitions)

## Why This Matters
App Intents make the app feel native and integrated with iOS. "Hey Siri, what's my battery level?" or automation shortcuts increase daily utility and App Store appeal.
