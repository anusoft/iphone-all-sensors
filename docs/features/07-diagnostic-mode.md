# Feature 07: Add Device Diagnostic Mode

## Checklist

- [ ] Create DiagnosticManager service
- [ ] Create DiagnosticView with test suite
- [ ] Test each sensor with guided steps:
  - [ ] Accelerometer: Shake device
  - [ ] Gyroscope: Rotate device
  - [ ] Magnetometer: Move near metal
  - [ ] GPS: Step outside
  - [ ] Barometer: Change altitude
  - [ ] Proximity: Cover screen
  - [ ] Brightness: Change lighting
  - [ ] Battery: Check level
  - [ ] Bluetooth: Toggle state
  - [ ] Camera: Check availability
- [ ] Pass/fail result for each test
- [ ] Overall diagnostic score (pass rate)
- [ ] Generate shareable report (text/PDF)
- [ ] Add Diagnostic tab to main tab bar
- [ ] Add "Run All Tests" batch mode
- [ ] Time estimate for full test (60 seconds)

## Details

**New File:** `Services/DiagnosticManager.swift`

**New File:** `Views/Diagnostic/DiagnosticView.swift`

**New File:** `Views/Diagnostic/DiagnosticResultView.swift`

**Test Model:**
```swift
struct DiagnosticTest: Identifiable {
    let id = String
    let name: String
    let description: String
    let icon: String
    let testAction: () async -> TestResult
}

enum TestResult {
    case passed
    case failed(String)
    case skipped
    case inProgress
}
```

**Report Format:**
```
Device Diagnostic Report
========================
Device: iPhone 17 Pro
iOS: 26.2
Date: 2026-05-05 10:30:00

Tests Passed: 18/20 (90%)

✅ Accelerometer - PASSED
✅ Gyroscope - PASSED
❌ Barometer - FAILED (No pressure change detected)
✅ GPS - PASSED
...
```

**Tab Bar Integration:**
Replace or add alongside existing tabs. Recommended: Add as 5th tab "Diagnostic" with stethoscope icon.

**Modified Files:**
- `App/ContentView.swift` (add Diagnostic tab)
- `LocalizationManager.swift` (add diagnostic labels)

## Why This Matters
This is the strongest differentiator. "Device Diagnostic" is a clear, defensible positioning with a specific audience (used phone buyers/sellers, repair shops). Apple is much less likely to reject an app that provides genuine hardware testing utility.
