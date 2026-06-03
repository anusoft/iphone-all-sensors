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
python3 scripts/appstore/asc.py wait-build  --build-version 1        # poll until VALID
python3 scripts/appstore/asc.py encryption  --build-version 1        # usesNonExemptEncryption=false
python3 scripts/appstore/asc.py attach-build --build-version 1       # attach build to the editable version
python3 scripts/appstore/asc.py submit                               # cancels stale rejected sub, then submits
```

## Gotchas (carried over — verified)

- **`whatsNew` / release notes is NOT editable on a first, never-released version** — including
  it 409s the localization PATCH. Omit for v1.0 (fastlane already skips it; `asc.py set-text`
  only sends it if present in the JSON).
- **Age rating is app-INFO level**, not the version (`appInfos/{id}` → `ageRatingDeclaration`,
  UPDATE only). `asc.py age-rating-4plus` handles it.
- **Screenshot display types** (confirmed for this app): 6.9″ iPhone (1320×2868) → `APP_IPHONE_67`;
  13″ iPad (2064×2752) → `APP_IPAD_PRO_3GEN_129`.
- **Resubmitting after rejection**: the rejected `reviewSubmission` stays `UNRESOLVED_ISSUES` and
  locks the version (`ITEM_PART_OF_ANOTHER_SUBMISSION`). PATCH it `canceled:true`, then re-add the
  version to a fresh submission. `asc.py submit` does this automatically.
- **Encryption PATCH 409 "value already set"** is benign.
- **`xcrun altool`** is the upload path (the bare `altool` isn't on PATH; always invoke via `xcrun`).

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

- **Resolution Center** rejection reasons/replies.
- **App Privacy** data-collection ("nutrition label") — declare **Data Not Collected**.
- **Agreements / Tax / Banking** — sign the **Free Apps Agreement** (required before a free app
  goes live; not required to submit).
- **Pricing = Free / Availability** and the **release choice** (Manual recommended for v1.0) —
  see [10-categories-pricing-availability.md](10-categories-pricing-availability.md).
