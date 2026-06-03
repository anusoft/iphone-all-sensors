# 13 · API-first publish runbook

Ported from the verified `qwen3-asr-swift` / Konjac runbook and adapted for **All Sensors**.
How to build, upload, and **submit for review** mostly headlessly via the App Store Connect
REST API. Pairs with [12-appstore-connect-and-fastlane.md](12-appstore-connect-and-fastlane.md)
(fastlane handles metadata + screenshots; this doc handles build + age-rating + submit).

## App facts

| | |
|---|---|
| Name / Bundle | All Sensors / `com.1moby.allsensors` |
| App ID (ASC) | `6776145177` · SKU `ALLSENSORS-IOS-1` |
| Team | `D62Y8JVXB9` |
| Version / build | `1.0` / `1` (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`) |
| Non-exempt encryption | `ITSAppUsesNonExemptEncryption` **not** in Info.plist → declare per-build (standard HTTPS only → **exempt/NO**). Optionally add the key to Info.plist to skip it. |

**Versioning policy:** never bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` unless the
user explicitly asks.

## Credentials

- **Admin** key `Y7U2DJCZQK` — needed for cloud-signing/cert + everything. App-Manager key
  `CQHFLUWF22` can upload but **cannot create the distribution certificate**.
- Issuer `69a6de71-ebf1-47e3-e053-5b8c7c11a4d1`. Keys: `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8`.
- Override via env: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_P8`.

Helper: **`scripts/appstore/asc.py`** (ES256-JWT, only needs `pip install cryptography`).

## Full release flow

### 1. Build the `.ipa`

**Option A — Xcode (chosen for v1.0):** Product ▸ Archive ▸ Distribute App ▸ App Store Connect ▸ Upload (uses your existing signing).

**Option B — headless (cloud signing via the ADMIN key, no Xcode UI):**
```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/AllSensors.xcarchive -allowProvisioningUpdates archive

# ExportOptions.plist: method=app-store-connect, teamID=D62Y8JVXB9,
#   signingStyle=automatic, destination=export, uploadSymbols=true,
#   manageAppVersionAndBuildNumber=false
xcodebuild -exportArchive -archivePath build/AllSensors.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_Y7U2DJCZQK.p8 \
  -authenticationKeyID Y7U2DJCZQK -authenticationKeyIssuerID 69a6de71-ebf1-47e3-e053-5b8c7c11a4d1
```

### 2. Upload the binary (if you used Option B)
```bash
xcrun altool --upload-app -f build/export/iPhoneSensors.ipa -t ios \
  --apiKey Y7U2DJCZQK --apiIssuer 69a6de71-ebf1-47e3-e053-5b8c7c11a4d1
```

### 3. Listing + age rating + attach + submit (via asc.py / fastlane)
```bash
export ASC_KEY_ID=Y7U2DJCZQK ASC_ISSUER_ID=69a6de71-ebf1-47e3-e053-5b8c7c11a4d1

# Metadata + screenshots: done by fastlane (see doc 12) —
#   fastlane store_listing   (reads docs/appstore/metadata + screenshots/)
# asc.py can also do them if needed:
python3 scripts/appstore/asc.py status
python3 scripts/appstore/asc.py age-rating-4plus                     # -> 4+ (all NONE/false)
python3 scripts/appstore/asc.py content-rights                       # DOES_NOT_USE_THIRD_PARTY_CONTENT
python3 scripts/appstore/asc.py price-free                           # create a $0 (Free) price schedule, base USA
python3 scripts/appstore/asc.py wait-build  --build-version 1        # poll until VALID
python3 scripts/appstore/asc.py encryption  --build-version 1        # only if Info.plist key absent (we set it)
python3 scripts/appstore/asc.py attach-build --build-version 1       # attach build to the editable version
# --> Do the manual App Privacy step in the UI here (see below), THEN:
python3 scripts/appstore/asc.py submit                               # cancels stale rejected sub, then submits
```

## Gotchas (carried over — verified)

- **`whatsNew` / release notes is NOT editable on a first, never-released version** — including
  it 409s the localization PATCH. Omit for v1.0 (fastlane already skips it; `asc.py set-text`
  only sends it if present in the JSON).
- **Age rating is app-INFO level**, not the version (`appInfos/{id}` → `ageRatingDeclaration`,
  UPDATE only; the resource has **no GET-instance**). `asc.py age-rating-4plus` handles it.
- **Age-rating schema expanded (2025):** the PATCH must now also include `ageAssurance`,
  `userGeneratedContent`, `lootBox`, `parentalControls`, `advertising`, `healthOrWellnessTopics`,
  `messagingAndChat` (all **booleans** → `false`) and `gunsOrOtherWeapons` (enum → `NONE`). A PATCH
  must send the **full required set** or it 409s ("missing required attribute"). `asc.py` now
  sends them all (verified 200 → 4+).
- **Screenshot display types** (confirmed for this app): 6.9″ iPhone (1320×2868) → `APP_IPHONE_67`;
  13″ iPad (2064×2752) → `APP_IPAD_PRO_3GEN_129`.
- **Resubmitting after rejection**: the rejected `reviewSubmission` stays `UNRESOLVED_ISSUES` and
  locks the version (`ITEM_PART_OF_ANOTHER_SUBMISSION`). PATCH it `canceled:true`, then re-add the
  version to a fresh submission. `asc.py submit` does this automatically.
- **Encryption PATCH 409 "value already set"** is benign.
- **`xcrun altool`** is the upload path (the bare `altool` isn't on PATH; always invoke via `xcrun`).
- **Unused `UIBackgroundModes` fails the UPLOAD** — `altool` rejected the build with
  *"Info.plist key 'BGTaskSchedulerPermittedIdentifiers' must contain … when 'UIBackgroundModes' has
  'processing'."* All Sensors registers no `BGTaskScheduler`/background-location/fetch, so the modes
  were unused; **removed `UIBackgroundModes` entirely** (foreground sensor reads are unaffected).
  Unused `location`/`fetch` also commonly trigger review rejection. Only re-add a mode if the code
  truly uses it (and `processing` needs `BGTaskSchedulerPermittedIdentifiers`).
- **`ITSAppUsesNonExemptEncryption=NO` in Info.plist** (added) → the build self-declares export
  compliance; no per-build `encryption` step and no export-compliance prompt at submit.
- **Submit add-item 409 `STATE_ERROR.ENTITY_STATE_INVALID` ("this resource cannot be reviewed")**
  is the API's *vague* catch-all for "the version has unmet required items" — it does **not**
  enumerate them. Open the version page / click **Add for Review** in the UI to see the red list.
  For this app the blockers were **App Privacy** + **Pricing** (now scripted via `price-free`).
- **App Privacy must be PUBLISHED, not just answered** — selecting "Data Not Collected" isn't
  enough; you must click **Publish** on the App Privacy page, and it takes a moment to propagate
  before `submit` succeeds.
- **Pricing & content-rights ARE API-automatable** (the older runbook called pricing manual):
  `asc.py content-rights` and `asc.py price-free` (the latter finds the territory's `$0`
  `appPricePoint` and POSTs an `appPriceSchedule` using the `${temp-id}` included-resource pattern).

## ⚠️ Guideline 4.3(a) "Design – Spam" risk — READ BEFORE SUBMITTING

This Apple Developer account ships **multiple apps**, which amplifies 4.3(a) scrutiny: Apple may
judge an app "not unique enough" (template/reskin, saturated category) — and "sensor viewer" is a
**crowded** category with many clones. This is **not** fixable by UI polish or a plain resubmit.

**Lead with All Sensors' genuine differentiation** (already in the reviewer notes, doc 07, and the
store description):
- **Show-Off Mode — 74 unique full-screen visualizations** across 21 sensors (flight HUDs, compass
  roses, gravity wells, oscilloscopes…), a single cohesive presentation layer no clone has.
- **Fully on-device / no backend / no analytics SDK / no ads** — every reading stays local.
- An integrated tool (live dashboard + per-sensor detail + **Logger** with CSV/JSON export +
  HealthKit + Siri Shortcuts), not a single-screen readout.

If rejected under 4.3(a): **Resolution Center replies are MANUAL** (no API) — paste the
differentiation argument there; don't resubmit unchanged.

## Still MANUAL (no reliable public API — do in the App Store Connect UI)

- **App Privacy** data-collection ("nutrition label") — answer "No data collected" and **Publish**.
  This is Admin-only and has no public API; it's the one step that gates `submit`. Direct URL:
  `https://appstoreconnect.apple.com/apps/6776145177/distribution/privacy`.
- **Resolution Center** rejection reasons/replies.
- **Agreements / Tax / Banking** — sign the **Free Apps Agreement** (required before a free app
  goes live; not required to submit).
- **Release choice** after approval (Manual recommended for v1.0) —
  see [10-categories-pricing-availability.md](10-categories-pricing-availability.md).
  *(Pricing = Free and content-rights are now scripted — see `asc.py price-free` / `content-rights`.)*

## Submission record

- **2026-06-03** — All Sensors **1.0 (build 1)** submitted via this flow → state
  `WAITING_FOR_REVIEW`. Headless archive/export/upload (cloud-signed, admin key) after fixing the
  `UIBackgroundModes` upload rejection; age-rating 4+, content-rights, Free pricing, review contact
  set via `asc.py`; App Privacy "Data Not Collected" published in the UI; submitted via `asc.py submit`.
