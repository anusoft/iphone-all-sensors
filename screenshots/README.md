# App Store Screenshots — "All Sensors"

Canonical home for everything screenshot-related: the **specs**, the **capture +
compose pipeline**, and the **final, upload-ready images** organized by device slot.

> Two ways to produce store images live here, and they share this folder + the same
> final device subdirs:
> - **A · Marketing / Hero pipeline** (styled): polished `ScreenshotHeroView` pages →
>   `capture.sh` → AI copy → `compose.py` (gradient + device frame + headline).
> - **B · Clean / Show-Off pipeline** (undecorated): the in-app `--showoff` mode →
>   raw simulator capture, dropped straight into the device folder.
>
> Both are valid App Store submissions. Use **A** for conversion-optimized marketing
> art, **B** for the lowest-risk "App in use" look. You can mix curated picks from each.

## ⚡ One-shot

```bash
./screenshots/run.sh          # detect sims → build once → capture → compose → verify
```

Auto-detects the best iPhone **and** iPad simulator, builds the app once, captures every
hero page, composes final upload-ready images into `iphone-6.9/` + `ipad-13/`, and
**verifies every output's dimensions** before exiting 0. No flags needed. Add custom
`copy/<page>.json` first for AI taglines (the only non-automated step — "except codex");
otherwise compose uses built-in defaults so the run never blocks. Useful flags:
`--no-ipad`, `--no-build`, `--iphone "<name>"`, `--pages dashboard,health`.

```
screenshots/
├── README.md                     ← you are here (specs + how to generate)
├── run.sh                        ← ⚡ ONE-SHOT: detect sims → build → capture → compose → verify
├── ASSEMBLY.md                   ← marketing layout / device-framing workflow (Frameit, ImageMagick, Pillow)
├── capture.sh                    ← Pipeline A capture: boot sim → hero page → raw/<family>/*.png
├── compose.py                    ← Pipeline A compose: raw/<family> + copy → screenshots/<device>/*.png
├── requirements.txt              ← Python deps for compose.py (Pillow)
├── prompts/
│   └── marketing-vision-prompt.md  ← Vision-LLM prompt: raw shot → marketing JSON
├── copy/                         ← per-page marketing copy JSON (LLM output / hand-edited)
│   └── dashboard.json
├── frames/                       ← optional device bezel PNGs (transparent center)
├── raw/<iphone|ipad>/            ← intermediate clean captures, per family (gitignored)
├── iphone-6.9/                   ← FINAL upload set, iPhone 6.9" — 1320×2868
│   ├── 01-dashboard.png …        ← Pipeline B (Show-Off) curated captures
│   └── dashboard.png …           ← Pipeline A (marketing) composites
└── ipad-13/                      ← FINAL upload set, iPad 13" — 2064×2752
```

> Docs that reference this folder: `docs/screenshots.md` (the generation guide) and
> `docs/appstore/11-build-and-screenshots.md` (submission checklist). See also CLAUDE.md.

---

## Pipeline A — Marketing / Hero (styled, high-conversion)

```
 ┌─────────────┐  capture.sh   ┌──────────┐   marketing-vision-prompt   ┌────────────┐  compose.py  ┌────────────────────┐
 │  Simulator  │ ────────────▶ │ raw/*.png │ ─────(Vision LLM)─────────▶ │ copy/*.json │ ───────────▶ │ <device>/<page>.png │
 │ hero page   │  launch /     └──────────┘   taglines + bg styling     └────────────┘ Pillow overlay└────────────────────┘
 └─────────────┘  openurl                                                                + device frame  (upload-ready)
```

`run.sh` (above) runs steps 1 & 3 for both device slots in one shot. The manual
breakdown — step 2 is the only one you ever do by hand:

```bash
# 1. capture clean hero surfaces (use a 6.9" device for the required slot)
#    → screenshots/raw/iphone/<page>.png  (family inferred from the device name)
./screenshots/capture.sh --device "iPhone 16 Pro Max" \
    --pages "dashboard,motion,health,environment,logger"

# 2. (LLM step — "except codex") feed each screenshots/raw/iphone/<page>.png to a
#    Vision model with prompts/marketing-vision-prompt.md → save screenshots/copy/<page>.json
#    (compose also accepts the qwen3-asr schema: subhead / caption_placement / nested colors)

# 3. assemble final, upload-ready images into the device-slot folder
python3 -m pip install -r screenshots/requirements.txt
python3 screenshots/compose.py --device iphone-6.9 --callouts   # reads raw/iphone → iphone-6.9/<page>.png
python3 screenshots/compose.py --device ipad-13   --callouts    # reads raw/ipad   → ipad-13/<page>.png
```

| Stage | Tool | Input | Output |
|-------|------|-------|--------|
| 1. Capture | `capture.sh` (`xcrun simctl`) | hero page (deep link / launch arg) | `raw/<page>.png` |
| 2. Copywriting | Vision LLM + `prompts/marketing-vision-prompt.md` | `raw/<page>.png` | `copy/<page>.json` |
| 3. Assembly | `compose.py` (Pillow) | raw PNG + copy JSON + frame | `<device>/<page>.png` |

The hero pages live in `iPhoneSensors/Views/Screenshots/ScreenshotHeroView.swift` and
use entirely deterministic mock data, so captures are byte-stable across runs.

## Pipeline B — Clean / Show-Off (undecorated "app in use")

These produced the curated `NN-*.png` images already in the device folders. The in-app
**Show-Off Mode** (full-bleed theatrical sensor visualizations, see
`docs/sensors-show-off.md`) is launched directly into a chosen sensor/variant:

```bash
# Launch straight into a Show-Off variant, then screenshot.
# --showoff <sensorIdx> <variantIdx>  — sensorIdx is a TWO-DIGIT id from
# ShowOffVariantRouter.swift: 01=GPS 02=Heading 03=Accel 04=Gyro 05=Mag 06=DeviceMotion
# 07=Alt 08=Baro 09=Pedometer 10=Activity 11=Battery 12=Thermal 13=Disk 14=Mem 15=CPU
# 16=Bluetooth 17=Network 18=Camera 19=Light 20=Proximity 21=Torch.
UDID=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl launch "$UDID" com.1moby.allsensors --showoff 01 0     # 01 = GPS, variant 0
sleep 4
xcrun simctl io "$UDID" screenshot screenshots/iphone-6.9/02-gps-hud.png
```

No frames, gradients, or text overlays are added — the raw capture *is* the final image.
Capture on the exact device class so dimensions match the slot (6.9″ = 1320×2868).

---

## App Store screenshot requirements (researched)

> Source of truth: Apple Developer — *Screenshot specifications* (App Store Connect Help).
> Verified June 2026. Apple requires **one size per device family**; App Store Connect
> auto-downscales it to every smaller display, so you upload one set per family.

### Required device sizes

| Device family | Reference device | Portrait (px) | Folder | Required? |
|---------------|------------------|---------------|--------|-----------|
| **iPhone 6.9″** | iPhone 16 Pro Max | **1320 × 2868** (or 1290 × 2796) | `iphone-6.9/` | ✅ all apps |
| **iPad 13″** | iPad Pro 13″ (M4/M5) | **2064 × 2752** | `ipad-13/` | ✅ if app supports iPad |

`TARGETED_DEVICE_FAMILY = "1,2"` → this app supports iPad, so **both** slots are required.

### Rules

| Rule | Value |
|------|-------|
| Format | **PNG or JPEG**, RGB, **flattened (no alpha/transparency)** |
| Dimensions | Every image in one slot folder must share **identical** dimensions |
| Min / Max per slot per localization | **1** (recommend ≥3) / **10** |
| Max file size | **10 MB** per image |
| Content | Realistic status bar; not all-text; must not misrepresent the app. Marketing frames/gradients/captions **are** permitted (Pipeline A) and widely used — the "no decoration" rule applies to the app *icon*, not screenshots. |

`compose.py` always exports flattened RGB PNG at the exact slot resolution, so Pipeline A
output is upload-safe by construction.

### Device presets (`compose.py --device`)

| Key | Resolution | Output folder |
|-----|------------|---------------|
| `iphone-6.9` (default) | 1320 × 2868 | `screenshots/iphone-6.9/` |
| `iphone-6.9-1290`      | 1290 × 2796 | `screenshots/iphone-6.9-1290/` |
| `ipad-13`              | 2064 × 2752 | `screenshots/ipad-13/` |

---

## Deep link / launch contract (Pipeline A hero pages)

The app registers the `app` URL scheme (`iPhoneSensors/Info.plist`) and routes:

```
allsensors://<namespace>.<app>/screenshots/<page-name>     e.g. allsensors://1moby.allsensors/screenshots/dashboard
```

| Page | URL | Launch-arg equivalent | Showcases |
|------|-----|------------------------|-----------|
| `dashboard`   | `allsensors://1moby.allsensors/screenshots/dashboard`   | `--screenshot dashboard`   | 21 sensors + live chart |
| `motion`      | `allsensors://1moby.allsensors/screenshots/motion`      | `--screenshot motion`      | Accel/gyro chart + RPY rings |
| `health`      | `allsensors://1moby.allsensors/screenshots/health`      | `--screenshot health`      | HR ring + trend + vitals |
| `environment` | `allsensors://1moby.allsensors/screenshots/environment` | `--screenshot environment` | Barometer, altitude, light |
| `logger`      | `allsensors://1moby.allsensors/screenshots/logger`      | `--screenshot logger`      | Recording + CSV/JSON/SQLite |

Routing: `ScreenshotRouter` + `.onOpenURL` (`iPhoneSensorsApp.swift`) and the
`--screenshot <page>` launch arg (`ContentView.swift`) both render `ScreenshotHeroView`.

**Why two entry points (launch is the unattended default):** `capture.sh` defaults to
`--method launch` (`simctl launch … --screenshot <page>`) because it is deterministic and
prompt-free. `simctl openurl` to a **custom URL scheme** raises a SpringBoard consent
prompt ("Open in …?") — and if more than one installed app claims `allsensors://`, a chooser
instead — either of which overlays the screenshot and blocks unattended/CI capture.
(Confirmed on both this app and the qwen3-asr Konjac pipeline.) `--method openurl` still
exercises the real `.onOpenURL` deep link for interactive verification.

> **Note on this Xcode:** capture uses `xcrun simctl io <udid> screenshot <file>` — there
> is no top-level `simctl screenshot` subcommand on Xcode 26+. `capture.sh` also pins the
> status bar to 9:41 / full battery / full signal and clears it on exit.

See `ASSEMBLY.md` for the full marketing-layout / device-framing workflow.
