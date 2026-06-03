# Feature 01: Vibration Threshold Alarms (Seismometer Mode)

## Goal
Transform the passive accelerometer from a read-only dashboard into an active utility tool by implementing a rule engine that triggers local iOS notifications when specific G-force thresholds are breached.

## App Store Compliance Justification
Addresses Guideline 4.2 (Minimum Functionality) by demonstrating active background processing and utilizing native push notification architectures for tangible user alerts. Elevates the app from a passive data aggregator to an active utility.

## Requirements

### Core Functionality
- [ ] Add "Seismometer Mode" toggle to Accelerometer detail view
- [ ] Allow user to set G-force threshold (e.g., 0.5G, 1.0G, 2.0G, 5.0G, custom)
- [ ] When threshold is exceeded, trigger local notification immediately
- [ ] Notification includes timestamp, peak G-force value, and axis that triggered it
- [ ] Background processing: use `BGProcessingTask` or `BGAppRefreshTask` to continue monitoring when app is backgrounded
- [ ] Haptic feedback (CoreHaptics) on threshold breach when app is foreground

### UI/UX
- [ ] Threshold picker UI (slider or segmented control)
- [ ] Visual alarm state indicator (pulsing red border or banner)
- [ ] Alarm history list showing past threshold breaches with timestamps
- [ ] Enable/disable toggle with clear on/off state
- [ ] Localization keys for all new UI strings (12 languages)

### Technical Details
- Use `UNUserNotificationCenter` for local notifications
- Request notification permission in onboarding flow (new step or integrated into existing)
- Calculate vector magnitude `sqrt(x² + y² + z²)` and compare against threshold
- Debounce: minimum 2 seconds between notifications to prevent spam
- Store alarm history in UserDefaults (limited to last 50 events)

## Files to Modify
- `iPhoneSensors/Views/Sensors/AccelerometerDetailView.swift`
- `iPhoneSensors/Services/MotionSensorManager.swift`
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)
- `iPhoneSensors/Info.plist` (add `UIBackgroundModes` if not present)

## Localization Keys Needed
- `seismometer.title`
- `seismometer.enable`
- `seismometer.threshold`
- `seismometer.alarmHistory`
- `seismometer.noAlarms`
- `seismometer.notificationTitle`
- `seismometer.notificationBody`
- `seismometer.axisX`
- `seismometer.axisY`
- `seismometer.axisZ`

## Acceptance Criteria
- [ ] User can enable seismometer mode and set a threshold
- [ ] When device is shaken beyond threshold, local notification fires
- [ ] Alarm history persists across app launches
- [ ] Works in both foreground and background
- [ ] All UI strings are localized
