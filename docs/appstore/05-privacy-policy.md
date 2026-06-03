# 05 · Privacy Policy

Host this at the URL you give Apple as your **Privacy Policy URL** in [01](01-app-information.md). Plain HTML or markdown rendering is fine; just keep it reachable, HTTPS, and free of paywalls or redirects.

Replace `[FILL: …]` with your real values before publishing.

---

# Privacy Policy — All Sensors

**Effective date:** [FILL: e.g., 2026-05-15]
**Developer:** [FILL: legal entity name — same as Seller / Developer Name in App Store]
**Contact:** [FILL: privacy@yourdomain.com]

## TL;DR

All Sensors does not collect, transmit, or share any of your data. Every sensor reading is processed and stored on your device. We have no servers, no analytics, no advertising SDKs, no crash reporters. The only outbound network call is a connectivity test you initiate yourself.

## What the app does

All Sensors reads data from your iPhone or iPad's built-in sensors and APIs — accelerometer, gyroscope, magnetometer, GPS, barometer, motion activity classifier, pedometer, altimeter, battery monitor, thermal state monitor, processor info, memory monitor, disk usage, Wi-Fi/cellular path info, Bluetooth scanner, camera capability info, microphone audio levels, ambient light estimate, proximity sensor, screen brightness, and the torch — and shows them to you in real time on your device.

Optionally, you can record a logging session: pick which sensors to capture, set a sample rate, tap record. Sessions are saved to your device's app-private storage (sandbox) and you can browse, view, share, or delete them at any time.

## What we collect

**Nothing.**

The app does not have a backend service. We do not collect your name, email, phone number, location, sensor readings, health data, device identifiers, IP address, advertising identifier, or anything else. We do not have a database that stores your data on a remote server.

## What stays on your device

The following data is created and stored entirely within the app's sandbox on your device:

- **Logger sessions** — sensor recordings you intentionally start, stored as a SQLite database under your app's private `Documents/Logging/` folder. You can browse, share, export (CSV/JSON), or delete these from inside the app.
- **App preferences** — small UserDefaults entries: which sensors are enabled in the logger, your selected theme, language, whether you've completed the permission onboarding flow.
- **Cached HealthKit reads** — when you view the Health tab, the app reads from HealthKit into RAM to render charts. Nothing is persisted.

When you delete the app, iOS deletes everything in its sandbox. There is no copy on a server because we have no server.

## Permissions we request, and why

| Permission                  | What it lets the app do                                                                          | What we don't do with it                                |
|-----------------------------|--------------------------------------------------------------------------------------------------|---------------------------------------------------------|
| **Location (When In Use)**  | Display your GPS coordinates, altitude, speed, course, and compass heading on the GPS, Compass, and Show-Off Mode screens. | We do not log location anywhere outside your device, share it, or send it to ad networks. |
| **Motion & Fitness**        | Read accelerometer, gyroscope, magnetometer, device-motion fusion, pedometer, and motion activity classifier (`CMMotionManager`, `CMPedometer`, `CMMotionActivityManager`). | We do not transmit motion data off device. |
| **Camera**                  | Enumerate available cameras and zoom levels for the Camera sensor view, and toggle the torch (flashlight). | We do not capture photos, video frames, or save anything from the camera. |
| **Microphone**              | Read audio input device list and live audio levels (VU meter) for the Camera → Audio variant.      | We do not record audio to disk or transmit it. |
| **Bluetooth**               | Scan for nearby Bluetooth peripherals to display them in the Bluetooth sensor view (`CBCentralManager`). | We do not connect, pair, or transmit data. |
| **Local Network**           | Read your Wi-Fi network type and a basic path snapshot from `NWPathMonitor` to display in the Network sensor view. | We do not scan your network or send data over it. |
| **HealthKit (read)**        | Read steps, heart rate, active energy, distance, and sleep samples to display on the Health tab. | We do not write back unless you explicitly opt in. |
| **HealthKit (write)**       | If you opt in, the app can write workout sessions you create via Logger. Off by default.        | We do not write anything without your explicit action. |
| **Face ID** (capability info) | Display whether Face ID is available — does NOT authenticate.                                   | We never store biometric templates; iOS handles all biometric data. |

You can change every one of these at any time in iOS Settings → Privacy & Security → [permission] → All Sensors.

## Network usage

The app makes **no** outbound network requests as part of normal use. There are two exceptions, both initiated by you:

1. **Connectivity test ping.** When you open the Network sensor's "Throughput" variant and tap "Run Test", the app sends a single HTTPS request to `https://1.1.1.1/` and reads the round-trip time. That's all the test does. The response status code is shown to you and discarded.
2. **Outbound traffic from system frameworks.** Apple's frameworks may perform their own background activity (e.g., HealthKit syncing across your devices). That's iOS, not the app, and you control it from iOS Settings.

The app **never**:
- Phones home with telemetry or analytics.
- Loads ads.
- Communicates with any server we operate (we do not operate any).

## Children

The app is not directed at children under 13. We do not knowingly collect any data — including from anyone under 13 — because we do not collect data at all.

## How long we keep data

We don't keep any data, because we don't collect any. Locally stored data (logger sessions, preferences) lives on your device until you delete it or uninstall the app.

## Sharing

We do not share data with anyone. There is no data to share.

## Sale or "tracking" of personal information

We do not sell data. We do not use, allow, or include any third-party advertising or analytics SDKs. We do not track users for advertising purposes across apps or websites — therefore the iOS App Tracking Transparency prompt is not displayed.

## Your rights

Because we don't collect anything, there's nothing to access, correct, or delete from a server. Any local data lives on your device under your control:

- **View / export:** Logger → Sessions, swipe a session → Export
- **Delete a single session:** Logger → Sessions, swipe → Delete
- **Delete all data:** Delete the app from your device. iOS removes the sandbox.

If you have a question, write to [FILL: privacy@yourdomain.com] and we'll respond within 30 days.

## Changes to this policy

If we materially change how the app handles data — for example, by adding a backend service, an analytics SDK, or a sync feature — we will update this policy and bump the effective date at the top, **before** any such change ships. Material changes will be summarized in the version's "What's New" notes.

## Jurisdiction & legal basis

This policy is written for users worldwide. To the extent GDPR (EU/UK), CCPA (California), LGPD (Brazil), PIPL (China), or similar laws apply: the legal basis for any local processing is your consent, given by installing and using the app, and the processing is necessary to provide the functionality you've requested. The lawful basis for the optional connectivity test is your express action of running it.

## Contact

[FILL: legal entity name]
[FILL: postal address — required by some jurisdictions, e.g., for GDPR]
Email: [FILL: privacy@yourdomain.com]

---

*If anything in this policy is unclear or you spot something that doesn't match how the app behaves, please email — we'd like to know.*
