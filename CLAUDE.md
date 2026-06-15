# All Sensors — project guide

SwiftUI **iOS/iPadOS** app that exposes every iPhone/iPad sensor (motion, location,
environment, health, system, camera) with live readouts, charts, a theatrical
"Show-Off Mode", and a data logger that exports CSV/JSON/SQLite.

## Project facts

| | |
|---|---|
| Xcode project | `iPhoneSensors/iPhoneSensors.xcodeproj` |
| Scheme / target | `iPhoneSensors` |
| Bundle id | `com.1moby.allsensors` |
| Deployment target | iOS 17.0 |
| Device family | `1,2` (iPhone **and** iPad) |
| Source root | `iPhoneSensors/iPhoneSensors/` (`App/`, `Views/`, `Services/`, `Models/`) |

The `project.pbxproj` is **hand-written** (no Xcode UI / xcodegen) with a custom ID
scheme — adding a new Swift file means editing 4 sections by hand. SourceKit lints are
unreliable for new files until they're in the target; trust a real build.

```bash
# Build for the simulator
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

## Generating App Store screenshots

**One-shot:** `./screenshots/run.sh` — auto-detects the best iPhone + iPad simulator,
builds once, captures every hero page, composes final upload-ready images into
`screenshots/iphone-6.9/` + `screenshots/ipad-13/`, and verifies all dimensions before
exiting 0. (Drop `screenshots/copy/<page>.json` first for AI taglines — the only manual
step; otherwise it uses defaults.)

All screenshot tooling + final assets live in **`screenshots/`** (plural). Two pipelines,
both writing into the per-device slot folders `screenshots/iphone-6.9/` and `screenshots/ipad-13/`:

- **A · Marketing / Hero** (styled): `screenshots/capture.sh` → Vision LLM copy →
  `screenshots/compose.py` (gradient + device frame + headline). Hero pages:
  `iPhoneSensors/Views/Screenshots/ScreenshotHeroView.swift`, deep-linked via
  `allsensors://1moby.allsensors/screenshots/<page>` or the `--screenshot <page>` launch arg.
- **B · Clean / Show-Off** (undecorated): in-app `--showoff <sensorID> <variant>` captured raw.

👉 **Read [`docs/screenshots.md`](docs/screenshots.md) for the how-to**, with
[`screenshots/README.md`](screenshots/README.md) (full reference + specs),
[`screenshots/ASSEMBLY.md`](screenshots/ASSEMBLY.md) (Frameit/ImageMagick/Pillow), and
[`docs/appstore/11-build-and-screenshots.md`](docs/appstore/11-build-and-screenshots.md)
(submission checklist).

Gotchas: use `xcrun simctl io <udid> screenshot <file>` (no `simctl screenshot` on Xcode 26+);
the `allsensors://` scheme can be contested by another app, so `capture.sh` defaults to the
deterministic `--method launch`; required 6.9″ = 1320×2868, iPad 13″ = 2064×2752, all
images in a slot share dimensions.

## App Store Connect & fastlane

The app record must be **created once by hand** (the App Store Connect API has no
create-app endpoint); the bundle id `com.1moby.allsensors` is already registered.
Everything after — metadata + screenshots + build upload — is automated via fastlane
using the App Store Connect API key (`~/.appstoreconnect/private_keys/AuthKey_<id>.p8`;
`ASC_KEY_ID` / `ASC_ISSUER_ID` via env, never committed). Metadata **source of truth lives
in `docs/appstore/metadata/`** (read directly by `deliver`); lanes: `fastlane metadata` /
`screenshots` / `store_listing`.

👉 **Read [`docs/appstore/12-appstore-connect-and-fastlane.md`](docs/appstore/12-appstore-connect-and-fastlane.md)** for the fastlane metadata/screenshot workflow.

For **build → upload → age-rating → submit-for-review via the App Store Connect REST API**, use
[`docs/appstore/14-build-upload-submit-for-review.md`](docs/appstore/14-build-upload-submit-for-review.md)
as the operator checklist and
[`docs/appstore/13-api-publish-runbook.md`](docs/appstore/13-api-publish-runbook.md) for API
gotchas. The helper is **`scripts/appstore/asc.py`** (`status` / `age-rating-4plus` /
`content-rights` / `price-free` / `wait-build` / `encryption` / `attach-build` / `submit` /
`raw`). App id `6776145177`, team `D62Y8JVXB9`. App Privacy is the one UI-only step that gates
`submit` (publish "Data Not Collected"). 1.0 build 1 submitted 2026-06-03; 1.0 build 2
resubmitted 2026-06-08 after the permission-button wording rejection fix. ⚠️ The runbook flags the
**Guideline 4.3(a) "Design–Spam"** risk for this multi-app account — lead with Show-Off Mode (74
visualizations) + fully-on-device differentiation; Resolution Center replies are manual.

## Other docs

`docs/sensors-show-off.md` (Show-Off Mode design spec), `docs/appstore/` (store metadata
& submission), `docs/features.md` / `docs/logging.md` (feature references).
