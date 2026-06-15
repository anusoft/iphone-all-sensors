# 04 · App Privacy ("Nutrition Labels")

App Store Connect → App Privacy. This is what shows on your store page as the privacy summary.

**The truthful answer for All Sensors v1.0 is: "Data Not Collected."** The app reads sensors locally, displays them locally, and stores logger sessions in a local SQLite file inside the app's sandbox. Nothing is sent to a server. The only outbound network call is a *user-initiated* test ping to 1.1.1.1 (`URLSession` GET) when the user taps a "test connectivity" action in the Network sensor — and that returns a status code, not data.

## App Privacy form answers

### Step 1 — "Do you or your third-party partners collect data from this app?"

**Answer: No**

> "Data Not Collected" — the app does not collect any data from the user. All sensor readings are processed and stored on the device.

If Apple's wizard asks the qualifying questions to verify this:

| Question                                                                                              | Answer | Reason                                                                                       |
|-------------------------------------------------------------------------------------------------------|--------|----------------------------------------------------------------------------------------------|
| Does the app collect contact info (name, email, phone, address, other user contact info)?           | No     |                                                                                              |
| Does it collect health & fitness data?                                                               | No     | HealthKit data is *read* into the running app from the system store; the app does not store, transmit, or share it. Per Apple's guidance, system framework reads displayed in real time without persistence are not "collection". |
| Does it collect financial info?                                                                      | No     |                                                                                              |
| Does it collect location?                                                                            | No     | Location is read on-device for live display + optional logging into the local SQLite. Not transmitted. |
| Does it collect sensitive info?                                                                      | No     |                                                                                              |
| Does it collect contacts?                                                                            | No     |                                                                                              |
| Does it collect user content (photos, audio, customer support, gameplay, etc.)?                     | No     | Camera and microphone are introspected for *capabilities* — VU meter and lens enumeration. No frames or audio buffers are captured to disk. |
| Does it collect browsing/search history?                                                             | No     |                                                                                              |
| Does it collect identifiers (IDFA, user ID, device ID)?                                              | No     |                                                                                              |
| Does it collect purchases?                                                                           | No     | App is paid-once / free; no IAP.                                                              |
| Does it collect usage data, product interaction, advertising data, etc.?                            | No     | No analytics SDK, no telemetry.                                                               |
| Does it collect diagnostics (crash, performance, other)?                                             | No     | No crash reporter SDK.                                                                        |
| Does it collect any other data?                                                                      | No     |                                                                                              |

### Step 2 — Tracking

Q: "Do you or your third-party partners use data for tracking purposes?"
**Answer: No** — no advertising SDKs, no cross-app/cross-site tracking, no IDFA usage.

This means you do **not** need to display App Tracking Transparency (ATT) prompts.

## Important nuance: HealthKit + Logger sessions

The "Data Not Collected" answer is correct because of how Apple defines collection: data is "collected" when it leaves the device or is persisted by the developer in a way that's accessible to the developer.

- HealthKit readings flow through the iOS HealthKit store (managed by Apple). The app never copies them to its own files.
- Logger sessions ARE persisted — to the app's local sandbox SQLite (`Documents/Logging/`). This is "device storage" not "collection". You do not have to declare this on the privacy form, but [05-privacy-policy.md](05-privacy-policy.md) discloses it explicitly so users see it.

If at any point you add an analytics SDK, a crash reporter, a "send feedback" form that mails data, or a cloud sync feature, **you must update App Privacy** before that build ships. The penalty for a mismatched privacy label is rejection or removal.

> **Manifest ↔ listing status.** The store listing publishes **"Data Not
> Collected"**, and the checked-in `PrivacyInfo.xcprivacy` now uses an empty
> `NSPrivacyCollectedDataTypes` array to match that stance. If the app later adds
> analytics, cloud sync, server-side feedback, or HealthKit writes, update both
> this form and the manifest before shipping that build.

## Privacy Manifest (`PrivacyInfo.xcprivacy`)

iOS 17+ requires a Privacy Manifest if you call certain "required reason APIs" (file timestamps, system boot time, etc.). Add `PrivacyInfo.xcprivacy` to the app target with these declarations:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>C617.1</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>CA92.1</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>85F4.1</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array>
        <string>35F9.1</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

Reason codes used:
- `C617.1` — File timestamp displayed to user (logger session timestamps in browser)
- `CA92.1` — User defaults used solely for app's own configuration
- `85F4.1` — Display free disk space in the Disk sensor detail
- `35F9.1` — Display system uptime in the System Info screen

Add via Xcode: File → New → File → Resource → App Privacy file. Then paste the dict.
