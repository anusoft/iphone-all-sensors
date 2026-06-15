# 07 · App Review Information

App Store Connect → App Store → Version → "App Review Information". This is the single most important page for *not* getting rejected on a vague reason. Reviewers spend ~3–7 minutes per app; if the path to value is hidden, they reject for "not enough functionality" or "spam".

## Sign-in required

**No.** All Sensors does not require an account. Reviewer can use everything.

(Set the "Sign-in required" toggle to **Off**. Leave demo username / password fields blank.)

## Contact information (the human Apple emails if there's a problem)

| Field        | Value                              |
|--------------|------------------------------------|
| First name   | `Anu`                              |
| Last name    | `Anu`                              |
| Phone number | `+66819188052`                     |
| Email        | `anu@1moby.com` |

Apple-facing only (reviewers email this — **not** shown publicly). The public/app contact is
`contact@1moby.com`; this Apple contact is `anu@1moby.com`. It must be a real, monitored email —
Apple sends the rejection or "we have a question" message here. Watch it for 5–7 days after submission.

## Notes for the reviewer (paste into "Notes")

```
Thanks for reviewing All Sensors!

This app is a sensor visualization utility — it reads from device sensors and displays them in real time. There is no account, no sign-in, no in-app purchase, no ads, no remote backend, and no analytics SDK. Everything runs locally.

To see the headline feature in 30 seconds:

1. Launch the app — Dashboard appears with all 21 sensors grouped (Motion, Location, Environment, System, Connectivity, Camera).
2. Tap any sensor card (e.g. "Accelerometer", "GPS Location", or "Battery"). You'll land on its detail screen with charts and live values.
3. Tap the gradient banner labeled "Show-Off Mode" at the top of the detail screen. The sensor takes over fullscreen as a theatrical visualization.
4. In Show-Off Mode: swipe horizontally to switch sensors, swipe vertically to cycle the variant within a sensor, tap the grid icon (top-right) to jump to any of the 21 sensors. Tap X (top-left) to exit.

Other features worth noting:

• Logger tab (record icon, last tab): records sensor samples to a local SQLite, exports to CSV/JSON via the share sheet. Sessions live entirely on device under the app's sandbox.
• Health tab: reads from HealthKit (if granted) for vitals, activity, body measurements, and profile values shown in the Health tab. Read-only; the app does not write to HealthKit.
• Siri Shortcuts: "Get Sensor Reading", "Start Sensor Recording", "Stop Sensor Recording", "Export Sensor Data" are wired as App Intents.

Permissions:
The app requests Location, Motion, Camera, Microphone, Bluetooth, Local Network, and HealthKit (read). Each permission is gated to the screens that need it. The app continues to function even if a permission is denied — that sensor's detail just shows "Unavailable" with a deep-link to iOS Settings.

Network:
The app makes ZERO outbound network requests in normal use. The Network sensor's "Throughput" variant has a button to ping 1.1.1.1 (Cloudflare); that is user-initiated, returns a status code, and is not logged or transmitted further.

Why this isn't another sensor-app clone:
Show-Off Mode contains 74 unique full-screen visualizations across the 21 sensors — flight HUDs, compass roses, gravity wells, oscilloscopes, fuel gauges, lighthouses, etc. — designed as a single visual system. We could not find another sensor app on the store with a comparable presentation layer.

If anything is unclear or you'd like a video walkthrough, please email anu@1moby.com — I'll send you a 60-second screen recording immediately.

Thanks again,
Anu
```

## Attachments (optional but recommended)

Apple lets you attach up to 5 files (≤30 MB each) to the review notes. Recommended attachments:

1. **`walkthrough.mov`** — a 30–60 second screen recording on iPhone showing: dashboard → tap Accelerometer → tap Show-Off banner → swipe through 3 variants → exit. Capture in QuickTime or Xcode (Window → Devices → Take Screenshot/Screen Recording). Drops rejection rate from "they didn't see it" issues by ~50%.
2. **`logger-walkthrough.mov`** — 30 seconds: Logger tab → start session → walk → stop → export → AirDrop. Demonstrates that the export feature works.

Don't attach the privacy policy as PDF — Apple wants it at a public URL ([01](01-app-information.md)).

## Demo account fields (leave blank)

You don't need a demo account. Toggle "Sign-in required" to **Off**.

If Apple insists on credentials anyway (it sometimes does for regulated categories — Health, Finance), you can submit:

| Field    | Value          |
|----------|----------------|
| Username | `reviewer`     |
| Password | `reviewer-2026`|

…but only if the form refuses to save without them. The app does not actually accept these.

## Common rejection reasons we proactively neutralize in the notes

| Reason                              | Our preemption                                               |
|-------------------------------------|--------------------------------------------------------------|
| "Insufficient functionality"        | Notes link the reviewer to Show-Off Mode in 3 taps.          |
| "App appears to be a spam clone"    | Notes name a specific differentiator (74 visualizations).    |
| "Privacy policy doesn't match app"  | Privacy is "Data Not Collected" and the privacy policy says exactly that — they match. |
| "Crashes when permission denied"    | Notes explicitly state graceful denial behavior.             |
| "Bait-and-switch / hidden paywall"  | Notes state no IAP / no ads / no backend.                    |
| "Doesn't follow HIG"                | UI uses standard SF Pro, system materials, default tab bar.  |

## After submission

1. Apple sends "Waiting for Review" → "In Review" (typically 24–48 hours later) → "Approved" / "Rejected".
2. If rejected: read the message in Resolution Center. Most rejections are easy fixes. Reply with the notes from this packet, point to the specific paragraph that addresses their concern.
3. Approval → release. You can choose **Manually release** to publish on a specific date, or **Automatic** to go live immediately.
