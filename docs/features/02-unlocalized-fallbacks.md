# Feature 02: Fix Unlocalized Raw Value Fallbacks

## Checklist

- [ ] Audit all sensor managers for hardcoded English strings
- [ ] Map all raw API values through LocalizationManager in views
- [ ] Add missing translation keys for edge cases
- [ ] Verify no English text appears in non-English languages
- [ ] Test with Thai, Chinese, Arabic RTL

## Details

**Files to Audit:**
- `Services/MotionSensorManager.swift` — `activityState`, `calMagAccuracy`
- `Services/SystemSensorManager.swift` — `batteryStateText`, `thermalStateText`, `orientationText`
- `Services/ConnectivitySensorManager.swift` — `bluetoothStateText`, `networkType`, `cellularCarrier`
- `Services/HealthSensorManager.swift` — `biologicalSex`, `bloodType`
- `Services/EnvironmentSensorManager.swift` — `audioSessionCategory`

**Current Issues:**
- `activity.unknown` shows raw key if not in translations
- `N/A` fallback in ConnectivitySensorManager not localized
- Compass directions fallback to English in HeadingDetailView

**Required Translation Keys:**
- `activity.unknown`
- `value.n/a` or `status.notavailable`
- All orientation strings
- All audio session category strings

## Testing
Build with Thai language, verify every sensor detail view shows Thai text only.
