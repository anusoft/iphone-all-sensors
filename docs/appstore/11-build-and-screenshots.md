# 11 · Build, Icon, Screenshots, App Preview

## Build upload

You upload via Xcode (preferred) or Transporter.

### Xcode → Archive → Distribute

1. Select scheme `iPhoneSensors`, destination `Any iOS Device (arm64)`.
2. Bump build number first if this isn't the very first upload: in pbxproj `CURRENT_PROJECT_VERSION = N+1`. (Marketing version `1.0` stays the same; build numbers must be unique per upload.)
3. Product → Archive. Wait ~2 minutes.
4. Organizer opens. Pick the new archive → `Distribute App` → `App Store Connect` → `Upload`.
5. Apple processes the build for ~10 minutes. You'll get an email when it's available in App Store Connect.

The first time you upload, Apple may flag "Missing Compliance" — fix per [09](09-export-compliance.md).

### Sanity-check before archiving

```bash
# Make sure release build still compiles
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj \
           -scheme iPhoneSensors \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           build
```

Watch for any new warnings. The submission packet is fine with warnings, but resolve any new errors.

## App icon

### Required size: **1024 × 1024 px**, PNG, no transparency, no rounded corners (Apple rounds them).

Already set in `Assets.xcassets/AppIcon.appiconset`. To verify:

1. Open `iPhoneSensors/iPhoneSensors/Assets.xcassets/AppIcon.appiconset` in Finder.
2. Confirm `Icon-App-1024x1024@1x.png` is present and is exactly 1024×1024.
3. Also confirm a "marketing" 1024×1024 is set in Assets.xcassets → AppIcon → "App Store" slot.

App Store does NOT accept icons with: transparent backgrounds, alpha channel, "beta" / "test" overlays, or text that says "iPhone".

If you need to refine the icon before launch, the design lives in `[FILL: path to your source icon design file, e.g., Figma URL or PSD]`.

## Screenshots

> **How to generate:** see [`docs/screenshots.md`](../screenshots.md) for the full guide
> and [`screenshots/README.md`](../../screenshots/README.md) for the runnable pipeline.
> Finished, correctly-sized images live in `screenshots/iphone-6.9/` and `screenshots/ipad-13/`.

There are **two pipelines**, both depositing into those slot folders:

- **A · Marketing / Hero** (styled): `screenshots/capture.sh` captures polished
  `ScreenshotHeroView` pages → a Vision LLM writes copy JSON → `screenshots/compose.py`
  composites gradient + device frame + headline. Produces `iphone-6.9/<page>.png`.
- **B · Clean / Show-Off** (undecorated): the in-app `--showoff` mode captured raw.
  Produced the curated `iphone-6.9/NN-*.png` set already present.

| Device class         | Required? | Size (portrait)  | Folder                  | Count |
|----------------------|-----------|------------------|-------------------------|-------|
| iPhone 6.9" Display  | **Yes**   | 1320 × 2868      | `screenshots/iphone-6.9/` | up to 10 |
| iPad 13"             | **Yes** (if iPad enabled) | 2064 × 2752 | `screenshots/ipad-13/`    | up to 10 |

(Note: TARGETED_DEVICE_FAMILY = "1,2" means the build supports iPad. So iPad screenshots
are required. All images in a single slot folder must share identical dimensions.)

### Recommended order in App Store Connect (drag-drop)

1. `02-gps-hud.png`         — Show-Off Mode hero (red HUD)
2. `01-dashboard.png`       — Sensor list overview
3. `03-compass-rose.png`    — Show-Off Mode (compass)
4. `04-pedometer-big.png`   — Show-Off Mode (pedometer)
5. `05-cpu-cores.png`       — Show-Off Mode (processor cores)

Apple shows the first screenshot as the primary "hero" tile. Putting Show-Off Mode there showcases the differentiator.

### Screenshot content rules to remember

- Status bar must look real (`capture.sh` pins it to 9:41 / full battery / full signal,
  which is the standard Apple marketing state, not "editing").
- **Device frames, gradient backgrounds, and text/caption overlays ARE allowed** on
  screenshots and are used by most top apps — that's exactly what Pipeline A produces.
  The "no frames / no decoration" restriction applies to the **app icon**, not
  screenshots. Avoid only: claims you can't back up, fake UI, "Available now"/price
  badges that misrepresent, or anything implying another platform.
- All-text screenshots are not allowed — they must show the app. (Both pipelines do.)
- Flattened RGB PNG/JPEG, no transparency; all images in one slot share dimensions.
- The same screenshot can be reused across language localizations.

If you prefer the most conservative, lowest-risk route, ship the undecorated Pipeline B
(Show-Off) captures; they show the app with no marketing layer at all.

## App Previews (optional but high-impact)

App Previews are 15–30 second videos shown above your screenshots on the store. Approval rates and conversion are noticeably higher with one.

| Device class         | Resolution        | Frame rate | Duration |
|----------------------|-------------------|------------|----------|
| iPhone 6.9"          | 886 × 1920 OR 1080 × 1920 | 30 fps     | 15–30 s  |
| iPad 13"             | 1200 × 1600       | 30 fps     | 15–30 s  |

Recording flow:

1. Boot the iPhone 17 Pro Max simulator.
2. Launch app.
3. `xcrun simctl io booted recordVideo --codec h264 ./preview-iphone.mov` (Ctrl-C when done).
4. Run through: dashboard tap → sensor → Show-Off banner tap → 3 swipes through variants → exit.
5. Trim in QuickTime to ≤30 s. Export at the resolution above.

Repeat for iPad simulator → `preview-ipad.mov`.

Upload via App Store Connect → Version → "App Previews" slot.

## Localization

App Store Connect lets you provide a localized name, description, keywords, etc., per language. For v1.0 ship English (US) only. Your existing `LocalizationManager` already supports more — but the App Store *metadata* doesn't have to match the in-app languages.

If you do localize: pick the languages you can verify (you, a friend, or a paid translator). Apple now flags machine-translated metadata as a quality issue and may reject.
