# Feature 05: HealthKit Visible by Default + Medical Disclaimer

## Goal
Ensure HealthKit integration is a primary, visible feature — not optional or hidden — with a mandatory medical disclaimer to avoid rejection under Guidelines 2.5.1 and 1.4.1.

## App Store Compliance Justification
Prevents rejection for dormant/hidden APIs (Guideline 2.5.1) and misclassification as a medical device (Guideline 1.4.1). Medical disclaimer absolves Apple of medical liability.

## Requirements

### Core Functionality
- [ ] Health tab must be visible immediately upon launch (not conditional, not hidden)
- [ ] Remove any toggle or setting that hides/disables the Health tab
- [ ] Add mandatory medical disclaimer interstitial on first launch BEFORE Health tab access
- [ ] Disclaimer is non-dismissible without explicit acknowledgment
- [ ] Disclaimer text: "This application is for informational and educational purposes only. It is not intended to diagnose, treat, cure, or prevent any disease. Consult a licensed physician before making any medical decisions based on the data presented."
- [ ] User must tap "I Understand and Agree" to proceed
- [ ] Onboarding flow presents HealthKit permission dialog directly (no skip)
- [ ] Health data display uses sanitized terminology (no "patient", "vital signs", "diagnosis")

### UI/UX
- [ ] Medical disclaimer modal with scrollable text
- [ ] Acknowledgment checkbox + Continue button (disabled until checked)
- [ ] Health tab icon visible in tab bar from app launch
- [ ] Health detail view shows available metrics (heart rate, steps, etc.)
- [ ] Settings contains "View Medical Disclaimer Again" option

### Technical Details
- Store disclaimer acknowledgment in UserDefaults (`medicalDisclaimerAccepted`)
- HealthKit permission request happens during onboarding, not lazily
- Metadata update: App Store description must mention Health integration
- Review notes must state: "This application integrates with the Health app to provide physiological context alongside environmental sensor data."

## Files to Modify
- `iPhoneSensors/Views/HealthView.swift`
- `iPhoneSensors/Views/Components/PermissionRequestView.swift` (add Health step)
- `iPhoneSensors/Services/HealthSensorManager.swift`
- `iPhoneSensors/Services/LocalizationManager.swift` (new keys)
- `docs/app-store-metadata.md` (update description)
- `docs/appstore-info.md` (update review notes)

## Localization Keys Needed
- `health.disclaimer.title`
- `health.disclaimer.text`
- `health.disclaimer.checkbox`
- `health.disclaimer.agree`
- `health.tabTitle`
- `health.noData`
- `health.steps`
- `health.heartRate`

## Acceptance Criteria
- [ ] Health tab visible on first app launch
- [ ] Medical disclaimer shown before any HealthKit access
- [ ] User cannot bypass disclaimer without agreeing
- [ ] HealthKit permission requested during onboarding
- [ ] No clinical terminology in UI
