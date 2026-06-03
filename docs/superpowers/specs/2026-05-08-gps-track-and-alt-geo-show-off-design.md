# GPS Track Map + Altitude Geo Show-Off Variants

- **Date:** 2026-05-08
- **Status:** Approved
- **Branch:** TBD

## Summary

Add two new show-off variants to the existing variant system:
1. **GPS "TRACK"** (variant 5) — Real MapKit map with breadcrumb trail, heading indicator, and info overlay
2. **Altimeter "GEO ALT"** (variant 4) — Dual-source altitude dashboard combining GPS + barometric altitude with geo-location

## Integration

New variants added to the existing paged show-off system:
- `SOSensors.all` GPS entry: variants array gets `"TRACK"` appended (→ 6 variants)
- `SOSensors.all` Altimeter entry: variants array gets `"GEO ALT"` appended (→ 5 variants)
- `SOGPS` switch statement: case 5 → `GPSTrack(loc:)`
- `SOAlt` switch statement: case 4 → `AltGeoAlt(loc:env:)`

## Variant 1 — GPS TRACK

### Visual
Full-bleed `MKMapView` via `UIViewRepresentable`. User tracking mode follows heading. Red polyline traces accumulated GPS path. Red pulsing pin at current location. Heading cone rotates with `course`. Accuracy circle at current position radius = `horizontalAccuracy`.

Bottom glass sheet overlay (40% height, dismissable):
- LAT, LON, ALT, SPEED in 2-column grid
- H.ACC with color badge

### Data
- `LocationSensorManager`: latitude, longitude, altitude, speed, course, horizontalAccuracy, verticalAccuracy
- Path accumulates in `@State [CLLocation]`
- Filter: skip location if distance from last < 0.5m

### Behaviors
- Map tracks user with heading (`MKUserTrackingMode.followWithHeading`)
- User can pan; auto-recenters after 4s of inactivity
- Map type: `.hybrid` for visual appeal
- Polyline uses SO.gpsAccent (red) with glow shadow
- Accuracy overlay circle color: green < 10m, amber < 30m, red > 30m

### Files
- `GPSTrackMapView.swift` (UIViewRepresentable wrapper)
- Variant code inline in `ShowOffVariants_Motion.swift` alongside other GPS variants

## Variant 2 — ALT GEO ALT

### Visual
Hero: large GPS altitude (`+12.4 m`), 96pt rounded, cyan accent, glow. Below: side-by-side GPS vs barometric altitude columns. Accuracy section with horizontal/vertical accuracy color-coded. Geo-location coordinates in monospaced 6-decimal. Bottom: SOTickerBar with pressure, fix quality, trend.

### Data
- `LocationSensorManager`: altitude (hero), horizontalAccuracy, verticalAccuracy, latitude, longitude
- `MotionSensorManager`: relativeAltitude (barometric comparison), pressure
- Color coding for accuracy: green < 5m, yellow < 15m, red > 15m

### Behaviors
- All values update live via `@ObservedObject`
- Hero altitude animates smoothly
- Barometric delta shown as signed difference from GPS altitude

### Files
- Variant code inline in `ShowOffVariants_Environment.swift` alongside other Altimeter variants

## Changes Required

| File | Change |
|------|--------|
| `ShowOffMode.swift` | Update GPS variants to add "TRACK", Altimeter to add "GEO ALT" |
| `ShowOffVariants_Motion.swift` | Add `GPSTrack` view + GPS track case |
| `ShowOffVariants_Environment.swift` | Add `AltGeoAlt` view + switch case, needs `@EnvironmentObject var loc` |
| NEW: `GPSTrackMapView.swift` | UIViewRepresentable wrapping MKMapView with polyline + heading |

## Edge Cases

- **Location not authorized**: GPS track shows "Location Unavailable" placeholder card with SO style
- **No barometer on device**: Alt Geo variant falls back to showing only GPS altitude, baro column shows "N/A"
- **Stale data**: If no location update for 5s, map mode degrades gracefully (shows last known position)
- **Reduce motion**: Polyline uses simpler rendering, heading animation crossfades
