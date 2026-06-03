---
name: screenshots
description: How to generate App Store screenshots for All Sensors — the two pipelines (marketing/hero + clean/show-off), specs, and gotchas.
type: how-to
updated: 2026-06-02
---

# Generating App Store Screenshots

All screenshot tooling and assets live in **`screenshots/`** (plural) at the repo root.
This doc is the orientation; the runnable detail is in
[`screenshots/README.md`](../screenshots/README.md) and
[`screenshots/ASSEMBLY.md`](../screenshots/ASSEMBLY.md).

There are **two pipelines**, both writing their finished images into the per-device
slot folders `screenshots/iphone-6.9/` and `screenshots/ipad-13/`:

| | **A · Marketing / Hero** | **B · Clean / Show-Off** |
|---|---|---|
| Look | Gradient bg + device frame + headline/sub + callout badges | Undecorated full-bleed app capture |
| In-app surface | `ScreenshotHeroView` (mock data) | Show-Off Mode variants ([`docs/sensors-show-off.md`](sensors-show-off.md)) |
| Entry | `app://…/screenshots/<page>` deep link **or** `--screenshot <page>` launch arg | `--showoff <sensorID> <variantIdx>` launch arg |
| Make it | `capture.sh` → Vision LLM → `compose.py` | launch + `simctl io … screenshot` |
| Produced | `iphone-6.9/dashboard.png`, … | `iphone-6.9/01-dashboard.png`, `02-gps-hud.png`, … |
| Best for | Conversion-optimized store art | Lowest-risk "app in use" |

Both are App-Store-legal. Marketing frames/gradients/captions **are** allowed on
screenshots (most top apps use them); the "no decoration" rule applies to the app
*icon*, not screenshots. Pick per slot, or mix the strongest of each (≤10 per slot).

---

## Pipeline A — marketing / hero (the automated path)

**One-shot (recommended):**

```bash
./screenshots/run.sh
```

Auto-detects the best iPhone + iPad simulator, builds the app once, captures every hero
page, composes final upload-ready images into `screenshots/iphone-6.9/` and
`screenshots/ipad-13/`, then verifies every output's dimensions before exiting 0. The
only thing it can't do for you is write the AI copy (step 2 below — "except codex"); it
falls back to built-in defaults so the run never blocks. Flags: `--no-ipad`, `--no-build`,
`--iphone "<name>"`, `--pages dashboard,health`, `--no-callouts`.

**Manual breakdown** (what `run.sh` automates for both slots):

```bash
# 1. capture polished hero pages (use a 6.9" device for the required slot)
./screenshots/capture.sh --device "iPhone 16 Pro Max" \
    --pages "dashboard,motion,health,environment,logger"
#    → screenshots/raw/iphone/<page>.png   (status bar pinned to 9:41, full battery/signal)

# 2. AI copy ("except codex"): send each screenshots/raw/iphone/<page>.png to a vision
#    model with screenshots/prompts/marketing-vision-prompt.md; save the JSON it returns
#    to screenshots/copy/<page>.json. compose accepts this repo's schema AND the
#    qwen3-asr schema (subhead / caption_placement / nested background colors).

# 3. compose final, upload-ready images into the slot folder
python3 -m pip install -r screenshots/requirements.txt
python3 screenshots/compose.py --device iphone-6.9 --callouts   # reads raw/iphone → iphone-6.9/
python3 screenshots/compose.py --device ipad-13   --callouts    # reads raw/ipad   → ipad-13/
```

Hero pages are defined in `iPhoneSensors/Views/Screenshots/ScreenshotHeroView.swift`
with deterministic mock data (no live sensors / permissions), so captures are stable.
Routing: `ScreenshotRouter` + `.onOpenURL` in `iPhoneSensorsApp.swift`, plus the
`--screenshot <page>` launch arg parsed in `ContentView.swift` (both render the hero).
Add a new page = add a case to `ScreenshotPage` + a `Hero<Page>Page` view.

## Pipeline B — clean / show-off (curated captures)

```bash
UDID=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl launch "$UDID" com.1moby.allsensors --showoff 01 0   # <sensorIdx> <variantIdx>
sleep 4
xcrun simctl io "$UDID" screenshot screenshots/iphone-6.9/02-gps-hud.png
```

`sensorIdx` is a **two-digit id** from `ShowOffVariantRouter.swift`: `01`=GPS, `02`=Heading,
`03`=Accel, `04`=Gyro, `05`=Mag, `06`=DeviceMotion, `07`=Alt, `08`=Baro, `09`=Pedometer,
`10`=Activity, `11`=Battery, `12`=Thermal, `13`=Disk, `14`=Mem, `15`=CPU, `16`=Bluetooth,
`17`=Network, `18`=Camera, `19`=Light, `20`=Proximity, `21`=Torch. Capture on the exact
device class so the file matches the slot dimensions.

---

## Specs (verified June 2026)

| Slot | Device | Size (portrait) | Folder | Required? |
|------|--------|-----------------|--------|-----------|
| iPhone 6.9″ | iPhone 16 Pro Max | **1320 × 2868** (1290 × 2796 also accepted) | `screenshots/iphone-6.9/` | ✅ all apps |
| iPad 13″ | iPad Pro 13″ (M4/M5) | **2064 × 2752** | `screenshots/ipad-13/` | ✅ (this app sets `TARGETED_DEVICE_FAMILY = "1,2"`) |

- Flattened **PNG/JPEG, RGB, no alpha**. 1–10 per slot per localization (recommend ≥3). ≤10 MB each.
- **Every image in one slot folder must share identical dimensions** — don't mix 1320×2868 and 1290×2796 in `iphone-6.9/`. App Store Connect auto-downscales the 6.9″ set to all smaller iPhones.

## Gotchas (this machine / Xcode 26+)

- **No `simctl screenshot` subcommand** — use `xcrun simctl io <udid> screenshot <file>`.
- **`simctl openurl` to a custom scheme is not unattended-safe.** It raises a SpringBoard
  "Open in …?" consent prompt (and a chooser if more than one app claims `app://`) that
  overlays the screenshot. So `run.sh`/`capture.sh` default to `--method launch`
  (`simctl launch … --screenshot <page>`), which is prompt-free; `--method openurl` is for
  interactive deep-link verification only. (Same conclusion as the qwen3-asr pipeline.)
- **Raw captures are namespaced per family** (`raw/iphone/`, `raw/ipad/`) so an iPad run
  never clobbers the iPhone set; `compose.py` reads the matching family for its `--device`.
- Only the **6.1″ iPhone 16e** + iPad Pro sims were installed here; install **iPhone 16
  Pro Max** (Xcode ▸ Settings ▸ Components) for pixel-perfect 6.9″ captures. `compose.py`
  will upscale a smaller raw to fit, but that softens the device content.
- Only **one simulator** should be booted at a time on this Mac (OOM).

See [`screenshots/README.md`](../screenshots/README.md) for the full reference and
[`docs/appstore/11-build-and-screenshots.md`](appstore/11-build-and-screenshots.md) for
the submission checklist.
