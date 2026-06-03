# Marketing Layout Assembly — Workflow & Options

Stage 3 of the pipeline turns each **raw capture** + **AI copy JSON** into an
**upload-ready App Store image** at the exact target resolution (README §1.4).

This repo ships a self-contained Pillow assembler (`compose.py`) as the default,
and documents two alternatives (Fastlane Frameit, ImageMagick) for teams already
invested in those toolchains. All three produce the same artifact shape:
`screenshots/<device>/<page>.png` (e.g. `screenshots/iphone-6.9/dashboard.png`).

---

## Option A — `compose.py` (Pillow) · default, zero external tooling

```bash
python3 -m pip install -r screenshots/requirements.txt

# all pages found in raw/, iPhone 6.9" (1320×2868) → screenshots/iphone-6.9/, with badges
python3 screenshots/compose.py --device iphone-6.9 --callouts

# iPad 13" (2064×2752) → screenshots/ipad-13/
python3 screenshots/compose.py --device ipad-13

# just two pages, no badges
python3 screenshots/compose.py --pages dashboard,health
```

What it renders, bottom-to-top:
1. **Gradient background** — `background.colors` + `background.angle` from the copy JSON.
2. **Device screenshot** — scaled to fit, **rounded corners + soft drop shadow**, hairline edge.
3. **Caption band** — `headline` (with accent underline) + `subheadline`, placed `top`/`bottom`.
4. **Feature callouts** *(with `--callouts`)* — accent badges anchored to normalized `zone`s.
5. **Flatten → RGB PNG** at the exact device resolution (App Store rejects alpha / wrong dims).

It reads every field the Vision prompt emits (README + `prompts/marketing-vision-prompt.md`),
so the LLM → assembler loop is closed with no manual mapping.

### Optional: composite onto a real device bezel
Drop a transparent-center bezel PNG at `screenshots/frames/<device>.png` and add `--frame`:
```bash
python3 screenshots/compose.py --device iphone-6.9 --frame
```
Good free bezels: Apple's [Apple Design Resources](https://developer.apple.com/design/resources/)
(Device frames), or Facebook's [devices.css](https://github.com/picturepan2/devices.css) PNG exports.

---

## Option B — Fastlane `frameit` · best if you already use Fastlane snapshot

`frameit` auto-wraps screenshots in the correct Apple device frame and burns in a
title/keyword from a per-locale strings file. It infers the device from the image
resolution, which is why **capturing at the true 6.9″/13″ size matters**.

```bash
# one-time
brew install imagemagick
gem install fastlane
fastlane frameit setup        # downloads the official frames

# layout: screenshots/raw/<locale>/<page>.png  (e.g. en-US/dashboard.png)
cd screenshots/raw
frameit                       # writes <page>_framed.png next to each source
```

Drive the copy with `Framefile.json` + `title.strings` (maps to our copy JSON):

```jsonc
// screenshots/raw/Framefile.json
{
  "device_frame_version": "latest",
  "default": {
    "title": { "color": "#FFFFFF" },
    "background": "./background.jpg",
    "padding": 50,
    "show_complete_frame": false,
    "title_below_image": false
  },
  "data": [
    { "filter": "dashboard", "title": { "text": "See every sensor, live" } },
    { "filter": "health",    "title": { "text": "Your vitals, visualized" } }
  ]
}
```

A tiny adapter can transpile our `copy/*.json` → `Framefile.json` + `title.strings`
so the same AI output feeds either backend.

---

## Option C — ImageMagick · scriptable, CI-friendly, no Ruby/Python deps

```bash
brew install imagemagick   # provides `magick`

PAGE=dashboard
W=1320; H=2868
ACCENT="#3B82F6"

# 1) gradient canvas
magick -size ${W}x${H} gradient:'#071A2F-#0B3A63' canvas.png

# 2) round the screenshot corners (radius ~ 9% of width)
magick screenshots/raw/$PAGE.png \
  \( +clone -alpha extract -draw 'fill black polygon 0,0 0,90 90,0 fill white circle 90,90 90,0' \
     \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
  -alpha off -compose CopyOpacity -composite shot_rounded.png

# 3) shadow + composite device, then caption text
magick canvas.png \( shot_rounded.png -resize 80% \) -gravity center -geometry +0+180 -composite \
  -gravity North -pointsize 96 -fill white -font Helvetica-Bold \
  -annotate +0+150 'See every sensor, live' \
  -gravity North -pointsize 44 -fill '#CBD5E1' \
  -annotate +0+300 '21 iPhone sensors — motion, GPS, health & more.' \
  -flatten screenshots/iphone-6.9/$PAGE.png
```

ImageMagick is the most portable in headless CI but the most verbose for callouts/badges.

---

## Recommended end-to-end (the path this repo automates)

```bash
# 1. capture (clean, 9:41 status bar) — use a 6.9" device for the required slot
./screenshots/capture.sh --device "iPhone 16 Pro Max" \
    --pages "dashboard,motion,health,environment,logger"

# 2. AI copy: feed each raw/<page>.png + prompts/marketing-vision-prompt.md to a
#    vision model; save JSON to copy/<page>.json

# 3. assemble required slots → screenshots/<device>/<page>.png
python3 screenshots/compose.py --device iphone-6.9 --callouts          # required
python3 screenshots/compose.py --device ipad-13   --callouts           # if iPad supported

# 4. upload screenshots/<device>/*.png via App Store Connect, Transporter, or:
#    fastlane deliver --screenshots-path screenshots
```

### Resolution matrix (what to capture vs. what to upload)

| Slot | Capture device (raw) | `compose.py --device` | Final size |
|------|----------------------|------------------------|------------|
| iPhone 6.9″ (required) | iPhone 16 Pro Max | `iphone-6.9` | 1320 × 2868 |
| iPad 13″ (required if iPad) | iPad Pro 13″ (M4/M5) | `ipad-13` | 2064 × 2752 |

> `compose.py` scales whatever raw size it's given to fit the target canvas, so the
> pipeline still runs on a 6.1″ sim for previews — but **submit captures taken on the
> matching device class** for pixel-perfect, non-upscaled device content.

### Notes for clean, store-grade captures
- Capture on the **exact device class** of the slot (don't upscale a 6.1″ shot to 6.9″).
- `capture.sh` pins the status bar to **9:41 / full battery / full signal**; it clears the
  override on exit.
- The transient `‹ <app>` back-affordance you may see top-left only appears when another app
  hands off via URL; it is absent on a freshly booted device used for final captures.
- Keep ≤ 10 images per slot per localization; lead with your 3 strongest.
