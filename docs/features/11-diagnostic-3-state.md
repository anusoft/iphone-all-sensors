# Feature 11: Diagnostic 3-State Results (Unavailable / Permission Denied / Active)

## Goal
Re-engineer the diagnostic suite to distinguish between hardware unavailability, permission denial, and active states to avoid misleading users and reviewers (Guideline 1.4.1).

## App Store Compliance Justification
Prevents rejection for inaccurate device data and misleading users. Reviewers reject apps that claim hardware is "Failed" when it's merely software-gated.

## Requirements

### Core Functionality
- [ ] Replace binary Pass/Fail with three distinct states:
  - **Hardware Unavailable** — Device physically lacks the sensor (gray icon)
  - **Permission Denied** — Hardware present but iOS privacy gate closed (yellow icon)
  - **Active** — Sensor available and responding (green icon)
- [ ] Update `DiagnosticManager` to check both hardware availability AND authorization status
- [ ] Update `DiagnosticView` to show nuanced status indicators
- [ ] Update report generation to include these states

### UI/UX
- [ ] Each test result shows:
  - Icon: ⚙️ for unavailable, 🔒 for permission denied, ✓ for active
  - Label: "Unavailable", "Permission Required", "Active"
  - Color: Gray, Yellow, Green
- [ ] If Permission Denied, show "Open Settings" button
- [ ] Overall score calculation excludes "Unavailable" sensors from denominator

### Technical Details
- Check `CMMotionManager.isAccelerometerAvailable` vs authorization separately
- Check `CLLocationManager.authorizationStatus()` for location-based sensors
- Check `HKHealthStore.isHealthDataAvailable()` for HealthKit
- Store per-test status enum: `unavailable`, `permissionDenied`, `active`

## Files to Modify
- `iPhoneSensors/Services/DiagnosticManager.swift`
- `iPhoneSensors/Views/DiagnosticView.swift`
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `diagnostic.unavailable`
- `diagnostic.permissionDenied`
- `diagnostic.permissionRequired`
- `diagnostic.active`
- `diagnostic.openSettings`

## Acceptance Criteria
- [ ] Each sensor shows correct 3-state result
- [ ] Unavailable sensors don't penalize overall score
- [ ] Permission Denied sensors show actionable button
- [ ] Report text reflects nuanced states
