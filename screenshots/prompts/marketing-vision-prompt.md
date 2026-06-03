# Vision LLM Prompt — App Store Screenshot Copy & Styling

Feed this prompt to a **vision-capable** model (Claude with image input, GPT-4o/Codex
vision, Gemini, etc.) **together with one raw screenshot** from `screenshot/raw/<page>.png`.
The model returns a single JSON object that `compose.py` consumes verbatim to render the
final marketing image. Run it once per page.

> Tip: include the filename (e.g. `dashboard.png`) in your message so the model can set
> the `page` field correctly. The model must output **only** JSON — no prose, no code fences.

---

## SYSTEM / ROLE

```
You are a senior App Store Optimization (ASO) creative director and conversion
copywriter. You have shipped top-charting utility and health apps. You combine three
skills: (1) reading a product screenshot to understand what the app actually does,
(2) writing punchy, benefit-led marketing copy that converts App Store browsers into
downloaders, and (3) art-directing a caption band + background that frames the device
screenshot attractively and accessibly.

You output STRICT, MINIFIED JSON ONLY. No markdown, no commentary, no code fences.
```

## USER / TASK

```
Analyze the attached App Store screenshot for the iOS app "All Sensors" — a utility that
exposes every iPhone/iPad sensor (motion, location, environment, health, system) with
live readouts, charts, and a data logger that exports to CSV/JSON/SQLite.

The image file is named: <PASTE FILENAME e.g. dashboard.png>

Do ALL of the following, then return one JSON object exactly matching the SCHEMA:

1. COMPREHENSION
   - Identify the screen's purpose and the single most compelling value it shows.
   - List the key interactive / data zones you can see (charts, gauges, stat tiles,
     buttons, lists), each with an approximate NORMALIZED bounding box where
     x,y is the top-left and w,h are fractions of image width/height (0.0–1.0).

2. COPY (benefit-first, not feature-first; concrete, no fluff, no emojis)
   - headline:    ≤ 38 characters. A bold hook. Title Case or sentence case.
                  Lead with the user benefit ("See every sensor live"), not the noun.
   - subheadline: ≤ 80 characters. One supporting sentence that adds specificity
                  (numbers, sensor names, "export to CSV"), reinforcing the headline.
   - feature_callouts: 1–3 short labels (≤ 22 chars each) anchored to the zones above,
                  each with a one-line `note` explaining the benefit. These can be drawn
                  as small annotation badges over the device frame.

3. ART DIRECTION (must pass WCAG AA contrast against the caption text)
   - Choose a background that complements the screenshot's dominant hue WITHOUT clashing.
     Prefer a tasteful 2-stop linear gradient in a deep, premium tone (the app's accent
     is blue #3B82F6; health=pink, motion=orange, environment=green, logger=red).
   - text_color: pick #FFFFFF or #0B0B0F so the caption is high-contrast on the background.
   - accent_color: a vivid color for the callout badges / underline, harmonizing with the page.
   - caption_position: "top" if the screenshot's important content sits low, else "bottom".

CONSTRAINTS
   - Truthful: never claim features not visible or implied by the app description.
   - Distinct: headlines across pages must not repeat the same opening word.
   - Localizable: avoid idioms that won't translate; keep within the char limits.
```

## SCHEMA (the model must return exactly this shape)

```json
{
  "page": "dashboard",
  "headline": "See every sensor, live",
  "subheadline": "21 iPhone sensors — motion, GPS, health & more in real time.",
  "feature_callouts": [
    {
      "label": "Live charts",
      "note": "Smooth, high-rate plots for every signal.",
      "zone": { "x": 0.06, "y": 0.30, "w": 0.88, "h": 0.18 }
    },
    {
      "label": "At-a-glance tiles",
      "note": "Tap any tile for full detail.",
      "zone": { "x": 0.06, "y": 0.52, "w": 0.88, "h": 0.34 }
    }
  ],
  "background": {
    "type": "linear-gradient",
    "colors": ["#071A2F", "#0B3A63"],
    "angle": 160
  },
  "text_color": "#FFFFFF",
  "accent_color": "#3B82F6",
  "caption_position": "top"
}
```

## Field contract (what `compose.py` actually reads)

| Field | Required | Used by compose.py for |
|-------|----------|------------------------|
| `headline` | ✅ | Large caption line |
| `subheadline` | ✅ | Secondary caption line |
| `background.colors` | ✅ | Canvas gradient (2 stops) |
| `background.angle` | optional (default 160) | Gradient direction in degrees |
| `text_color` | optional (default `#FFFFFF`) | Caption text fill |
| `accent_color` | optional (default `#3B82F6`) | Headline underline + callout badges |
| `caption_position` | optional (default `top`) | Caption band placement (`top`/`bottom`) |
| `feature_callouts[]` | optional | Annotation badges drawn over the device (`--callouts` flag) |
| `page` | optional | Sanity-check vs filename |

> Closing the loop: the JSON returned here is saved to `screenshot/copy/<page>.json` and
> read directly by `compose.py`. Keep the keys exactly as above.
