---
name: sensors-show-off
description: Design prompt — "Show-Off Mode" full-screen presentation variants for every sensor detail view in the All Sensors iOS app. Feed this document into Claude Design to generate UI mockups and SwiftUI implementations for each variant.
type: design-spec
target: Claude Design
platform: iOS 17+ (iPhone primary, iPad secondary)
date: 2026-05-07
---

# All Sensors — "Show-Off Mode" Design Prompt

## 0. The brief (read this first)

You are designing **Show-Off Mode** for the *All Sensors* iOS app. Every sensor detail screen already has a normal "data + chart + readouts" layout. We are adding a button (top-right toolbar, icon `sparkles` or `play.tv`) that swaps the entire screen for a **full-bleed, theatrical, demo-grade visualization** of that sensor's live data.

Think: handing the phone to a friend to make them say "wait, is this real?". Think: the demo Apple plays in retail stores. Think: instrument panels from cars, planes, submarines, satellites, spaceships. Think: wallpaper-quality motion graphics that *also* tell you exactly what the sensor is reporting.

Each sensor gets **3–5 switchable variants** the user can swipe between (horizontal page-style, with a pill indicator at the bottom). One sensor → many ways to admire it. One variant is "default", picked by us; the rest are unlockable through swiping.

This document defines:
- The shared chrome, motion, and constraints that make every variant feel like the same app.
- For each of the 21 sensors: the variant list, the visual concept, the data bindings, and the motion behavior.

Generate **one SwiftUI view per variant**, in the style of the existing project (`glassCard()`, `appBackground()`, `ThemeManager` colors, `LocalizationManager` keys), but with the gloves off — full-screen, edge-to-edge, no nav bar. The host wrapper handles paging and the dismiss gesture.

---

## 1. Global design system for Show-Off Mode

### 1.1 Layout & chrome
- **Status bar:** hidden in show-off mode. Re-show on dismiss.
- **Navigation bar:** hidden. Replace with a **floating top bar** that fades after 3 s of inactivity and re-appears on tap:
  - Left: small `xmark` chip on a blurred capsule — exits show-off mode.
  - Center: sensor name in monospaced uppercase, tracked +2 (e.g. `GYROSCOPE`).
  - Right: small `square.grid.3x3` chip — opens a sheet listing all variants for jump navigation.
- **Page indicator:** custom — small horizontal track with **named pills** (not just dots), e.g. `HUD · MIN/MAX · ALTIMAP · ORBIT`, the active one filled. Sits 24 pt above the bottom safe area.
- **Paging:** `TabView(.page(indexDisplayMode: .never))` style — horizontal swipe between variants. Every variant gets its own SwiftUI view; the parent does the paging.
- **Background:** every variant must own its background fully (not call `appBackground()`). Show-Off is meant to escape the chrome.

### 1.2 Typography
- Big numbers: **SF Pro Rounded, semibold, monospaced digits**, sized for one-glance readability from 1 m away (display 96–140 pt for "hero" values).
- Labels: **SF Compact, uppercase, tracked +2**, opacity 0.6, never larger than 14 pt.
- Secondary numbers: **SF Mono**, tabular figures, white at 0.7 opacity.
- No serif fonts. No emoji in the values themselves.

### 1.3 Color & material
- Each sensor has a **signature accent** (already used in normal mode — match it):
  Accelerometer `.blue`, Gyroscope `.indigo`, Magnetometer `.purple`, Device Motion `.teal`, Altimeter `.cyan`, Barometer `.mint`, Pedometer `.green`, Activity `.orange`, GPS `.red`, Heading `.pink`, Light `.yellow`, Proximity `.gray`, Torch `.orange`, Battery `.green`, Thermal `.red`, Disk `.brown`, Memory `.purple`, Processor `.blue`, Network `.cyan`, Bluetooth `.blue`, Camera `.gray`.
- Backgrounds: deep, near-black gradients tinted by the accent. Use `Material.ultraThinMaterial` only for floating chrome and HUD widgets, never as the dominant surface.
- Light mode: invert to a near-white gradient with the accent kept at full saturation. Never use pure `.black` or pure `.white`; always 0.04–0.06 offset.

### 1.4 Motion principles
- **Always responsive:** every variant must animate from real sensor data within one frame. No throttling beyond what the manager already provides (most are 100 Hz).
- **Smoothing:** wrap noisy values in a low-pass filter (`alpha = 0.15`) for visual smoothness; *never* smooth the displayed numbers (they should pop with sensor cadence).
- **Idle animations:** if the sensor is flat, layer a subtle ambient motion (slow rotating gradient, 30 s loop) so the screen never looks frozen.
- **Reduce Motion:** honour `accessibilityReduceMotion`. Replace 3D/parallax with crossfade; keep the data visible.

### 1.5 Accessibility
- Every hero value gets a `accessibilityLabel` that reads "<sensor>, <value>, <unit>".
- Minimum tap targets remain 44 pt even when chrome is hidden.
- VoiceOver should be able to traverse: dismiss → variant title → primary value(s) → secondary readout(s) → variant switcher.

### 1.6 Performance budget
- 60 fps on iPhone 12 and newer. Avoid `Canvas` for any variant that updates more than 30 Hz unless drawing fewer than ~200 primitives per frame.
- Heavy 3D (RealityKit) is allowed for at most one variant per sensor; it must auto-pause when off-screen.
- Camera-based variants (Magnetometer "Field Lines on Live Camera", Light "Lux Meter Camera") stream from `CameraSensorManager` and must release the session on exit.

### 1.7 Shared widgets (build once, reuse across variants)
- `HUDFrame` — hexagonal/rounded-rect glass border with corner brackets, animated scanline.
- `RadialGauge` — full-arc gauge with min/max ticks, current value sweep, peak-hold marker, configurable accent.
- `LiveSpark` — 256-sample running line graph that auto-scales Y, fixed time window (4 s), drawn with `Canvas`.
- `OdometerNumber` — flip-card / rolling digits for changing values (used by Pedometer, Disk, Network).
- `CompassRose` — 360° rose with cardinal letters, smooth angular interpolation.
- `PulseRing` — radiating concentric rings emitted at sensor cadence (used by Heart Rate, Bluetooth scan, Magnetometer).
- `TickerBar` — bottom strip showing min/max/avg with three columns, monospaced.

---

## 2. Per-sensor variant specs

> Format for each sensor:
> - **Accent / data sources** — the published properties and their units.
> - **Variant N — `NAME`** — concept, visual, motion, data binding, what makes it show-off.
>
> Generate one SwiftUI file per variant: `<Sensor>ShowOff_<VariantName>View.swift`. Wire them into a `<Sensor>ShowOffView` paged container.

---

### 2.1 GPS / Location  *(LocationSensorManager)*

**Accent:** `.red` over deep cobalt gradient.
**Data:** `latitude`, `longitude`, `altitude`, `speed` (m/s), `course`, `horizontalAccuracy`, `verticalAccuracy`, `floor`, `timestamp`, `authorizationDescription`.

#### Variant 1 — `HUD` *(default)*
Automotive head-up display. Centered hero: **speed in km/h** in 140-pt monospaced semibold, slowly tickering. Below it a thin horizontal bar shows current heading as a strip-compass (translates left/right with `course`). Below that, three columns: `ALT`, `H.ACC`, `V.ACC`. Top-right corner: tiny satellite count proxy (`fix quality` derived from `horizontalAccuracy < 10/30/100` → GREAT/OK/POOR with green/amber/red dot). Top-left: floor indicator if available. Background: a slow-drifting topographic contour pattern in red on near-black. When `speed > 0.5 m/s`, faint motion lines streak from edges toward center. When stationary, the speed digit gently pulses 0–1 at 1 Hz.

#### Variant 2 — `MIN · MAX · AVG`
Three giant stacked rows for **speed**: `MIN` (white at 0.6), `AVG` (white at full), `MAX` (red at full), each 80 pt monospaced, live updated. Right column: a vertical bar histogram of the last 60 seconds of speed samples, accent-filled. Bottom: a `RESET` chip (haptic medium impact). Below the trio: same three for **altitude** in a smaller secondary block. This variant is the runner/cyclist's brag screen — when you stop, the MAX freezes and glows.

#### Variant 3 — `ALTIMAP`
Full-screen Apple Maps `.standard` (or `.hybrid`) with the current pin pulsing red, course-arrow rotated to `course`. Overlay: a **bottom glass sheet** (40% height) with `LAT / LON / ALT / SPEED / FLOOR` in two columns, and the live `H.ACC` accuracy radius drawn around the pin. The sheet is dismissable with a downward swipe to reveal the map full-screen. Auto-recenter on the user every 4 s unless the map has been panned. The map heading-tracks if `headingAvailable`.

#### Variant 4 — `COORDINATES`
Pure typography. Latitude and longitude rendered as **monospaced 6-decimal coordinates** stacked center-screen, each 64 pt. The decimal portion ticks live with sensor updates, integers never (visual cue: position locked-in). Below: a small **decimal degrees → DMS** toggle. Bottom strip: timestamp ISO-8601 in mono, refreshing each fix. Background: a slow Mercator world map line-drawing in 0.04 white, with a single dot at the user's longitude band orbiting. Feels like a satellite ground station.

#### Variant 5 — `ORBIT`
Stylized "satellites overhead". Concentric circles representing accuracy bands (10 m, 30 m, 100 m). Small orbiting glyphs (sat icons) circle the rings at speeds proportional to `1 / horizontalAccuracy`. The center holds the cardinal `LAT, LON`. When `H.ACC` improves, satellites snap inward with a spring; when it degrades, they drift out. Useful and beautiful — you can *feel* the lock improving.

---

### 2.2 Heading / Compass  *(LocationSensorManager — heading fields)*

**Accent:** `.pink`.
**Data:** `heading` (CL value), `magneticHeading`, `trueHeading`, `headingAccuracy`.

#### Variant 1 — `COMPASS ROSE` *(default)*
Full-screen analog compass rose. The **rose rotates** opposite to heading (like Apple's Compass app). Center: **giant heading number** in degrees, 120 pt mono, with the cardinal letter (N/E/S/W) below. Outer ring: tick marks every 5°, labeled every 30°. A north-pointing red triangle floats at the top edge. Behind the rose: subtle hexagonal grid that drifts slightly with motion. Bottom: `TRUE` vs `MAG` toggle, accuracy chip (red if `headingAccuracy > 10°`).

#### Variant 2 — `RADAR SWEEP`
Submarine-style green-on-black radar. The sweep arm rotates at fixed 1 Hz, leaving a fading cone of phosphor. The current heading is a fixed pointer at top; the **rose rotates underneath**. Concentric rings labeled 30°/60°/90° from current heading. Tiny "pings" at cardinal letters when the sweep crosses them. Bottom-left: target lock readout `BRG: 247°`. This one is pure cosplay.

#### Variant 3 — `BEARING TO`
Choose-a-target screen. Default targets: **Magnetic North**, **True North**, **Mecca (Qibla)**, **a pinned coordinate** (user can long-press anywhere on the map in another variant to set). Renders a single arrow in the center, length 60% of screen, that always points at the chosen target relative to current heading. Distance to target shown in km if coordinate-based. When perfectly aligned (within 2°), the arrow turns gold and a single haptic tick fires.

#### Variant 4 — `DUAL DIAL`
Side-by-side dials: **Magnetic** (left, blue) and **True** (right, red), each as a tachometer-style half-arc. Below each, the numeric value. Between them, a thin vertical bar showing the *declination* — the angular difference, animated as it changes. Below: a tiny chart of declination over the last 30 s. For nerdy users.

---

### 2.3 Accelerometer  *(MotionSensorManager — accX/Y/Z)*

**Accent:** `.blue`.
**Data:** `accX`, `accY`, `accZ` in g.

#### Variant 1 — `G-FORCE METER` *(default)*
Race-car instrument cluster. Center: a **circular g-force ball** — a dot rides inside a 2-axis circle showing X/Y in g, with concentric rings at 0.5g, 1g, 1.5g, 2g. The Z-axis (vertical) is rendered as a vertical bar to the right. Below the ball: **peak-g hold** that glows for 1.5 s after each new max. Bottom ticker: `MAG` (vector magnitude), `MAX`, `RMS` (last 1 s). Background: subtle carbon-fiber pattern.

#### Variant 2 — `BUBBLE LEVEL`
The phone becomes a workshop spirit level. Two bubbles: a **circular bubble** for X/Y tilt (gravity component) and a **horizontal bubble strip** for one selectable axis. Bubbles physically wobble with damped spring physics. When perfectly level (within 0.5°), the screen flashes green and emits one haptic tick. Numeric tilt readout in degrees on the side.

#### Variant 3 — `OSCILLOSCOPE`
Three stacked oscilloscope traces (X red, Y green, Z blue) on a phosphor-green grid, time-base 4 s, auto-scale Y. Drawn with `Canvas`. Trigger line at user-selectable g threshold (chip on the right). When triggered, the trace freezes and pulses for 0.5 s. Top-right: FFT preview thumbnail — the dominant frequency in Hz of the last 256 samples (good for showing engine vibration, walking cadence, etc.).

#### Variant 4 — `SHAKE-O-METER`
Big single number: **shake intensity** in m/s² (vector magnitude minus 1 g), auto-scaling between `STILL`, `LIGHT`, `MODERATE`, `WILD`, `SEISMIC`. Around it, a Richter-style segmented arc fills as you shake harder. Background ripples reactively. Below: a "highest shake of the session" trophy plaque. Pure crowd-pleaser.

---

### 2.4 Gyroscope  *(MotionSensorManager — gyroX/Y/Z)*

**Accent:** `.indigo`.
**Data:** `gyroX`, `gyroY`, `gyroZ` in rad/s.

#### Variant 1 — `COCKPIT` *(default)*
Aircraft attitude indicator. Centered: an **artificial horizon** (split sky-blue / dirt-brown) that tilts with roll and shifts with pitch. Around it, three radial dials at 4-, 8-, 12-o'clock positions: **roll rate**, **pitch rate**, **yaw rate** in °/s. Above the horizon: a heading tape. Top corners: `G-LIM` (max rate hit) and `STALL` (when all three rates near zero — joke easter-egg). Top-center: faux call-sign `A11-S3N50R5` in mono. Behind everything: subtle riveted-aluminum bulkhead texture. Each rate dial has a peak-hold needle in red that decays back over 2 s.

#### Variant 2 — `GIMBAL`
A 3-ring gimbal rendered in SwiftUI 3D (rotation3DEffect). Each ring rotates with one axis — the inner ring shows the device, the middle ring rolls with X, the outer ring with Y, and a base disc rotates with Z. Numbers float beside each ring. When the device is steady, the rings settle with a satin sheen. When you spin it, they whip. Premium.

#### Variant 3 — `SPIN-O-METER`
Single giant tachometer (0–10 rad/s, redline at 6) showing **|ω|** = magnitude of angular velocity. The needle slings around. To the right, three small bar meters for X/Y/Z. Below: a "max spin" trophy that locks in the highest rate seen. Engine-rev sound effect optional (off by default). Tap-to-reset.

#### Variant 4 — `INTEGRATOR`
Show the *integral* of angular velocity over time — total degrees rotated on each axis since open. Three rolling odometer-style numbers. Shows you "this device has spun 14,212° clockwise around Z since you opened this view". Reset button. Surprisingly mesmerizing for fidgeters.

---

### 2.5 Magnetometer  *(MotionSensorManager — magX/Y/Z, calMagX/Y/Z, calMagAccuracy)*

**Accent:** `.purple` over violet/black.
**Data:** raw `magX/Y/Z` in µT, calibrated `calMagX/Y/Z`, `calMagAccuracy` enum (`magaccuracy.high/medium/low/unknown`).

#### Variant 1 — `FIELD STRENGTH` *(default)*
Center: a **giant glowing orb** whose size and pulse frequency scale with `|B|` (vector magnitude in µT). Around it, three thin orbital arcs tilted by the field direction. To the left and right, vertical bars for X/Y/Z. Top: numeric `|B|` and a **calibration badge** (LOW/MED/HIGH, color-coded). When near a magnet, the orb violently throbs and fades to red. Without calibration, the orb is greyed and a small "Move phone in figure-8" overlay nudges the user.

#### Variant 2 — `FIELD LINES` *(camera AR)*
Live rear-camera feed full-screen. Overlay: **flowing field-line particles** drifting in the direction of the calibrated field vector projected to screen plane. Density proportional to `|B|`. Particles emit from edges, cross the screen, fade. Brings invisible magnetism into reality. Numeric readout in a corner glass capsule. Requires camera permission; gracefully falls back to a synthetic background if not granted.

#### Variant 3 — `METAL DETECTOR`
Treasure-hunter mode. Big bullseye in the center, the inner dot scaling with how far `|B|` deviates from the **baseline** (sampled when the screen is opened). When the deviation is high, a Geiger-counter click track speeds up (haptic + optional audio). A peak-hold ring locks in the strongest pulse. Calibration banner if needed. The ultimate "find the keys in the couch" demo.

#### Variant 4 — `VECTOR`
Pure 3D arrow rendered with rotation3DEffect, pointing in the direction of the field vector relative to the device. Three orthogonal axes drawn as faint cross-lines. Length of the arrow proportional to magnitude. As you rotate the phone, the arrow holds its real-world direction. Below: numeric components in mono.

---

### 2.6 Device Motion  *(MotionSensorManager — roll/pitch/yaw, gravity, userAccel, quat, rotMat)*

**Accent:** `.teal`.
**Data:** `roll`, `pitch`, `yaw` (rad), `gravX/Y/Z`, `userAccX/Y/Z`, `quatW/X/Y/Z`, `rotMat`.

#### Variant 1 — `FLIGHT INSTRUMENT` *(default)*
Combined attitude+heading indicator. **Artificial horizon** with roll & pitch (like Gyro Cockpit but driven by *fused* device motion, smoother). To the right, a heading tape driven by `yaw`. Bottom strip: gravity vector visualization (a tiny ball under glass, "down" indicator). Top-left: load factor `1 + |userAccel|/g`. The whole panel has the feel of a Garmin G1000.

#### Variant 2 — `3D PHONE`
A photorealistic 3D iPhone model (or a clean stylized one — chamfered glass slab) centered in the scene, rotating in real time with `quaternion`. The model is anchored in world space; rotating your phone rotates the on-screen model identically. Around it, faint orthogonal axes labeled X/Y/Z. Below: roll/pitch/yaw readout in degrees. Pure "wait, how did you do that" moment.

#### Variant 3 — `GRAVITY WELL`
A grid of 256 dots that warp like a rubber sheet under gravity. The "well" deepest point follows `(gravX, gravY)`. As you tilt, the well rolls with you. A **single ball** at the screen center physically rolls into the well with damped physics. Tilt the phone vertically and the ball drops off-screen with a comedic *whoosh* haptic. Numeric readout in a corner.

#### Variant 4 — `QUATERNION`
For the math nerds. Four big numbers (W, X, Y, Z) of the orientation quaternion with mono rolling digits. Below: a tiny live 3D unit-sphere with a vector poking through it showing the rotation axis, length proportional to angle. Bottom: rotation matrix as a 3×3 grid that updates live, sub-pixel scale.

---

### 2.7 Altimeter  *(MotionSensorManager — relativeAltitude, pressure)*

**Accent:** `.cyan`.
**Data:** `relativeAltitude` (m, relative to first sample), `pressure` (kPa).

#### Variant 1 — `ALTITUDE TAPE` *(default)*
Aircraft altimeter style: a **vertical tape** down the right edge marked every 1 m, scrolling as altitude changes. A fixed pointer in the middle reads the current altitude. To the left, a **giant 3-digit altitude reading** (00.0 m). Top: pressure in hPa with a barometric trend arrow (↑/↓/—). Background: stratified gradient — darker as you go up, lighter as you go down (visual proxy for altitude). Bottom: peak high & low this session.

#### Variant 2 — `ELEVATOR`
The screen *is* an elevator panel. A floor display shows a number that increments/decrements as you ascend or descend (every 3 m = 1 floor). Big up/down arrows light when you're moving in that direction. A blueprint-style cross-section of a building down the side shows the current floor highlighted. Sound: optional "ding" on each floor change (off by default).

#### Variant 3 — `PRESSURE GAUGE`
A vintage brass barometer face — circular gauge labeled `STORMY · RAIN · CHANGE · FAIR · DRY`. Needle sweeps with pressure. Below: numeric kPa and the corresponding region. Around the dial: hairline marks every 0.1 kPa. Above: weather emoji optional.

#### Variant 4 — `STAIRS`
A side-on, scrolling staircase that builds upward each time `barometerElevationChange` increases by ~3 m and unbuilds when it drops. Visual log of your ascent. Pedometer's `floorsAscended/Descended` counters shown in the corner if available.

---

### 2.8 Barometer  *(MotionSensorManager — pressure, baseline, trend, weatherPrediction)*

**Accent:** `.mint`.
**Data:** `pressure` (kPa), `barometerBaseline`, `barometerElevationChange`, `barometerTrend`, `barometerWeatherPrediction`.

#### Variant 1 — `WEATHER STATION` *(default)*
A clean, minimalist nearest-thing-to-an-Apple-Weather panel. Hero: **trend arrow** (↑↑ / ↑ / — / ↓ / ↓↓) with a one-word forecast (`IMPROVING`, `STEADY`, `RAIN LIKELY`, etc., from `barometerWeatherPrediction`). Below: pressure in hPa, big mono. To the side: a 30-min line graph of pressure with annotated highs/lows. Background: gradient from sunny gold (high pressure) to slate blue (low pressure) tinted by current value.

#### Variant 2 — `STORM GLASS`
Animated decorative storm glass (like the Victorian instrument). Crystals form in patterns dictated by pressure trend — feathery for falling, clear for rising. Numeric pressure overlaid in a tiny corner capsule. Pure aesthetic; numbers are still readable.

#### Variant 3 — `ELEVATION DELTA`
Centered hero: **how much have you gone up/down** since the baseline, in meters, signed (`+12.4 m`). Below: barometric pressure. Side: the live elevation change graph from `barometerMaxDelta` over time, filled gradient. Useful for "how high is that hill" demos.

---

### 2.9 Pedometer  *(MotionSensorManager — steps, distance, floorsAscended/Descended, pace, cadence)*

**Accent:** `.green`.
**Data:** `steps` (count today), `distance` (m), `floorsAscended/Descended`, `pace` (s/m), `cadence` (steps/s).

#### Variant 1 — `BIG NUMBER` *(default)*
A huge **flip-card odometer** (140 pt) with the day's step count. Each step increments with a mechanical roll. Below: `DISTANCE` in km/mi (toggle), `FLOORS UP / DOWN`, `CADENCE` in steps/min. Background: a subtle running-track texture (faint white lanes on green) that pans slowly in the direction of motion if cadence > 0.

#### Variant 2 — `PACE BAR`
Marathon-runner style. A horizontal pace bar showing current pace (min/km), color-coded by zone (slow / steady / brisk / fast / sprint). Above it, current cadence in steps/min as a big number with a metronome dot pulsing in time. Below: distance and time-since-open with split table.

#### Variant 3 — `STREAK MAP`
A 7-day grid visualization (last 7 days), each day a vertical bar showing steps as a fraction of 10k goal. Today's bar pulses. Around it: total weekly steps, average. Pulled from HealthKit if authorized; falls back to in-session pedometer. (Reuses HealthSensorManager `stepCount`.)

#### Variant 4 — `STAIRMASTER`
For floors. Big vertical column on the right that builds a stack of glass floor tiles each time `floorsAscended` increments. Floors descended subtracts. Hero number: net floors. Side panel: total ascended, total descended. Animation: each new floor slides in from below with a small bounce.

---

### 2.10 Activity  *(MotionSensorManager — activityState, isWalking/Running/Cycling/Automotive/Stationary)*

**Accent:** `.orange`.
**Data:** `activityState` string, five booleans.

#### Variant 1 — `STATE BADGE` *(default)*
Center stage: a **massive, bold pictogram** of the current activity (figure walking / figure running / bicycle / car / pause), 200 pt SF Symbol, accent-tinted. Below: the activity name in tracked uppercase. Around it: five small inactive pictograms in a circle, the current one promoted to the center with a spring transition. At the bottom: a horizontal **timeline of activity states** for the last 10 minutes, color-coded segments — like an Apple Watch workout summary.

#### Variant 2 — `LIFE LOG`
Vertical timeline scrolling up: each activity change becomes a row with timestamp, duration, and pictogram. Most recent at the top. Subtotals per activity for the session at the bottom. Like a Quantified Self diary.

#### Variant 3 — `CONFIDENCE METER`
Five horizontal bars (walking / running / cycling / automotive / stationary), each filling proportionally to whether that boolean is true (binary, but animated). The dominant one glows. To the side, a single live "What you're probably doing" caption.

---

### 2.11 Battery  *(SystemSensorManager — batteryLevel, batteryState, isLowPowerModeEnabled)*

**Accent:** `.green` (charging) / `.yellow` (low) / `.red` (critical).
**Data:** `batteryLevel` (0–1), `batteryState` (.unknown/.unplugged/.charging/.full), `batteryStateKey`, `isLowPowerModeEnabled`.

#### Variant 1 — `LIQUID BATTERY` *(default)*
A giant battery silhouette (vertical, half the screen tall) filled with **animated liquid**: SwiftUI metaball-style sloshing fluid that responds to phone tilt (uses gravity from device motion). Color: green > 50%, yellow 20–50%, red < 20%. Big percentage label inside. Above: state badge (`CHARGING`, `FULL`, `ON BATTERY`). Below: low-power mode chip if active. Tilt the phone — the liquid sloshes. Mesmerizing.

#### Variant 2 — `RUNTIME ESTIMATE`
Center: estimated time remaining in the form `5h 23m`, big mono. (Estimate from current level + a moving average of drain rate over the session.) Below: instantaneous drain rate in %/hour, signed (negative for charging). A live line graph of battery level over the session. To the side: smaller readouts of state, low-power mode.

#### Variant 3 — `CHARGING ANIMATION`
Only meaningful when `batteryState == .charging`. The screen becomes a circuit board with electrons (small dots) flowing along traces from the bottom (USB-C port) up into a central pulsing cell. Speed of flow proportional to the rate of level change. When fully charged, the cell becomes a serene constant glow. When unplugged, an animation reverses (drain). Pure satisfying.

---

### 2.12 Thermal  *(SystemSensorManager — thermalState, thermalStateKey, isLowPowerModeEnabled)*

**Accent:** `.red`/`.orange`/`.yellow`/`.green` mapped to state.
**Data:** `thermalState` enum (`.nominal`, `.fair`, `.serious`, `.critical`).

#### Variant 1 — `THERMOMETER` *(default)*
A vertical glass thermometer in the center (illustrative; iOS does not expose temperature in °C). Mercury fill height maps to state: NOMINAL (cool blue, low), FAIR (green, mid-low), SERIOUS (orange, mid-high), CRITICAL (red, top, with rising heat-shimmer particles). Big text: state name. Below: low-power mode chip. Behind: heat haze refraction effect on `.serious`+ states.

#### Variant 2 — `RADIATOR GRID`
A grid of 64 hex tiles in the bg, each pulsing red proportionally to thermal state (all green when nominal, all red and pulsing when critical). Center: state name and a "since opened, time spent in each state" stacked bar. Cosmetic but informative.

#### Variant 3 — `COOLING CURVE`
A live time-series of thermal state (as 0–3 numeric) over the last 5 minutes. Annotates each step transition with a pill (`→ FAIR`, `→ SERIOUS`). Useful while running heavy workloads.

---

### 2.13 Disk  *(SystemSensorManager — totalDiskSpace, freeDiskSpace, usedDiskSpace)*

**Accent:** `.brown` (or warm earth).
**Data:** `totalDiskSpace`, `freeDiskSpace`, `usedDiskSpace` (Int64 bytes).

#### Variant 1 — `STORAGE WHEEL` *(default)*
A massive donut chart, used vs free, with the percentage in the center. Used arc segmented into a faux breakdown (`SYSTEM`, `APPS`, `MEDIA`, `OTHER` — all proportional to a fixed split since iOS doesn't expose categories; label the segments as estimates). Outer ring: total bytes. Below: `FREE` in big mono with auto-scaled units (GB / TB).

#### Variant 2 — `BYTES TICKER`
A massive odometer-style number showing **free bytes** down to the byte (auto-formatted: `108.43 GB`). The last digits flicker as the OS allocates and frees pages. Below: total, used. To the side: a tiny line graph of free space over the session, useful for noticing leaks.

#### Variant 3 — `BLUEPRINT`
A schematic floorplan-style diagram: total disk represented as a large rectangle, used as a smaller filled rectangle inside, with measurements drafted along the edges (`TOTAL: 256.00 GB · USED: 147.62 GB · FREE: 108.38 GB`). Faint architectural blueprint grid. Pure aesthetic but legible.

---

### 2.14 Memory  *(SystemSensorManager — physicalMemory + derived used/free via mach_task_basic_info or os_proc_available_memory)*

**Accent:** `.purple`.
**Data:** `physicalMemory` (UInt64 total). Derive *used* via `os_proc_available_memory()` or `task_info` (already wired in the project's diagnostics; if not, add a helper).

#### Variant 1 — `RAM BARS` *(default)*
Five horizontal bars stacked, each representing 20% of physical memory, filling up like a loading dock. Used memory paints them left-to-right with a glassy purple. Hero: **used / total** in GB, big mono. To the side: pressure indicator (`NORMAL` / `WARN` / `URGENT`) from `os_proc_*` thresholds.

#### Variant 2 — `MEMORY MAP`
A grid of 1,024 small squares (32×32). Each represents `total / 1024` of memory. Filled squares = used; squares animate as the live used value changes. Looks like a defrag screen from the 90s. Cult favorite.

#### Variant 3 — `PRESSURE PULSE`
A heart-rate-style pulse line driven by memory pressure events. Each warn or urgent notification fires a spike. Background ambient pulse at low amplitude. Numeric peak and current pressure level.

---

### 2.15 Processor  *(SystemSensorManager — processorCount, activeProcessorCount; derive load via host_processor_info)*

**Accent:** `.blue`.
**Data:** `processorCount`, `activeProcessorCount`. Derive per-core load (helper using `host_processor_info`).

#### Variant 1 — `CORE GRID` *(default)*
A grid of N cells (one per logical core), each cell a vertical bar showing live load 0–100%. Cells light up cyan with intensity matching load. Above: hero "**TOTAL: xx%**" and active/total core count. Background: subtle die-shot of an Apple silicon SoC, blurred.

#### Variant 2 — `CPU SPIKE`
A continuous line graph (sum across cores), 60 s window, with 3-σ spike highlighting. Color shifts red on >85% load. Side: top spike in last minute.

#### Variant 3 — `THREAD DANCE`
Each core is a little orbital dot revolving around the center. Speed of revolution = load. When a core spikes, its dot streaks brighter and longer. When idle, dots crawl. Aesthetic.

---

### 2.16 Bluetooth  *(ConnectivitySensorManager)*

**Accent:** `.blue` over inky navy.
**Data:** `bluetoothState`, `bluetoothStateText`, `discoveredPeripherals` ([CBPeripheral]), `connectedPeripherals`, `isScanning`.

#### Variant 1 — `RADAR` *(default)*
Submarine-radar take 2 (different from Heading's). Center is "you". As `discoveredPeripherals` arrives, each peripheral is plotted on the rings — distance is *fake* (we don't have RSSI distance, but we can map RSSI to ring radius if available; otherwise random within ring). Sweep arm rotates at 1 Hz, peripherals "ping" in as the arm crosses them. Tap a dot → name + UUID popover. Top-right: count of devices. Bottom: state pill (POWERED ON / OFF / UNAUTH).

#### Variant 2 — `DEVICE LIST DELUXE`
A large vertical scrolling list, each row a glass card with: device name (or `Unnamed` in italic), last-seen timestamp, signal-strength bars if RSSI available, connect/disconnect button. New rows slide in from the bottom with a gentle blue glow. Empty state: a wandering dot with `Scanning…`. Far prettier than Settings.

#### Variant 3 — `STATE BEACON`
Centered: a giant radiating Bluetooth glyph that **pulses** when scanning, sits steady when powered on but not scanning, dims when off, glows red on unauthorized. Around it, the count of discovered/connected. Minimal, but the pulse is hypnotic.

---

### 2.17 Network  *(ConnectivitySensorManager)*

**Accent:** `.cyan`.
**Data:** `networkType` (WiFi/Cellular/None), `isConnectedToNetwork`, `wifiSSID`, `wifiBSSID`, `wifiSignalStrength`, `cellularCarrier`, `cellularRadioTechnology`.

#### Variant 1 — `SIGNAL CITY` *(default)*
Skyline of glowing antennas. Tallest one is the active connection (Wi-Fi tower if WiFi, cell tower if cellular). Pulses outward at the cadence of connectivity. SSID/BSSID/Carrier displayed below as a sticker. Type pictogram top-center. Background: a slow city-grid pan.

#### Variant 2 — `LIVE THROUGHPUT`
Two big bars (UP / DOWN) with kbps live-ish indicators (estimated by sampling `URLSessionTaskMetrics` against a tiny test endpoint optionally; if no test, leave throughput hidden and surface only RTT to a known host). Below: latency to `1.1.1.1` updated every 2 s. Carrier and radio technology in a side capsule. Honest about what's measured vs unknown.

#### Variant 3 — `NETWORK TREE`
A tree diagram: device → router (SSID) → ISP (carrier or unknown) → public IP (fetched once from ipify or shown as `—`). Each node a glass capsule. Edges animate with packet pulses.

---

### 2.18 Camera *(read-only metadata)*  *(CameraSensorManager — capability flags, audio metadata)*

**Accent:** `.gray` over film-noir.
**Data:** `isFrontCameraAvailable`, `isRearCameraAvailable`, `isFlashAvailable`, `isTorchAvailable`, `torchLevel`, `maxZoomFactor`, `cameraAccessGranted`, `microphoneAccessGranted`, audio metadata.

#### Variant 1 — `LENS BOARD` *(default)*
A clean diagram of a camera "rig": rear lens, front lens, flash module, torch — each rendered as a circle/icon, lit (white) when available, dimmed when not. Around the lens: current `MAX ZOOM 10×` ring. Below: permission badges (camera ✓, mic ✓). Aesthetically like a product page.

#### Variant 2 — `LIVE VIEWFINDER + METADATA`
Live rear-camera preview (full-bleed). Overlay: corners with film-frame markers, focal-length ladder along the bottom (no actual focal length API for AVFoundation simplification — show the **zoom factor** instead). A floating sticker with all camera/mic capability flags. Tap to switch to front. Toggle torch on/off via a chip.

#### Variant 3 — `AUDIO LEVEL`
Even though it's a "Camera" view, the camera ships with audio metadata. So a vertical VU-meter showing live mic level (use AVAudioRecorder with `meteringEnabled`), audio session category, sample rate, channels. Pure pro-audio interface.

---

### 2.19 Light *(ambient brightness proxy)*  *(EnvironmentSensorManager — screenBrightness)*

**Accent:** `.yellow` to dark amber.
**Data:** `screenBrightness` (0–1; iOS doesn't expose ambient lux, but auto-brightness drives this and serves as a proxy).

> **Honesty banner (mandatory):** Show-Off Mode for Light displays a small chip explaining `Estimated from screen auto-brightness, not a true lux meter.`

#### Variant 1 — `LUX METER` *(default)*
A circular gauge labeled `DARK / DIM / NORMAL / BRIGHT / SUNLIT`, needle driven by `screenBrightness`. Big estimated lux number (mapped from brightness 0–1 to a log-scale 1–10000 lux with the disclaimer). Background tint shifts from black to white as the value rises.

#### Variant 2 — `LAMP`
The screen *is* the lamp. Background fully fills with a smoothly interpolated color from indigo → amber → white as brightness rises. Numeric small in the corner. Purely decorative; doubles as a flashlight in a pinch.

#### Variant 3 — `CAMERA LUX`
If the camera permission is granted, run a low-rate (5 Hz) capture and average pixel luminance from the preview to display a *more honest* relative-light reading. Disclaimer still present. Renders as a horizontal bar with hex luminance value.

---

### 2.20 Proximity  *(EnvironmentSensorManager — proximityState, isProximityMonitoringEnabled)*

**Accent:** `.gray` to white.
**Data:** `proximityState` boolean, `isProximityMonitoringEnabled`.

#### Variant 1 — `RIPPLE` *(default)*
Big concentric circles emanating outward from the center. When `proximityState` is true (something near), the circles snap to a tight, bright ring. When false, they fan out lazily. A simple word in the center: `NEAR` / `CLEAR`. Behind: faint hexagonal sonar grid. (Note: iOS only exposes binary near/far; the variant honors that.)

#### Variant 2 — `TOGGLE SCOREBOARD`
Like a basketball scoreboard. Two columns: `NEAR` and `FAR`, each a big mono counter. Increments each transition. Bottom: total transitions, longest streak in each state. Pure novelty.

#### Variant 3 — `EARPIECE TIMER`
When `NEAR`, a stopwatch starts. When `FAR`, it pauses. Display: total time near (lifetime of session). Useful for "how long has this been on my face" demos. Single-purpose.

---

### 2.21 Torch  *(EnvironmentSensorManager / CameraSensorManager — torchLevel, isTorchAvailable)*

**Accent:** `.orange`.
**Data:** `torchLevel` 0–1, `isTorchAvailable`.

#### Variant 1 — `BIG SWITCH` *(default)*
A massive vertical slider running the full screen height controlling `torchLevel` 0 to 1. The screen background brightens proportionally with a warm tungsten glow. A big numeric `LEVEL: 64%`. Haptic ticks every 10% as you drag. Below: torch availability badge.

#### Variant 2 — `LIGHTHOUSE`
The torch periodically pulses on and off in a configurable Morse pattern (default: SOS). Tap to send. Tap-and-hold for continuous. Pattern selector: SOS, blink, strobe (with epilepsy warning), heartbeat. *Functional* show-off.

#### Variant 3 — `COLOR TEMP`
Although the LED is fixed-temp, the *screen* fills with an accompanying color (warm/cool selector) at a chosen brightness. Marketed as a complete photographer's fill light. The torch level slider sits at the bottom.

---

## 3. Variant switcher behavior

- Swipe horizontally to advance/retreat between variants of the same sensor.
- Pinch-out (zoom out) to reach a **9-up grid** of all variants for *all* sensors — so the user can showcase the whole app in one swipe. Tap any thumbnail to jump.
- Long-press anywhere on a variant to take a **snapshot** to Photos (with disclaimer overlay watermarking the data and a "via All Sensors" footer).
- Triple-tap to toggle the floating chrome on/off without leaving the variant.

## 4. Empty/edge states

- Sensor unavailable on this device (e.g. no magnetometer in iPad Wi-Fi): replace the variant body with a clean "Not available on this device" card, but keep the styling and accent so the screen isn't ugly.
- Permission denied (camera/heading/health): show a glass card with the permission name and a "Grant access" button that deep-links to Settings.
- No data yet (e.g. no Bluetooth peripherals discovered): keep the variant alive with a tasteful "Searching…" animation rather than an empty rectangle.

## 5. Engineering hooks (don't design these, but know they exist)

- A `ShowOffHostView<Sensor>` wraps each sensor's variant TabView and owns:
  - Floating chrome auto-hide timer.
  - `UIScreen.main.brightness` is **not** modified.
  - Idle-disable: prevent screen sleep while in show-off mode (`UIApplication.shared.isIdleTimerDisabled = true`), restore on dismiss.
  - Orientation: lock to portrait by default; opt-in landscape per variant if it benefits (HUD, Cockpit, Altitude Tape).
  - Recording: a small "REC" chip that ties into the existing `LoggingService` to start logging the current sensor while showing off — so the user can demo *and* capture.

## 6. Deliverables expected from Claude Design

For each variant listed in §2:
1. A SwiftUI view file named `<Sensor>ShowOff_<VariantName>View.swift`, conforming to the conventions in §1.
2. A short visual mockup (annotated diagram or screenshot of the implementation in the simulator).
3. Notes on which existing `MotionSensorManager` / etc. fields are bound, and any new derived helpers needed (e.g. peak-hold, low-pass filter, integrator, FFT).
4. A 1-line entry to add to the variant index used by `ShowOffHostView<Sensor>`.

## 7. Tone reminders for the designer

- "Show-off" does not mean "cluttered". The very best variants are 90% empty space with one breathtaking element.
- Every variant must remain **truthful** — it's still a sensor app. No fake numbers, no dramatized scales without a disclaimer.
- Where iOS doesn't expose what people expect (lux, real Bluetooth distance, CPU temp in °C), say so plainly via the honesty chip rather than faking it.
- Variants should look like instruments designed by people who *use* the sensor — pilots for gyro/motion, hikers for altimeter, sailors for compass, runners for pedometer, photographers for torch. Borrow the visual language of those tools.
