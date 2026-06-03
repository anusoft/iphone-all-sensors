# Feature 02: Inclinometer & Surface Level Tooling

## Goal
Create a dedicated dual-axis surface level interface for physical measurement, augmented with haptic feedback when absolute zero is achieved.

## App Store Compliance Justification
Elevates the application from a numerical readout to a practical physical measurement tool, adding lasting utility. Demonstrates deep native integration with CoreHaptics.

## Requirements

### Core Functionality
- [ ] Add new "Level Tool" mode accessible from Device Motion detail view or as standalone view
- [ ] Display dual-axis bubble level visualization (X and Y axes)
- [ ] Show numeric angle readout for both axes in degrees
- [ ] When both axes are within ±0.5° of zero, trigger CoreHaptics "success" pulse
- [ ] Visual indicator turns green when level is achieved
- [ ] Optional: Calibrate to current position as "zero" reference

### UI/UX
- [ ] Large, high-contrast bubble level UI (similar to iOS native level tool but custom)
- [ ] Circular level with crosshair and floating bubble
- [ ] Numeric readout below visualization
- [ ] Calibration button to set current orientation as reference
- [ ] Lock orientation button to prevent rotation

### Technical Details
- Use `CMDeviceMotion.attitude.roll` and `.pitch` for X/Y angles
- Convert radians to degrees for display
- Use `CoreHaptics` for haptic feedback (light impact when close, heavy impact when level)
- Update at 30Hz for smooth visual feedback

## Files to Modify
- `iPhoneSensors/Views/Sensors/DeviceMotionDetailView.swift` (add level mode)
- `iPhoneSensors/Services/MotionSensorManager.swift` (add level calculations)
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `level.title`
- `level.calibrate`
- `level.locked`
- `level.unlocked`
- `level.angle`
- `level.levelAchieved`

## Acceptance Criteria
- [ ] Bubble level responds smoothly to device tilt
- [ ] Haptic feedback fires when level is achieved
- [ ] Calibration sets custom zero reference
- [ ] Numeric readout accurate within ±0.1°
