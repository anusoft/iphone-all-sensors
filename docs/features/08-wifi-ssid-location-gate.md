# Feature 08: WiFi SSID Conditional Rendering with Location Gate

## Goal
Implement progressive, conditional permission gating for WiFi SSID display to prevent App Store rejection for broken functionality (Guideline 2.1).

## App Store Compliance Justification
Apple requires Precise Location authorization to display WiFi SSID. Without proper gating, the SSID field appears blank, leading reviewers to flag it as broken.

## Requirements

### Core Functionality
- [ ] Add `com.apple.developer.networking.wifi-info` entitlement to project
- [ ] Check `CLLocationManager.authorizationStatus()` before attempting SSID read
- [ ] If precise location denied, show educational message instead of blank field
- [ ] Gracefully degrade: show "WiFi Connected" boolean instead of SSID name
- [ ] Provide button to open Settings → Location Services

### UI/UX
- [ ] Network detail view shows SSID when available
- [ ] If location permission missing, show:
  - Info icon + message: "To display the current WiFi Network Name (SSID), Apple privacy guidelines require Precise Location Services to be enabled, as network names can be utilized to determine geographic location."
  - "Open Settings" button
- [ ] Never show empty field where SSID should be

### Technical Details
- Use `NEHotspotConfiguration` or `CNCopyCurrentNetworkInfo` (deprecated but still functional with entitlement)
- Requires `Access WiFi Information` capability in Apple Developer portal
- Requires `Location When In Use` permission at minimum
- Store permission state and update UI reactively

## Files to Modify
- `iPhoneSensors/Views/Sensors/NetworkDetailView.swift`
- `iPhoneSensors/Services/ConnectivitySensorManager.swift`
- `iPhoneSensors/Services/LocationSensorManager.swift`
- `iPhoneSensors/Info.plist` (entitlements)
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `network.ssid`
- `network.ssidUnavailable`
- `network.ssidRequiresLocation`
- `network.openSettings`
- `network.wifiConnected`

## Acceptance Criteria
- [ ] SSID displays when location permission is granted
- [ ] Educational message displays when permission is denied
- [ ] No blank fields in Network view
- [ ] Entitlement is properly configured
