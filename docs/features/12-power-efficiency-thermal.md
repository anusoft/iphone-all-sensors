# Feature 12: Power Efficiency & Thermal Throttling

## Goal
Implement intelligent internal throttling that automatically pauses high-frequency polling or reduces visual refresh rates when device enters Low Power Mode or exceeds nominal thermal states.

## App Store Compliance Justification
Prevents rejection under Guideline 2.4.2 (Power Efficiency) for excessive battery drain and thermal throttling during review.

## Requirements

### Core Functionality
- [ ] Monitor `ProcessInfo.thermalState` continuously
- [ ] Monitor `ProcessInfo.processInfo.isLowPowerModeEnabled`
- [ ] When thermal state ≥ `.serious` OR Low Power Mode is ON:
  - Reduce sensor polling from 10Hz to 2Hz
  - Pause real-time chart updates (show "Paused for power efficiency" message)
  - Pause recording sessions
  - Disable haptic feedback
- [ ] When conditions return to normal, resume automatically
- [ ] Show power efficiency status indicator in dashboard

### UI/UX
- [ ] Dashboard shows subtle icon when throttling is active (🌡️ or 🔋)
- [ ] Detail views show banner: "Reduced refresh rate to conserve power"
- [ ] Recording sessions show "Paused — Low Power Mode" status
- [ ] Settings includes option to "Always allow full rate" (disabled by default for compliance)

### Technical Details
- Use `NotificationCenter` for `NSProcessInfoThermalStateDidChange` and `NSProcessInfoPowerStateDidChange`
- Throttle by adjusting `CMMotionManager` update intervals
- Pause charts by setting `chartData.isPaused = true`
- Resume when state returns to `.nominal` or `.fair` AND Low Power Mode is off

## Files to Modify
- `iPhoneSensors/Services/SystemSensorManager.swift` (thermal monitoring)
- `iPhoneSensors/Services/SensorManager.swift` (throttle logic)
- `iPhoneSensors/Views/DashboardView.swift` (status indicator)
- `iPhoneSensors/Views/Components/SensorComponents.swift` (chart pause)
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `power.thermalThrottling`
- `power.lowPowerMode`
- `power.reducedRefresh`
- `power.pausedForEfficiency`
- `power.resumed`
- `settings.allowFullRate`

## Acceptance Criteria
- [ ] Throttling activates automatically in Low Power Mode
- [ ] Throttling activates automatically at serious thermal state
- [ ] Charts pause with clear message
- [ ] Recording pauses automatically
- [ ] Resume happens automatically when conditions improve
