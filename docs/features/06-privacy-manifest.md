# Feature 06: PrivacyInfo.xcprivacy Manifest

## Goal
Create a properly formatted `PrivacyInfo.xcprivacy` manifest that maps restricted API calls to Apple's rigidly defined alphanumeric reason codes to prevent automated binary rejection (ITMS-91053).

## App Store Compliance Justification
Mandatory for iOS 17+ submissions. Without this manifest, the binary will be automatically rejected by App Store Connect's static analysis.

## Requirements

### Core Functionality
- [ ] Create `PrivacyInfo.xcprivacy` at project root
- [ ] Include `NSPrivacyAccessedAPITypes` array with all required API categories
- [ ] Map each API category to exact alphanumeric reason code

### Required API Mappings

| API Category | Framework Invoked | Required Reason Code | Justification |
|-------------|-------------------|---------------------|---------------|
| `NSPrivacyAccessedAPICategorySystemBootTime` | `ProcessInfo.systemUptime`, `mach_absolute_time()` | `35F9.1` | Converting relative hardware sensor timestamps to absolute timestamps for 10Hz recording engine and Swift Charts, strictly without tracking user across reboots |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `FileManager.systemFreeSize`, `statvfs` | `E174.1` | Check available volume capacity before and during prolonged 10Hz sensor recording to prevent storage exhaustion and crashes |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `FileManager.attributesOfItem`, `creationDate` | `C617.1` | Display creation/modification metadata of exported CSV/JSON files in recording list |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `UserDefaults` | `CA92.1` | Persist user-selected language, theme, and dashboard layout preferences |

### Additional Considerations
- [ ] If custom keyboard or auto-completion is added, declare `NSPrivacyAccessedAPICategoryActiveKeyboards`
- [ ] Add `NSPrivacyCollectedDataTypes` section describing what data is collected
- [ ] Add `NSPrivacyTracking` = false (app does not track users)
- [ ] Add `NSPrivacyTrackingDomains` = empty array

## Files to Create
- `iPhoneSensors/PrivacyInfo.xcprivacy`

## Files to Modify
- Xcode project to include the privacy manifest in the bundle

## Acceptance Criteria
- [ ] Privacy manifest contains all 4 required API categories
- [ ] Each category uses exact alphanumeric reason code (no custom text)
- [ ] Manifest is included in app bundle
- [ ] `NSPrivacyTracking` is set to false
