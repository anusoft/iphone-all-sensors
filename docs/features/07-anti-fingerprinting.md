# Feature 07: Anti-Fingerprinting & Data Siloing

## Goal
Prove transparently that high-entropy hardware data never leaves the local device environment, preempting reviewer suspicion of stealth fingerprinting.

## App Store Compliance Justification
Prevents rejection under anti-fingerprinting policies. The app explicitly collects high-entropy signals (CPU cores, battery state, thermal limits) which are the exact vectors used by illicit ad-tech SDKs.

## Requirements

### Core Functionality
- [ ] Add "Data Privacy" section in Settings with explicit statement
- [ ] Display a clear message: "All sensor data is processed locally on your device. No data is transmitted to external servers."
- [ ] No outgoing network requests except for explicit user-initiated exports/shares
- [ ] Do NOT implement App Tracking Transparency (ATT) prompt
- [ ] Add technical addendum to App Store Connect review notes

### UI/UX
- [ ] Settings sheet includes "Data Privacy" card with:
  - Local processing icon/checkmark
  - "No external servers" statement
  - "No analytics or tracking" statement
  - "No advertising identifiers" statement
- [ ] Each sensor detail view shows a small "🔒 Local Only" badge

### Technical Details
- Audit all network entitlements in the app
- Ensure no analytics SDKs, crash reporters, or third-party libraries make network calls
- If crash reporting is needed, use anonymous, stripped data with explicit disclosure
- Review notes must contain: "This application reads hardware parameters strictly for local, on-device diagnostic display. No heuristic data, combinatorial device signals, or fingerprinting identifiers are generated, hashed, persisted, or transmitted. All data remains siloed within the application's sandbox."

## Files to Modify
- `iPhoneSensors/Views/Components/SettingsSheet.swift` (add Data Privacy section)
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)
- `docs/appstore-info.md` (update review notes)

## Localization Keys Needed
- `privacy.dataPrivacy`
- `privacy.localProcessing`
- `privacy.noExternalServers`
- `privacy.noAnalytics`
- `privacy.noTracking`
- `privacy.localOnlyBadge`

## Acceptance Criteria
- [ ] Settings shows clear Data Privacy section
- [ ] No ATT prompt is implemented
- [ ] No unauthorized network calls in code
- [ ] Review notes contain anti-fingerprinting technical addendum
