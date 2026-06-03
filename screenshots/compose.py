#!/usr/bin/env python3
"""
compose.py — Stage 3 of the App Store screenshot pipeline.

Takes a raw simulator capture (screenshots/raw/<page>.png) plus the AI-generated
marketing copy (screenshots/copy/<page>.json) and renders an upload-ready App Store
image:

    gradient background  +  caption band (headline / subheadline)  +
    rounded, shadowed device screenshot  +  optional feature-callout badges

Output is a FLATTENED RGB PNG at the exact target resolution for the chosen device
slot (App Store Connect rejects transparency / wrong dimensions), written into the
device-slot folder alongside any hand-curated captures:

    screenshots/<device>/<page>.png     e.g. screenshots/iphone-6.9/dashboard.png

Usage:
    python3 compose.py                         # all pages found in raw/, iphone-6.9
    python3 compose.py --device ipad-13
    python3 compose.py --pages dashboard,health --callouts
    python3 compose.py --list-devices

Dependencies:  Pillow  (pip install -r requirements.txt)

Design note: the device "frame" is drawn procedurally (rounded corners + soft shadow),
so no bezel asset is required. Drop a transparent-center bezel PNG into
screenshots/frames/<device>.png and pass --frame to composite onto a real device mockup
instead (see ASSEMBLY.md).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit("Pillow is required:  python3 -m pip install -r screenshots/requirements.txt")

# --------------------------------------------------------------------------- #
# Device presets — exact App Store Connect target resolutions (see README §1). #
# --------------------------------------------------------------------------- #
# Folder name == device key. All images uploaded to one App Store slot must share
# identical dimensions, so each key maps to exactly one resolution + output folder.
# iphone-6.9 = 1320x2868 matches the existing assets and the iPhone 16 Pro Max native
# capture; iphone-6.9-1290 is the smaller alternate App Store Connect also accepts.
DEVICES = {
    "iphone-6.9":      {"size": (1320, 2868), "label": 'iPhone 6.9" (16 Pro Max native)', "corner": 0.092, "family": "iphone"},
    "iphone-6.9-1290": {"size": (1290, 2796), "label": 'iPhone 6.9" (1290 alt)',          "corner": 0.092, "family": "iphone"},
    "ipad-13":         {"size": (2064, 2752), "label": 'iPad 13"',                         "corner": 0.045, "family": "ipad"},
}

HERE = Path(__file__).resolve().parent
COPY_DIR = HERE / "copy"
FRAME_DIR = HERE / "frames"


def raw_dir_for(device: str) -> Path:
    """Raw captures live in raw/<family>/ (e.g. raw/iphone). Falls back to the
    legacy flat raw/ dir if the family subdir doesn't exist."""
    family = DEVICES[device]["family"]
    sub = HERE / "raw" / family
    return sub if sub.exists() else HERE / "raw"

DEFAULT_BG = ["#071A2F", "#0B3A63"]
DEFAULT_TEXT = "#FFFFFF"
DEFAULT_ACCENT = "#3B82F6"


# --------------------------------------------------------------------------- #
# Helpers                                                                      #
# --------------------------------------------------------------------------- #
def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Best-effort load of a clean sans-serif; falls back to PIL default."""
    candidates = [
        # macOS
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        # Linux
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def gradient(size: tuple[int, int], colors: list[str], angle_deg: float) -> Image.Image:
    """Two-stop linear gradient at an arbitrary angle."""
    w, h = size
    c0, c1 = hex_to_rgb(colors[0]), hex_to_rgb(colors[-1])
    base = Image.new("RGB", size)
    px = base.load()
    rad = math.radians(angle_deg)
    dx, dy = math.cos(rad), math.sin(rad)
    # Project each pixel onto the gradient axis; normalize 0..1.
    proj = [(x * dx + y * dy) for x, y in ((0, 0), (w, 0), (0, h), (w, h))]
    lo, hi = min(proj), max(proj)
    span = (hi - lo) or 1.0
    for y in range(h):
        ydy = y * dy
        for x in range(w):
            t = ((x * dx + ydy) - lo) / span
            px[x, y] = (
                int(c0[0] + (c1[0] - c0[0]) * t),
                int(c0[1] + (c1[1] - c0[1]) * t),
                int(c0[2] + (c1[2] - c0[2]) * t),
            )
    return base


def rounded(img: Image.Image, radius: int) -> Image.Image:
    """Apply rounded corners, returning an RGBA image with a clean alpha mask."""
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]],
                                           radius=radius, fill=255)
    img.putalpha(mask)
    return img


def drop_shadow(canvas: Image.Image, shape: Image.Image, xy: tuple[int, int],
                blur: int, opacity: int, offset: tuple[int, int]) -> None:
    """Paint a soft shadow of `shape`'s alpha onto `canvas` (in place)."""
    w, h = shape.size
    pad = blur * 3
    shadow = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    alpha = shape.split()[-1]
    solid = Image.new("RGBA", (w, h), (0, 0, 0, opacity))
    shadow.paste(solid, (pad, pad), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(shadow, (xy[0] - pad + offset[0], xy[1] - pad + offset[1]))


def wrap(draw: ImageDraw.ImageDraw, text: str, font, max_w: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for word in words:
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def text_block_height(lines: list[str], font, spacing: int) -> int:
    asc, desc = font.getmetrics()
    line_h = asc + desc
    return line_h * len(lines) + spacing * (len(lines) - 1)


# --------------------------------------------------------------------------- #
# Composition                                                                  #
# --------------------------------------------------------------------------- #
def compose(page: str, device: str, draw_callouts: bool, use_frame: bool) -> Path:
    spec = DEVICES[device]
    W, H = spec["size"]

    raw_dir = raw_dir_for(device)
    raw_path = raw_dir / f"{page}.png"
    if not raw_path.exists():
        raise FileNotFoundError(
            f"missing raw capture: {raw_path.relative_to(HERE)} (run capture.sh first)")

    copy_path = COPY_DIR / f"{page}.json"
    if copy_path.exists():
        meta = json.loads(copy_path.read_text())
    else:
        print(f"  ! no copy/{page}.json — using neutral defaults")
        meta = {}

    # Tolerant field reading — accept this repo's schema AND the qwen3-asr schema
    # (subhead / caption_placement / background.{text_color,accent_color,angle_deg}).
    bg = meta.get("background", {}) or {}
    bg_colors = bg.get("colors", DEFAULT_BG)
    angle = float(bg.get("angle", bg.get("angle_deg", 160)))
    text_color = hex_to_rgb(meta.get("text_color", bg.get("text_color", DEFAULT_TEXT)))
    accent = hex_to_rgb(meta.get("accent_color", bg.get("accent_color", DEFAULT_ACCENT)))
    headline = meta.get("headline", page.title())
    subheadline = meta.get("subheadline", meta.get("subhead", ""))
    position = meta.get("caption_position", meta.get("caption_placement", "top"))

    # 1) background canvas
    canvas = gradient((W, H), bg_colors, angle).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # 2) caption band geometry
    side_margin = int(W * 0.085)
    max_text_w = W - side_margin * 2
    h_font = load_font(int(W * 0.072), bold=True)
    s_font = load_font(int(W * 0.034))

    h_lines = wrap(draw, headline, h_font, max_text_w)
    s_lines = wrap(draw, subheadline, s_font, max_text_w) if subheadline else []

    h_spacing = int(W * 0.012)
    s_spacing = int(W * 0.008)
    block_h = text_block_height(h_lines, h_font, h_spacing)
    if s_lines:
        block_h += int(H * 0.018) + text_block_height(s_lines, s_font, s_spacing)

    caption_top = int(H * 0.055) if position == "top" else int(H * 0.80)

    # 3) draw caption text (+ accent underline under the headline)
    y = caption_top
    asc_h, desc_h = h_font.getmetrics()
    for i, line in enumerate(h_lines):
        draw.text((side_margin, y), line, font=h_font, fill=text_color)
        y += asc_h + desc_h + (h_spacing if i < len(h_lines) - 1 else 0)
    # accent underline
    ul_w = int(min(max_text_w, W * 0.20))
    draw.rounded_rectangle([side_margin, y + int(H * 0.010),
                            side_margin + ul_w, y + int(H * 0.010) + int(H * 0.006)],
                           radius=int(H * 0.003), fill=accent)
    y += int(H * 0.030)
    asc_s, desc_s = s_font.getmetrics()
    for line in s_lines:
        draw.text((side_margin, y), line, font=s_font, fill=(*text_color, 220))
        y += asc_s + desc_s + s_spacing

    caption_block_bottom = y if position == "top" else caption_top

    # 4) place the device screenshot
    raw = Image.open(raw_path).convert("RGB")
    # available vertical region for the device
    if position == "top":
        region_top = caption_block_bottom + int(H * 0.04)
        region_bottom = H - int(H * 0.05)
    else:
        region_top = int(H * 0.05)
        region_bottom = caption_top - int(H * 0.04)
    region_h = region_bottom - region_top
    region_w = W - side_margin * 2

    scale = min(region_w / raw.width, region_h / raw.height)
    dev_w, dev_h = int(raw.width * scale), int(raw.height * scale)
    device_img = raw.resize((dev_w, dev_h), Image.LANCZOS)

    radius = int(dev_w * spec["corner"])
    device_img = rounded(device_img, radius)

    dev_x = (W - dev_w) // 2
    dev_y = region_top + (region_h - dev_h) // 2

    # soft shadow then the device
    drop_shadow(canvas, device_img, (dev_x, dev_y),
                blur=int(W * 0.020), opacity=150, offset=(0, int(H * 0.006)))
    # subtle screen bezel/outline for a premium edge
    ImageDraw.Draw(canvas).rounded_rectangle(
        [dev_x - 3, dev_y - 3, dev_x + dev_w + 3, dev_y + dev_h + 3],
        radius=radius + 3, outline=(255, 255, 255, 40), width=3)
    canvas.alpha_composite(device_img, (dev_x, dev_y))

    # 5) optional real-bezel frame overlay (frames/<device>.png, transparent center)
    if use_frame:
        frame_path = FRAME_DIR / f"{device}.png"
        if frame_path.exists():
            frame = Image.open(frame_path).convert("RGBA").resize((dev_w + int(dev_w*0.12),
                                                                   dev_h + int(dev_h*0.06)))
            fx = (W - frame.width) // 2
            canvas.alpha_composite(frame, (fx, dev_y - int(dev_h*0.03)))
        else:
            print(f"  ! --frame requested but {frame_path} not found; skipping bezel")

    # 6) optional feature-callout badges
    if draw_callouts:
        cf = load_font(int(W * 0.026), bold=True)
        for c in meta.get("feature_callouts", []):
            zone = c.get("zone", {})
            label = c.get("label", "")
            if not label or not zone:
                continue
            bx = dev_x + int(zone.get("x", 0) * dev_w)
            by = dev_y + int(zone.get("y", 0) * dev_h)
            tw = draw.textlength(label, font=cf)
            pad = int(W * 0.018)
            ImageDraw.Draw(canvas).rounded_rectangle(
                [bx, by, bx + tw + pad * 2, by + int(W * 0.05)],
                radius=int(W * 0.025), fill=(*accent, 235))
            ImageDraw.Draw(canvas).text((bx + pad, by + int(W * 0.012)),
                                        label, font=cf, fill=(255, 255, 255))

    # 7) flatten to RGB (App Store requires no alpha) and save into the device-slot
    #    folder (screenshots/<device>/<page>.png), alongside any hand-curated captures.
    out_dir = HERE / device
    out_dir.mkdir(parents=True, exist_ok=True)
    flat = Image.new("RGB", (W, H))
    flat.paste(canvas, (0, 0), canvas)
    out_path = out_dir / f"{page}.png"
    flat.save(out_path, "PNG", optimize=True)
    return out_path


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="Assemble App Store marketing screenshots.")
    ap.add_argument("--device", default="iphone-6.9", choices=list(DEVICES),
                    help="target device slot (default: iphone-6.9)")
    ap.add_argument("--pages", default="", help="comma-separated pages (default: all in raw/)")
    ap.add_argument("--callouts", action="store_true", help="draw feature-callout badges")
    ap.add_argument("--frame", action="store_true", help="overlay frames/<device>.png bezel")
    ap.add_argument("--list-devices", action="store_true", help="print device presets and exit")
    args = ap.parse_args()

    if args.list_devices:
        for k, v in DEVICES.items():
            print(f"  {k:20s} {v['size'][0]}x{v['size'][1]}  ({v['label']})")
        return 0

    raw_dir = raw_dir_for(args.device)
    if args.pages.strip():
        pages = [p.strip() for p in args.pages.split(",") if p.strip()]
    else:
        pages = sorted(p.stem for p in raw_dir.glob("*.png") if not p.stem.startswith("."))
    if not pages:
        print(f"No raw captures found in {raw_dir.relative_to(HERE)}/. Run capture.sh first.")
        return 1

    print(f"Composing {len(pages)} page(s) for {args.device} "
          f"({DEVICES[args.device]['size'][0]}x{DEVICES[args.device]['size'][1]})")
    rc = 0
    for page in pages:
        try:
            out = compose(page, args.device, args.callouts, args.frame)
            print(f"  ✓ {page:12s} → {out.relative_to(HERE)}")
        except FileNotFoundError as e:
            print(f"  ✗ {page:12s} {e}")
            rc = 1
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
