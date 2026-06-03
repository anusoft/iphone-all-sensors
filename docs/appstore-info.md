# App Store Connect Submission Guide — All Sensors

> **Last Updated:** 2026-05-06
> **App:** All Sensors (com.1moby.iPhoneSensors)
> **Target:** iOS 17+ (iPhone & iPad)
> **Bundle ID:** com.1moby.iPhoneSensors

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [App Information](#2-app-information)
3. [Pricing & Availability](#3-pricing--availability)
4. [App Privacy](#4-app-privacy)
5. [Version Information (Per Release)](#5-version-information-per-release)
6. [Screenshots & App Previews](#6-screenshots--app-previews)
7. [Build Selection](#7-build-selection)
8. [App Review Information](#8-app-review-information)
9. [Age Rating](#9-age-rating)
10. [Export Compliance](#10-export-compliance)
11. [Content Rights](#11-content-rights)
12. [TestFlight Setup (Recommended)](#12-testflight-setup-recommended)
13. [Review Rejection Prevention](#13-review-rejection-prevention)
14. [Pre-Submission Checklist](#14-pre-submission-checklist)

---

## 1. Prerequisites

Before you can submit, ensure these are completed in Apple Developer:

| Requirement | Status | Notes |
|------------|--------|-------|
| Apple Developer Program membership | Required ($99/year) | Must be active, not expired |
| Paid Apps Agreement signed | Required | In Agreements, Tax, and Banking |
| Tax forms completed | Required | W-9 (US) or W-8BEN (international) |
| Banking information entered | Required | For receiving payments |
| App record created | Required | App Store Connect → My Apps → + |
| Xcode 15+ installed | Required | For building and archiving |
| Valid signing certificate | Required | Apple Development + Distribution |

---

## 2. App Information

**Location:** App Store Connect → My Apps → [All Sensors] → App Information

### 2.1 Basic Information

| Field | Required | Value / Instructions |
|-------|----------|---------------------|
| **Name** | Yes | `All Sensors` (max 30 chars) |
| **Subtitle** | Yes | `Monitor Every Sensor on Your iPhone` (max 30 chars) |
| **Bundle ID** | Auto | `com.1moby.iPhoneSensors` (set at creation, cannot change) |
| **SKU** | Yes | `ALLSENSORS001` (internal reference, not visible) |
| **Primary Language** | Yes | `English (U.S.)` |
| **Category** | Yes | **Primary:** Utilities<br>**Secondary:** Developer Tools |
| **Content Rights** | Yes | Does NOT contain third-party content |

### 2.2 App Icon

| Requirement | Details |
|------------|---------|
| Format | 1024×1024 PNG (no alpha/transparency in corners) |
| File | `Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| Status | ✅ Already in project |

### 2.3 App Information URL Fields

| Field | Required | Value |
|-------|----------|-------|
| **Support URL** | Yes | `https://github.com/1m0bY/iPhoneSensors/issues` |
| **Marketing URL** | Optional | `https://github.com/1m0bY/iPhoneSensors` |
| **Privacy Policy URL** | **YES** | Must be a live webpage. Use GitHub Pages to host `docs/privacy-policy.md` as HTML. Example: `https://1m0bY.github.io/iPhoneSensors/privacy` |

> **CRITICAL:** The privacy policy URL must be accessible and contain a real privacy policy. A broken link = automatic rejection.

---

## 3. Pricing & Availability

**Location:** App Store Connect → Pricing and Availability

| Field | Required | Recommended Value |
|-------|----------|------------------|
| **Price** | Yes | **Free** (`0.00 USD`) |
| **Availability** | Yes | All countries/regions (175 territories) |
| **Pre-Order** | Optional | No (submit for immediate release) |
| **Distribution** | Auto | App Store |

### Why Free?

- All sensor readouts must be free per App Store Review Guideline 4.10
- This app has no In-App Purchases or subscriptions
- Free removes payment friction and increases downloads

---

## 4. App Privacy

**Location:** App Store Connect → App Privacy

This is a **nutrition label** that Apple shows on your App Store page. It must accurately reflect ALL data collection and usage.

### 4.1 Data Types

For **All Sensors**, declare the following:

| Data Type | Linked to User | Used for Tracking | Reason |
|-----------|---------------|-------------------|--------|
| **Location (Precise)** | No | No | App functionality (GPS display) |
| **Health & Fitness** | No | No | App functionality (heart rate, steps) |
| **Diagnostics** | No | No | App functionality (device diagnostic tests) |
| **Other Data** | No | No | App functionality (sensor readings displayed locally) |

### 4.2 Important Notes

- **All data stays on device** — nothing is sent to external servers
- **No tracking** — no advertising identifiers, no analytics SDKs
- **No third-party data sharing**
- The privacy nutrition label should reflect: **"Data Not Linked to You"** for all categories

### 4.3 Privacy Policy URL

Must be a live, publicly accessible URL. Options:
1. **GitHub Pages** (free): Convert `docs/privacy-policy.md` to HTML and host
2. **Your own domain**
3. **Privacy policy generator** (iubenda, Termly, etc.)

Minimum required sections in privacy policy:
- What data is collected
- How data is used
- Data sharing (none for this app)
- User rights
- Contact information

---

## 5. Version Information (Per Release)

**Location:** App Store Connect → [App] → [Version] → Version Information

### 5.1 Required Metadata

| Field | Required | Max Length | Recommended Content |
|-------|----------|------------|-------------------|
| **Promotional Text** | Optional | 170 chars | "Turn your iPhone into a powerful sensor dashboard. Real-time charts, data export, and hardware diagnostics." |
| **Description** | **YES** | 4000 chars | See full description below |
| **Keywords** | **YES** | 100 chars | `sensor,diagnostic,accelerometer,gyroscope,magnetometer,gps,compass,barometer,logger,export` |
| **Support URL** | **YES** | — | Same as App Information |
| **Marketing URL** | Optional | — | Same as App Information |
| **What's New** | **YES** | 4000 chars | For v1.0: "Initial release with full sensor monitoring, real-time charts, data export, recording, and diagnostic mode." |

### 5.2 Full App Description (Template)

```
All Sensors gives you complete visibility into every sensor and hardware component on your iPhone. From motion sensors to environmental readings, system resources to connectivity status — see it all in one beautifully designed app.

KEY FEATURES:

📊 Real-Time Dashboard
• Monitor accelerometer, gyroscope, magnetometer, and device motion
• Track GPS location, altitude, and compass heading
• View barometric pressure, ambient light, and proximity sensor
• Check battery level, CPU usage, memory, and thermal state

📈 Live Charts
• Visualize sensor data with smooth real-time charts
• Pause and resume data collection
• Rolling 200-point buffer for continuous monitoring

💾 Data Export
• Export sensor readings as CSV or JSON
• Share via AirDrop, Messages, Mail, or Files
• Perfect for research, debugging, and analysis

🎙️ Sensor Recording
• Record sensor data at 10Hz for detailed analysis
• Manage multiple recording sessions
• Export recordings for offline analysis

🔍 Diagnostic Mode
• Run comprehensive hardware tests
• Verify all 12 sensor categories
• Get an overall device health score
• Generate and share diagnostic reports

🌍 12 Languages Supported
English, 中文, 日本語, 한국어, Español, Français, Deutsch, Português, العربية, Italiano, Русский, ไทย

PRIVACY FIRST:
All sensor data is processed locally on your device. Nothing is sent to external servers.

REQUIREMENTS:
• iOS 17.0 or later
• Compatible with iPhone and iPod touch
```

### 5.3 Build Selection

| Field | Required | Notes |
|-------|----------|-------|
| **Build** | **YES** | Select the uploaded build (must be "Ready to Submit") |
| **App Clip** | No | Not applicable |

---

## 6. Screenshots & App Previews

**Location:** App Store Connect → [Version] → Media Manager

### 6.1 Screenshot Requirements by Device

| Device | Size | Required | Files Available |
|--------|------|----------|----------------|
| **iPhone 6.7"** | 1290×2796 | Yes | `screenshots/02_dashboard_67.png` etc. |
| **iPhone 6.5"** | 1284×2778 | Yes | `screenshots/02_dashboard_65.png` etc. |
| **iPhone 5.5"** | 1242×2208 | Yes | `screenshots/02_dashboard_55.png` etc. |
| **iPad Pro 12.9"** | 2048×2732 | Yes (if supporting iPad) | `screenshots/ipad_01_dashboard_pro129.png` etc. |
| **iPad Pro 11"** | 1668×2388 | Optional | `screenshots/ipad_01_dashboard_pro11.png` etc. |
| **iPad 9th gen** | 1620×2160 | Optional | `screenshots/ipad_01_dashboard_ipad9.png` etc. |

### 6.2 Screenshot Upload Strategy

Upload **3–6 screenshots per device size**. Recommended order:

1. **Dashboard Overview** — All sensor categories visible
2. **Real-time Chart** — Accelerometer or gyroscope chart
3. **Diagnostic Mode** — Pass/fail test results
4. **Sensor Detail** — Single sensor with gauges
5. **System Info** — Battery, CPU, memory
6. **Settings/Languages** — Theme and language picker

### 6.3 App Preview Video (Optional but Recommended)

| Requirement | Spec |
|------------|------|
| Length | 15–30 seconds |
| Format | H.264 or Apple ProRes 422 (HQ) |
| Resolution | Match screenshot sizes |
| Audio | Optional (no copyrighted music) |
| Content | Show app in use, no hands/overlays |

---

## 7. Build Selection

**Location:** App Store Connect → [Version] → Build

### 7.1 Uploading Your Build

1. In Xcode: Product → Archive
2. Window → Organizer → Select archive → Distribute App
3. Choose **App Store Connect** → Upload
4. Wait for processing (5–30 minutes)

### 7.2 Build Status

| Status | Meaning |
|--------|---------|
| **Processing** | Apple is processing the binary |
| **Ready to Submit** | ✅ Select this build in App Store Connect |
| **Invalid Binary** | ❌ Fix issues and re-upload |
| **Missing Compliance** | ❌ Answer export compliance questions |

---

## 8. App Review Information

**Location:** App Store Connect → [Version] → App Review Information

### 8.1 Required Fields

| Field | Required | Value for All Sensors |
|-------|----------|----------------------|
| **Sign-in required?** | Yes | **No** |
| **Contact Information** | Yes | Your name, phone, email |
| **Demo Account** | Only if sign-in | **Not applicable** |
| **Demo Account Notes** | Only if sign-in | **Not applicable** |

### 8.2 Notes for Reviewer (CRITICAL — Use this to prevent rejection)

Paste this in the **"Notes"** field. This proactively answers reviewer's questions:

```
Thank you for reviewing All Sensors!

WHAT THIS APP DOES:
All Sensors is a utility app that displays real-time data from hardware sensors available on iOS devices. It provides visualization, recording, export, and diagnostic capabilities for developers, researchers, and users who want to monitor their device hardware.

UNIQUE UTILITY (Section 4.2 Compliance):
Unlike basic sensor viewers, this app includes:
• Real-time Swift Charts with play/pause controls
• CSV/JSON data export for research and analysis
• 10Hz sensor recording with session management
• Comprehensive 12-sensor diagnostic test suite with health score
• 12-language localization
• App Intents for Siri shortcuts

PERMISSIONS EXPLAINED:
• Location: To display GPS coordinates, altitude, and compass heading
• Motion: To display accelerometer, gyroscope, and device motion data
• Camera: To display camera capabilities and information
• Microphone: To display audio input information
• Bluetooth: To discover and display nearby Bluetooth devices
• Health: To display heart rate and step count (optional, currently disabled in code)

All permissions are requested individually through an onboarding flow. Users can skip any permission.

HEALTHKIT NOTE:
HealthKit capability is implemented in code but currently disabled (healthKitEnabled = false in SensorManager) because it requires an Apple Developer account with HealthKit entitlement enabled. The code is present for future activation but Health data will not appear unless explicitly enabled by the developer.

PRIVACY:
All sensor data is processed locally on the device. No data is sent to external servers. The in-app privacy policy is accessible from Settings.

TESTING NOTES:
• Most sensors require a physical device (simulator shows limited/mock data)
• The app gracefully handles missing sensors on older devices
• Sensors stop updating when the app enters background to preserve battery
```

### 8.3 Attachment (Optional)

You can attach:
- A video demonstrating the app
- Screenshots showing specific features
- Document explaining complex functionality

For All Sensors, a 30-second demo video is recommended but not required.

---

## 9. Age Rating

**Location:** App Store Connect → [App] → App Information → Age Rating

### 9.1 Age Rating Quiz

Answer these questions for All Sensors:

| Question | Answer |
|----------|--------|
| Unrestricted Web Access | **No** |
| Gambling and Contests | **No** |
| Gambling | **No** |
| Contests | **No** |
| Horror/Fear Themes | **No** |
| Prolonged Graphic or Sadistic Realistic Violence | **No** |
| Graphic Sexual Content and Nudity | **No** |
| Frequent/Intense Mature/Suggestive Themes | **No** |
| Frequent/Intense Alcohol, Tobacco, or Drug Use | **No** |
| Frequent/Intense Profanity or Crude Humor | **No** |
| Frequent/Intense Simulated Gambling | **No** |
| Frequent/Intense Horror/Fear Themes | **No** |
| Frequent/Intense Realistic Violence | **No** |
| Frequent/Intense Cartoon or Fantasy Violence | **No** |
| Medical/Treatment Information | **No** (sensor data is raw, not medical advice) |

### 9.2 Expected Result

**Age Rating:** 4+ (Everyone)

> ⚠️ **Important:** Do NOT claim medical/treatment information unless the app provides actual medical advice. Raw sensor data is NOT medical information.

---

## 10. Export Compliance

**Location:** Xcode Organizer during upload OR App Store Connect after upload

### 10.1 Encryption Declaration

For All Sensors, answer:

| Question | Answer |
|----------|--------|
| Does your app use encryption? | **No** |
| Does your app implement any encryption algorithms? | **No** |
| Does your app use SSL/TLS for network connections? | **No** (no network connections) |
| Does your app use standard Apple encryption (HTTPS)? | **No** (no network calls) |

### 10.2 Result

**No export compliance documentation required.** This app:
- Does not use encryption
- Does not make network requests
- Does not use HTTPS/SSL
- All data is processed locally

---

## 11. Content Rights

**Location:** App Store Connect → [App] → App Information → Content Rights

| Field | Answer |
|-------|--------|
| Does this app contain, display, or access third-party content? | **No** |
| Do you have all necessary rights to the content? | **Yes** (all original content) |

This app contains only:
- Original code
- System UI frameworks (SwiftUI)
- System icons (SF Symbols)
- No third-party images, text, or media

---

## 12. TestFlight Setup (Recommended)

Before App Store submission, distribute via TestFlight to catch issues.

### 12.1 Internal Testing

1. App Store Connect → TestFlight → Internal Testing
2. Add up to 100 team members
3. Select build and add testers
4. Testers receive email invitation

### 12.2 External Testing

1. App Store Connect → TestFlight → External Testing
2. Create a group (e.g., "Beta Testers")
3. Add up to 10,000 testers via email or public link
4. Submit for Beta App Review (lighter review)
5. Once approved, testers can install

### 12.3 Beta App Review Notes

Use the same notes as App Review. Beta review is typically faster (24–48 hours).

---

## 13. Review Rejection Prevention

This section is specific to **All Sensors** and how to avoid the most common rejections.

### 13.1 Section 4.2 — Minimum Functionality

**Risk:** Medium-High (sensor apps are common)

**Prevention:**
- ✅ App has unique features beyond "displaying numbers"
- ✅ Diagnostic mode with pass/fail tests
- ✅ Real-time charts with play/pause
- ✅ Data export (CSV/JSON)
- ✅ Sensor recording at 10Hz
- ✅ 12-language support

**If rejected:** Appeal with emphasis on diagnostic utility, data export, and recording features. Position as "Device Diagnostic & Sensor Logger" not "Sensor Viewer."

### 13.2 Section 4.3(b) — Spam / Saturated Category

**Risk:** Medium

**Prevention:**
- ✅ Unique positioning: "Device Monitor & Diagnostic"
- ✅ Not a clone of existing apps
- ✅ Unique UI design (glass cards, dark/light themes)
- ✅ 12 languages (most competitors are English-only)

### 13.3 Section 5.1.1 — Privacy

**Risk:** Low

**Prevention:**
- ✅ All 7 purpose strings in Info.plist
- ✅ In-app privacy policy linked
- ✅ Privacy nutrition label accurate
- ✅ No data leaves device
- ✅ No analytics/tracking SDKs

### 13.4 Section 5.1.1(ii) — Purpose Strings Missing

**Risk:** Very Low (already handled)

**Verified purpose strings in Info.plist:**
- `NSLocationWhenInUseUsageDescription` ✅
- `NSLocationAlwaysAndWhenInUseUsageDescription` ✅
- `NSMotionUsageDescription` ✅
- `NSCameraUsageDescription` ✅
- `NSMicrophoneUsageDescription` ✅
- `NSBluetoothAlwaysUsageDescription` ✅
- `NSBluetoothPeripheralUsageDescription` ✅

### 13.5 Section 2.3 — Accurate Metadata

**Risk:** Low

**Prevention:**
- ✅ Screenshots show actual app UI
- ✅ Description matches actual features
- ✅ No exaggerated claims
- ✅ Keywords relevant and not spammy

### 13.6 Section 2.1 — Performance

**Risk:** Low

**Prevention:**
- ✅ App tested on physical device
- ✅ No crashes on launch
- ✅ Graceful handling of missing sensors
- ✅ Background battery usage reasonable

### 13.7 Section 4.10 — Monetization

**Risk:** Very Low

**Prevention:**
- ✅ All sensors are free
- ✅ No paywalls on basic functionality
- ✅ No ads
- ✅ No In-App Purchases

---

## 14. Pre-Submission Checklist

### 14.1 Code & Build

- [ ] App builds without errors or warnings
- [ ] Archive created successfully in Xcode
- [ ] Build uploaded to App Store Connect
- [ ] Build status shows "Ready to Submit"
- [ ] Build tested on physical iPhone device
- [ ] Build tested on physical iPad device (if supporting iPad)
- [ ] Info.plist has all required purpose strings
- [ ] App icon is 1024×1024 PNG
- [ ] Launch screen displays correctly

### 14.2 App Store Connect Metadata

- [ ] App name entered (max 30 chars)
- [ ] Subtitle entered (max 30 chars)
- [ ] Description written (max 4000 chars)
- [ ] Keywords entered (max 100 chars)
- [ ] Support URL is live and accessible
- [ ] Privacy Policy URL is live and accessible
- [ ] Category selected (Primary: Utilities)
- [ ] Age rating completed (expected: 4+)
- [ ] Content rights declared (No third-party content)
- [ ] App privacy nutrition label completed

### 14.3 Screenshots

- [ ] iPhone 6.7" screenshots uploaded (3–6 images)
- [ ] iPhone 6.5" screenshots uploaded (3–6 images)
- [ ] iPhone 5.5" screenshots uploaded (3–6 images)
- [ ] iPad Pro 12.9" screenshots uploaded (if supporting iPad)
- [ ] Screenshots show actual app UI with real data
- [ ] No status bar shows "Carrier" or debug info
- [ ] Screenshots are in correct dimensions

### 14.4 App Review Information

- [ ] Contact information filled in
- [ ] "Sign-in required" set to No
- [ ] Detailed notes for reviewer pasted
- [ ] Demo account section left empty (not applicable)
- [ ] Attachment uploaded (optional: demo video)

### 14.5 Build & Version

- [ ] Correct build selected
- [ ] Version number matches (e.g., 1.0)
- [ ] "What's New" text entered
- [ ] Copyright field filled (e.g., "© 2026 Your Name")

### 14.6 Compliance

- [ ] Export compliance answered (No encryption used)
- [ ] No gambling/contests declared
- [ ] Made for Kids: No

### 14.7 Final Steps

- [ ] All required fields show green checkmarks
- [ ] "Submit for Review" button is active
- [ ] Read final confirmation dialog carefully
- [ ] Submit and wait for review (typically 24–48 hours)

---

## Appendix A: Quick Reference — Field Limits

| Field | Max Length | Our Content Length |
|-------|-----------|-------------------|
| App Name | 30 chars | 11 (`All Sensors`) ✅ |
| Subtitle | 30 chars | 37 (`Monitor Every Sensor on Your iPhone`) ⚠️ TRUNCATE |
| Description | 4000 chars | ~1800 ✅ |
| Keywords | 100 chars | ~95 ✅ |
| Promotional Text | 170 chars | ~120 ✅ |
| What's New | 4000 chars | ~150 ✅ |

> ⚠️ **Subtitle is too long!** Must be 30 characters or less.
> **Recommended:** `Monitor Device Sensors` (22 chars)

---

## Appendix B: Common Review Timelines

| Stage | Typical Duration |
|-------|-----------------|
| Waiting for Review | 0–24 hours |
| In Review | 12–48 hours |
| Ready for Sale | Immediate after approval |
| **Total** | **1–3 days** |

Peak times (September/October after iOS release) can take 3–5 days.

---

## Appendix C: Post-Approval Checklist

After your app is approved:

- [ ] Verify App Store page looks correct
- [ ] Test download on a device not used for development
- [ ] Check that all screenshots display correctly
- [ ] Verify privacy policy link works from App Store page
- [ ] Monitor reviews and respond to feedback
- [ ] Set up App Store Connect analytics
- [ ] Consider App Store Optimization (ASO) improvements

---

*Document Version: 1.0*
*Last Updated: 2026-05-06*
*For: All Sensors iOS App*
