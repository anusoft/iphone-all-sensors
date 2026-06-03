#!/usr/bin/env bash
#
# run.sh — ONE-SHOT App Store screenshot generation for "All Sensors".
#
# Auto-detects the best iPhone (and iPad) simulator, builds the app ONCE, captures
# every hero page, and composes final upload-ready images — zero manual steps:
#
#     ./screenshots/run.sh
#
# The only external step is the optional AI marketing copy: drop copy/<page>.json
# files in first (see prompts/marketing-copy.prompt.md) for custom taglines;
# otherwise compose uses built-in defaults so the run never blocks.
#
# Options:
#   --iphone <name>   Force iPhone simulator name      (default: best available)
#   --ipad   <name>   Force iPad simulator name        (default: best available)
#   --no-ipad         Skip the iPad slot
#   --no-build        Reuse the last build in .build/
#   --no-callouts     Don't draw feature-callout badges
#   --pages  <list>   Comma-separated pages            (default: all five)
#   --keep-booted     Leave simulators booted at the end
#   -h, --help        Show this help
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$REPO_DIR/iPhoneSensors/iPhoneSensors.xcodeproj"
SCHEME="iPhoneSensors"
DERIVED="$SCRIPT_DIR/.build"
PAGES="dashboard,motion,health,environment,logger"

IPHONE_NAME=""; IPAD_NAME=""
WANT_IPAD=1; DO_BUILD=1; CALLOUTS="--callouts"; KEEP_BOOTED=0

while [[ $# -gt 0 ]]; do case "$1" in
  --iphone)      IPHONE_NAME="$2"; shift 2 ;;
  --ipad)        IPAD_NAME="$2"; shift 2 ;;
  --no-ipad)     WANT_IPAD=0; shift ;;
  --no-build)    DO_BUILD=0; shift ;;
  --no-callouts) CALLOUTS=""; shift ;;
  --pages)       PAGES="$2"; shift 2 ;;
  --keep-booted) KEEP_BOOTED=1; shift ;;
  -h|--help)     sed -n '2,23p' "$0"; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac; done

log()  { printf '\033[1;36m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

command -v xcrun >/dev/null || die "xcrun not found — install Xcode command line tools."
command -v python3 >/dev/null || die "python3 not found."

# pick_device <family> [forced-name] → prints "<udid>\t<name>" of the best available sim
pick_device() {
  xcrun simctl list devices available -j | python3 -c "
import json,sys
family=sys.argv[1]; want=sys.argv[2] if len(sys.argv)>2 else ''
prefs={'iphone':['iPhone 16 Pro Max','iPhone 16 Plus','iPhone 15 Pro Max'],
       'ipad':['iPad Pro 13-inch (M4)','iPad Pro 13-inch (M5)','iPad Pro 12.9-inch (6th generation)']}
avail=[d for rt,ds in json.load(sys.stdin)['devices'].items() for d in ds if d.get('isAvailable')]
def emit(d): print(d['udid']+chr(9)+d['name']); sys.exit(0)
if want:
    for d in avail:
        if d['name']==want: emit(d)
    sys.exit(1)
for p in prefs.get(family,[]):
    for d in avail:
        if d['name']==p: emit(d)
key='iPad' if family=='ipad' else 'iPhone'
for d in avail:                                   # prefer the biggest of the family
    if key in d['name'] and ('Pro Max' in d['name'] or '13-inch' in d['name']): emit(d)
for d in avail:
    if key in d['name']: emit(d)
sys.exit(1)
" "$1" "${2:-}" 2>/dev/null || true
}

# ----- build once ------------------------------------------------------------
if [[ $DO_BUILD -eq 1 ]]; then
  log "Building $SCHEME once for the simulator…"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED" \
    build >/dev/null 2>&1 || die "Build failed — run xcodebuild manually to see errors."
fi
APP="$(/bin/ls -d "$DERIVED"/Build/Products/Debug-iphonesimulator/*.app 2>/dev/null | head -1)"
[[ -n "$APP" ]] || die "No .app in $DERIVED (drop --no-build or build first)."
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null || echo com.1moby.allsensors)"
ok "App: $(basename "$APP")  ($BUNDLE_ID)"

# ----- per-slot capture + compose --------------------------------------------
# OOM constraint on this Mac: only one simulator booted at a time. capture.sh shuts
# its device down when done, so slots run strictly sequentially.
run_slot() { # <udid> <name> <family> <preset>
  local udid="$1" name="$2" family="$3" preset="$4"
  echo; log "━━ $family slot: $name ━━"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
  xcrun simctl install "$udid" "$APP" >/dev/null || die "install failed on $name"
  ok "installed on $name"
  "$SCRIPT_DIR/capture.sh" --udid "$udid" --family "$family" --no-build \
      --pages "$PAGES" || die "capture.sh failed for $family"
  python3 "$SCRIPT_DIR/compose.py" --device "$preset" $CALLOUTS || die "compose.py failed for $preset"
}

DID_IPAD=0
IP="$(pick_device iphone "$IPHONE_NAME")"
[[ -n "$IP" ]] || die "No available iPhone simulator. Install one via Xcode ▸ Settings ▸ Components."
IFS=$'\t' read -r IP_UDID IP_NAME <<< "$IP"
[[ "$IP_NAME" == *"Pro Max"* ]] || warn "iPhone '$IP_NAME' is not a 6.9\" Pro Max — compose normalizes to 1320×2868, but device pixels are upscaled. Install 'iPhone 16 Pro Max' for pixel-perfect 6.9\" captures."
run_slot "$IP_UDID" "$IP_NAME" iphone iphone-6.9

if [[ $WANT_IPAD -eq 1 ]]; then
  PAD="$(pick_device ipad "$IPAD_NAME")"
  if [[ -n "$PAD" ]]; then
    IFS=$'\t' read -r PAD_UDID PAD_NAME <<< "$PAD"
    run_slot "$PAD_UDID" "$PAD_NAME" ipad ipad-13
    DID_IPAD=1
  else
    warn "No iPad simulator available — skipping iPad slot (--no-ipad to silence)."
  fi
fi

# ----- verification gate -----------------------------------------------------
echo; log "Verifying composed outputs…"
fail=0
verify() { # <folder> <W> <H>
  local folder="$1" W="$2" H="$3"
  IFS=',' read -r -a parr <<< "$PAGES"
  for pg in "${parr[@]}"; do
    local f="$SCRIPT_DIR/$folder/$pg.png"
    if [[ ! -s "$f" ]]; then warn "  MISSING $folder/$pg.png"; fail=1; continue; fi
    local dim
    dim="$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null \
        | awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w"x"h}')"
    if [[ "$dim" != "${W}x${H}" ]]; then warn "  WRONG SIZE $folder/$pg.png = $dim (want ${W}x${H})"; fail=1
    else ok "  $folder/$pg.png ($dim)"; fi
  done
}
verify iphone-6.9 1320 2868
[[ $DID_IPAD -eq 1 ]] && verify ipad-13 2064 2752

# ----- cleanup ---------------------------------------------------------------
if [[ $KEEP_BOOTED -eq 0 ]]; then
  xcrun simctl shutdown "$IP_UDID" >/dev/null 2>&1 || true
  [[ $DID_IPAD -eq 1 ]] && xcrun simctl shutdown "${PAD_UDID:-}" >/dev/null 2>&1 || true
fi

echo
if [[ $fail -eq 0 ]]; then
  ok "ONE-SHOT COMPLETE — every page composed and verified."
  echo "   Final assets: screenshots/iphone-6.9/*.png$([[ $DID_IPAD -eq 1 ]] && echo ' , screenshots/ipad-13/*.png')"
else
  die "One or more outputs were missing or the wrong size (see warnings above)."
fi
