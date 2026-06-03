# Feature 09: Thai PDPA Compliance (Consent + Delete My Data + Audit Trail)

## Goal
Implement PDPA-specific compliance mechanisms for Thai users: explicit consent architecture, automated data deletion, and immutable consent audit trails.

## App Store Compliance Justification
Apple Guidelines 5.1.1 and 5.1.2 require compliance with local privacy laws. Thai PDPA carries fines up to THB 5 million per offense.

## Requirements

### Core Functionality
- [ ] Add initial consent banner with "Accept All" and "Reject All" buttons of equal prominence
- [ ] "Reject All" must be fully functional (disable non-essential data collection)
- [ ] Add "Delete My Data" button in Settings
- [ ] Delete feature must programmatically purge:
  - All exported files in Documents directory
  - All recording session data
  - All alarm history
  - All signal map data
  - All UserDefaults except language/theme (or reset those too if user requests)
- [ ] Consent audit trail: timestamp the exact millisecond user completes 7-step onboarding
- [ ] User can view consent history in Settings
- [ ] User can modify consent preferences dynamically

### UI/UX
- [ ] Consent banner appears on first launch (before or alongside permission onboarding)
- [ ] "Accept All" and "Reject All" buttons same size, same visual weight
- [ ] Settings → Privacy → "Delete My Data" with confirmation dialog
- [ ] Settings → Privacy → "View Consent History" showing timestamps
- [ ] Settings → Privacy → "Manage Consent Preferences" with toggles

### Technical Details
- Store consent timestamp in UserDefaults with key `consentGivenAt`
- Store granular consent choices: `consentCrashAnalytics`, `consentSensorRecording`, etc.
- "Delete My Data" must complete within 90 days (immediate is preferred)
- Audit trail should be human-readable date + Unix timestamp
- If user rejects all, still allow app to function with minimal data collection

## Files to Modify
- `iPhoneSensors/Views/Components/PermissionRequestView.swift` (add consent step)
- `iPhoneSensors/Views/Components/SettingsSheet.swift` (add privacy section)
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)

## Localization Keys Needed
- `consent.title`
- `consent.description`
- `consent.acceptAll`
- `consent.rejectAll`
- `privacy.deleteMyData`
- `privacy.deleteMyDataConfirm`
- `privacy.deleteMyDataSuccess`
- `privacy.consentHistory`
- `privacy.consentGivenAt`
- `privacy.manageConsent`

## Acceptance Criteria
- [ ] Consent banner shows on first launch with equal buttons
- [ ] Reject All disables non-essential features gracefully
- [ ] Delete My Data purges all user-generated content
- [ ] Consent history shows exact timestamp
- [ ] User can modify consent preferences later
