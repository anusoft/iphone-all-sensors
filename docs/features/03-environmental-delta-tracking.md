# Feature 03: Environmental Delta Tracking (Barometer Elevation Tracker)

## Goal
Implement an automated elevation tracker and weather delta predictor that calculates atmospheric pressure changes over a prolonged user-initiated session.

## App Store Compliance Justification
Transforms raw kilopascal (kPa) readings into predictive insights, differentiating the app from basic dashboard wrappers. Addresses Guideline 4.2 by providing active utility.

## Requirements

### Core Functionality
- [ ] Add "Track Session" button to Barometer detail view
- [ ] When session starts, record baseline pressure and begin tracking changes
- [ ] Calculate relative elevation change from pressure delta (hypsometric formula)
- [ ] Show pressure trend: Rising / Falling / Stable
- [ ] Weather prediction heuristic: rapid drop = storm approaching, steady rise = clearing
- [ ] Session timer showing elapsed time
- [ ] Export session data as CSV/JSON

### UI/UX
- [ ] Large delta display showing ±kPa from baseline
- [ ] Elevation change in meters/feet
- [ ] Trend arrow (↗ Rising, ↘ Falling, → Stable)
- [ ] Weather prediction text ("Conditions improving", "Storm possible", etc.)
- [ ] Session history list with duration and max delta

### Technical Details
- Baseline pressure captured at session start
- Elevation formula: `h = 44330 * (1 - (P/P0)^(1/5.255))` where P0 is baseline
- Update every 10 seconds to avoid noise
- Minimum 5-minute session for weather prediction
- Store session history in UserDefaults

## Files to Modify
- `iPhoneSensors/Views/Sensors/BarometerDetailView.swift`
- `iPhoneSensors/Services/EnvironmentSensorManager.swift`
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `barometer.trackSession`
- `barometer.stopSession`
- `barometer.baseline`
- `barometer.delta`
- `barometer.elevationChange`
- `barometer.trend.rising`
- `barometer.trend.falling`
- `barometer.trend.stable`
- `barometer.weather.improving`
- `barometer.weather.storm`
- `barometer.weather.stable`

## Acceptance Criteria
- [ ] Session tracks pressure delta accurately
- [ ] Elevation calculation within ±10m accuracy
- [ ] Weather prediction displayed after 5 minutes
- [ ] Session history persists across launches
