# 06 · Support Page

Host this content at the URL you give Apple as your **Support URL** in [01](01-app-information.md). Reviewers and users both visit this. A support page that's clearly written with real FAQs and a real contact channel signals legitimacy hard.

Replace `[FILL: …]` before publishing.

---

# All Sensors — Support

Last updated: [FILL: 2026-05-15]
App version: 1.0
Maintainer: [FILL: legal entity / your name]

## Quick links

- [Contact](#contact)
- [Permissions troubleshooting](#permissions)
- [Show-Off Mode](#show-off-mode)
- [Logger](#logger)
- [HealthKit](#healthkit)
- [Privacy & data](#privacy)

---

## Contact

Email: [FILL: support@yourdomain.com]

I read every email personally. I aim to reply within 2–3 business days.

When reporting a problem, please include:

1. iPhone or iPad model + iOS version
2. App version (Settings → All Sensors → at the bottom)
3. Which sensor and which screen
4. What you expected vs. what you saw
5. A screenshot if possible

---

## Permissions troubleshooting

### "I tapped Allow but the screen still shows 'Unavailable'"

iOS sometimes caches an old permission state. Force-quit the app (swipe up from the App Switcher) and reopen.

If that doesn't fix it: iOS Settings → Privacy & Security → [the permission] → make sure "All Sensors" is set to your intended value.

### "I denied a permission, can I change it?"

Yes. iOS Settings → Privacy & Security → [permission] → All Sensors → toggle. Or: iOS Settings → All Sensors → re-enable any permission listed there.

### "Permission prompt didn't appear"

A given permission only prompts the first time the app actually uses that capability. To re-trigger: delete the app and reinstall, then walk through the permission onboarding flow again.

---

## Show-Off Mode

### How do I enter it?

Open any sensor's detail screen (tap a sensor card on the dashboard) and tap the gradient banner that says "Show-Off Mode" at the top.

### How do I navigate?

- **Horizontal swipe** — switch between sensors (21 total)
- **Vertical swipe** (up = next, down = previous) — switch between variants of the current sensor
- **Bottom pills** — tap to jump directly to a variant
- **Top-right grid icon** — opens a sensor index sheet; tap any sensor to jump to it
- **Top-left X** — exit back to the sensor detail screen

### Why does my variant pick reset when I swipe to another sensor?

It doesn't. Each sensor remembers its own selected variant for the duration of the session. Swipe back and the variant you last picked is still active.

### Show-Off Mode looks small on my iPad

That's intentional — the visualizations were designed for an iPhone-shaped frame, so on iPad we present them as a centered card so proportions stay correct. You still get the full screen for the chrome (close button, sensor name, sensor index).

---

## Logger

### How do I start a recording?

Logger tab (record icon) → tap "Start Log Session for all sensors" on the dashboard, or open Logger Settings to pick specific sensors and per-sensor sample rates.

### What's the format?

Sessions are stored as a SQLite database under your app's `Documents/Logging/` folder. You can export to CSV (one file per sensor) or JSON (a single file with all samples).

### How do I export to my Mac?

Three options:
1. **AirDrop** — long-press a session → Share → AirDrop.
2. **Files app** — your sessions appear under "On My iPhone → All Sensors → Logging". Drag from Files into Finder over a USB cable.
3. **Email / iMessage / any share extension** — long-press session → Share → pick.

### My recording stopped early

iOS can throttle background sensor work to save battery. The app shows a banner when this happens. To minimize throttling: keep the app in the foreground while recording, plug into power, disable Low Power Mode.

### How big can a session get?

A 1-minute recording of all 21 sensors at maximum rate is ~2 MB. A 1-hour recording at default rates (10 Hz for IMU, 1 Hz for slow sensors) is ~30 MB. Storage is your device's storage; the app does not upload anything.

---

## HealthKit

### Why does the Health tab show "No data"?

Either you haven't granted Health permission yet, or your HealthKit store has no data for the requested types. Try moving around with your phone (steps), or check that your Apple Watch is syncing if that's your data source.

### Does the app write to HealthKit?

By default, **no**. The app's HealthKit permission is read-only. Logger has an opt-in toggle to write workout sessions; that's the only write path.

---

## Siri Shortcuts

### What's available?

- **Get Sensor Reading** — returns the current value for a sensor you pick (accelerometer, gyroscope, magnetometer, GPS, compass, barometer, battery)
- **Start Sensor Recording** — begins a logger session for the picked sensor
- **Stop Sensor Recording** — ends the active session
- **Export Sensor Data** — exports the most recent session

Add via Shortcuts app → Add Action → search "All Sensors". Or just say "Hey Siri, get the accelerometer reading" once you've added it once.

---

## Privacy

The app does not collect, transmit, or share any of your data. See the full [privacy policy]([FILL: https://yourdomain.com/allsensors/privacy]).

The only outbound network call is a connectivity test you initiate yourself in the Network sensor.

---

## Known issues in v1.0

- **Magnetometer baseline** drifts on first launch — wave the phone in a figure-8 once to recalibrate.
- **Pedometer** shows "0 steps" until you've walked at least ~20 steps after install.
- **Bluetooth scanning** stops after ~30 seconds per iOS background-scan policy. Tap "Restart Scan" to resume.
- **iPad landscape** Show-Off Mode card stays portrait-shaped (this is intentional).

If you hit a different issue, please [contact](#contact) — I'll fix it in 1.0.1.

---

## Why this app exists

I built All Sensors because I was teaching myself iOS sensor APIs and couldn't find a single app that exposed them all in one place, honestly, with no marketing fluff. If it's useful to you too, that's great. If something's missing or wrong, write me and I'll fix it.

— [FILL: your first name]
