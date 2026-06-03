# Feature 04: Signal Mapping & KML Export

## Goal
Allow users to record signal strength drops across geographic coordinates to map dead zones in physical environments, exporting results as KML files.

## App Store Compliance Justification
Integrates CoreLocation with Network frameworks to create a unique, combinatorial feature not natively available in iOS settings. Demonstrates active utility and data transformation.

## Requirements

### Core Functionality
- [ ] Add "Signal Map" mode to Connectivity/Network detail view
- [ ] Record GPS coordinates + WiFi signal strength (RSSI) + Cellular signal strength
- [ ] Real-time map showing signal strength heatmap along user's path
- [ ] Color-coded pins: Green (strong), Yellow (moderate), Red (weak/no signal)
- [ ] Export collected data as KML file for Google Earth
- [ ] Export as CSV with lat/long/signal/timestamp columns

### UI/UX
- [ ] Map view using MapKit showing user's path with colored annotations
- [ ] Signal strength gauge (dBm display)
- [ ] Recording controls: Start / Pause / Stop
- [ ] List of recorded points with coordinates and signal values
- [ ] Share/export button for KML/CSV

### Technical Details
- Use `CTTelephonyNetworkInfo` for cellular signal (where available)
- Use `CoreWLAN` (private) or heuristic from network reachability for WiFi strength
- If exact RSSI unavailable, infer from connection quality (Excellent/Good/Poor)
- KML format compatible with Google Earth
- Minimum 3 data points before export is allowed
- Background location updates required for mapping while walking/driving

## Files to Modify
- `iPhoneSensors/Views/Sensors/NetworkDetailView.swift` (or new SignalMapView)
- `iPhoneSensors/Services/ConnectivitySensorManager.swift`
- `iPhoneSensors/Services/LocationSensorManager.swift`
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `signalMap.title`
- `signalMap.startRecording`
- `signalMap.stopRecording`
- `signalMap.wifiStrength`
- `signalMap.cellularStrength`
- `signalMap.exportKML`
- `signalMap.exportCSV`
- `signalMap.noData`

## Acceptance Criteria
- [ ] User can record signal strength at multiple locations
- [ ] Map displays colored pins along recorded path
- [ ] KML export opens in Google Earth
- [ ] CSV export has correct lat/long/signal columns
