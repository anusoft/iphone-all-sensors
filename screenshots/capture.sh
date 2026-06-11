#!/usr/bin/env bash
#
# capture.sh — Stage 1 of the App Store screenshot pipeline.
#
# Boots a target simulator, builds + installs the app, then for each page:
#   1. opens the deep link   allsensors://1moby.allsensors/screenshots/<page>
#   2. waits for the UI to render
#   3. captures a raw screenshot to  screenshots/raw/<family>/<page>.png
#
# It also pins the status bar to the classic Apple marketing state
# (9:41, full battery, full signal) so raw captures look App-Store clean.
#
# Usage:
#   ./screenshots/capture.sh [options]
#
# Options:
#   -d, --device <name>     Simulator device name   (default: "iPhone 16 Pro Max")
#       --udid   <udid>     Explicit simulator UDID (overrides --device resolution)
#   -f, --family <fam>      iphone|ipad             (default: inferred from device name)
#   -p, --pages  <list>     Comma-separated page list
#                           (default: "dashboard,motion,health,environment,logger")
#   -s, --scheme <name>     Xcode scheme            (default: "iPhoneSensors")
#   -o, --out    <dir>      Raw output directory     (default: <repo>/screenshots/raw/<family>)
#   -t, --settle <seconds>  Render settle time       (default: iphone 5s / ipad 9s)
#   -m, --method <m>        Invocation method        (default: launch)
#                             launch  → simctl launch ... --screenshot <page>
#                                       (deterministic; immune to URL-scheme chooser)
#                             openurl → simctl openurl allsensors://<host>/screenshots/<page>
#                                       (true deep link; requires this app to be the
#                                        sole claimant of the `allsensors://` scheme)
#       --appearance <l|d>  Force light/dark         (default: dark)
#       --no-build          Skip xcodebuild; reuse the already-installed app
#       --keep-booted       Do not shut the simulator down at the end
#   -h, --help              Show this help
#
# Examples:
#   ./screenshots/capture.sh                                   # all pages, iPhone 6.9"
#   ./screenshots/capture.sh -d "iPad Pro 13-inch (M5)"        # iPad capture
#   ./screenshots/capture.sh -p dashboard,health --appearance l
#
set -euo pipefail

# ----- defaults --------------------------------------------------------------
DEVICE="iPhone 16 Pro Max"
PAGES="dashboard,motion,health,environment,logger"
SCHEME="iPhoneSensors"
SETTLE=""                 # empty → auto per family (iphone 5s, ipad 9s — iPad cold-launch is slower)
APPEARANCE="dark"
DO_BUILD=1
KEEP_BOOTED=0
METHOD="launch"           # launch | openurl  (see --method)
HOST="1moby.allsensors"   # <namespace>.<app> — any host is accepted by the router
FAMILY=""                 # iphone | ipad — auto-inferred from the device name if empty
UDID_ARG=""               # explicit simulator UDID; overrides --device name resolution

# repo + project layout (script lives in <repo>/screenshots)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$REPO_DIR/iPhoneSensors"
OUT_DIR=""                # empty → <script>/raw/<family> (computed after device resolution)
DERIVED="$SCRIPT_DIR/.build"

# ----- arg parsing -----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)     DEVICE="$2"; shift 2 ;;
    --udid)          UDID_ARG="$2"; shift 2 ;;
    -f|--family)     FAMILY="$2"; shift 2 ;;
    -p|--pages)      PAGES="$2"; shift 2 ;;
    -s|--scheme)     SCHEME="$2"; shift 2 ;;
    -o|--out)        OUT_DIR="$2"; shift 2 ;;
    -t|--settle)     SETTLE="$2"; shift 2 ;;
    -m|--method)     METHOD="$2"; shift 2 ;;
    --appearance)    APPEARANCE="$2"; shift 2 ;;
    --no-build)      DO_BUILD=0; shift ;;
    --keep-booted)   KEEP_BOOTED=1; shift ;;
    -h|--help)       sed -n '2,44p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

case "$APPEARANCE" in
  l|light) APPEARANCE="light" ;;
  d|dark)  APPEARANCE="dark" ;;
  *) echo "--appearance must be l|light or d|dark" >&2; exit 2 ;;
esac

case "$METHOD" in
  launch|openurl) ;;
  *) echo "--method must be 'launch' or 'openurl'" >&2; exit 2 ;;
esac

log()  { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

command -v xcrun >/dev/null || die "xcrun not found — install Xcode command line tools."

# ----- resolve / boot the simulator -----------------------------------------
if [[ -n "$UDID_ARG" ]]; then
  UDID="$UDID_ARG"
  # Resolve the human name for logging + family inference.
  DEVICE="$(xcrun simctl list devices -j | /usr/bin/python3 -c "
import json,sys
want=sys.argv[1]
data=json.load(sys.stdin)
for runtime,devs in data['devices'].items():
    for d in devs:
        if d['udid']==want:
            print(d['name']); sys.exit(0)
sys.exit(0)
" "$UDID" 2>/dev/null || echo "$DEVICE")"
  log "Using simulator UDID: $UDID ($DEVICE)"
else
  log "Resolving simulator: $DEVICE"
  # Grab the UDID of the first *available* device whose name matches exactly.
  UDID="$(xcrun simctl list devices available -j \
          | /usr/bin/python3 -c "
import json,sys
want=sys.argv[1]
data=json.load(sys.stdin)
for runtime,devs in data['devices'].items():
    for d in devs:
        if d.get('isAvailable') and d['name']==want:
            print(d['udid']); sys.exit(0)
sys.exit(1)
" "$DEVICE" 2>/dev/null || true)"

  [[ -n "$UDID" ]] || die "No available simulator named \"$DEVICE\".
   List options with:  xcrun simctl list devices available
   For the required iPhone 6.9\" slot you need \"iPhone 16 Pro Max\"
   (install it via Xcode ▸ Settings ▸ Components if missing)."

  ok "Device UDID: $UDID"
fi

# ----- derive family, settle time, and raw output dir ------------------------
if [[ -z "$FAMILY" ]]; then
  case "$DEVICE" in
    *iPad*) FAMILY="ipad" ;;
    *)      FAMILY="iphone" ;;
  esac
fi
[[ -n "$SETTLE" ]] || { [[ "$FAMILY" == "ipad" ]] && SETTLE=9 || SETTLE=5; }
[[ -n "$OUT_DIR" ]] || OUT_DIR="$SCRIPT_DIR/raw/$FAMILY"
mkdir -p "$OUT_DIR"
log "Family: $FAMILY · settle: ${SETTLE}s · raw → ${OUT_DIR#$REPO_DIR/}"

BOOT_STATE="$(xcrun simctl list devices | grep "$UDID" | grep -oE '\((Booted|Shutdown)\)' | tr -d '()' || true)"
if [[ "$BOOT_STATE" != "Booted" ]]; then
  log "Booting simulator…"
  xcrun simctl boot "$UDID"
fi
open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
ok "Simulator booted"

# Force appearance for consistent screenshots.
xcrun simctl ui "$UDID" appearance "$APPEARANCE" >/dev/null 2>&1 || warn "Could not set appearance"

# ----- build + install -------------------------------------------------------
BUNDLE_ID="com.1moby.allsensors"
if [[ "$DO_BUILD" -eq 1 ]]; then
  log "Building $SCHEME (Debug) for the simulator…"
  xcodebuild \
    -project "$PROJECT_DIR/iPhoneSensors.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    build >/dev/null
  APP_PATH="$(/bin/ls -d "$DERIVED"/Build/Products/Debug-iphonesimulator/*.app 2>/dev/null | head -1)"
  [[ -n "$APP_PATH" ]] || die "Build succeeded but no .app found in $DERIVED"
  ok "Built: $(basename "$APP_PATH")"
  log "Installing app…"
  xcrun simctl install "$UDID" "$APP_PATH"
  # Read the real bundle id back from the built app for robustness.
  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || echo "$BUNDLE_ID")"
  ok "Installed $BUNDLE_ID"
else
  warn "--no-build: assuming $BUNDLE_ID is already installed on the simulator."
fi

# ----- status bar: classic 9:41 marketing state ------------------------------
log "Overriding status bar (9:41, full battery/signal)…"
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100 >/dev/null 2>&1 \
  || warn "status_bar override unsupported on this runtime (continuing)"

# ----- capture loop ----------------------------------------------------------
IFS=',' read -r -a PAGE_ARR <<< "$PAGES"
log "Capturing ${#PAGE_ARR[@]} page(s): ${PAGES}"
echo

for raw_page in "${PAGE_ARR[@]}"; do
  page="$(echo "$raw_page" | tr -d '[:space:]')"
  [[ -z "$page" ]] && continue
  url="allsensors://$HOST/screenshots/$page"
  out="$OUT_DIR/$page.png"

  log "[$page] terminating any prior instance…"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true

  if [[ "$METHOD" == "openurl" ]]; then
    log "[$page] openurl → $url"
    xcrun simctl openurl "$UDID" "$url"
  else
    log "[$page] launch → $BUNDLE_ID --screenshot $page"
    xcrun simctl launch "$UDID" "$BUNDLE_ID" --screenshot "$page" >/dev/null
  fi

  log "[$page] settling ${SETTLE}s for render…"
  sleep "$SETTLE"

  # `simctl io <device> screenshot <file>` is the portable form across Xcode versions.
  xcrun simctl io "$UDID" screenshot "$out" >/dev/null
  if [[ -f "$out" ]]; then
    dims="$(/usr/bin/sips -g pixelWidth -g pixelHeight "$out" 2>/dev/null | awk '/pixel/{print $2}' | paste -sd'x' -)"
    ok "[$page] saved raw/$FAMILY/$page.png  ($dims)"
  else
    warn "[$page] screenshot failed"
  fi
  echo
done

# ----- cleanup ---------------------------------------------------------------
xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true
if [[ "$KEEP_BOOTED" -eq 0 ]]; then
  log "Shutting simulator down…"
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
fi

ok "Done. Raw captures in: $OUT_DIR"
echo "   Next: run the Vision LLM prompt (prompts/marketing-vision-prompt.md) per image,"
echo "   then:  python3 screenshots/compose.py"
