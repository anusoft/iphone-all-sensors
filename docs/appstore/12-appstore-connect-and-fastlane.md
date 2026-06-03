# 12 · App Store Connect API & fastlane automation

How this project authenticates to App Store Connect and pushes the listing
(metadata + screenshots) and builds — and the one step that is still manual.

## TL;DR

- **You must create the app record once, by hand**, in the App Store Connect UI.
  The App Store Connect API has **no create-app endpoint** — `.p8` keys cannot make a
  new app. Everything *after* creation is automated with the key.
- **Bundle ID is already registered**: `com.1moby.allsensors` (name "All Sensors",
  resource id `USQ5NS3FGY`) — just pick it in the New App dialog.
- **Metadata source of truth lives in `docs/`**, not in `fastlane/`. `deliver` reads
  text straight from `docs/appstore/metadata/` (see paths below). Screenshots are the
  generated assets in `screenshots/` (see [11-build-and-screenshots.md](11-build-and-screenshots.md)).

## Auth — App Store Connect API key (.p8)

| Item | Value |
|------|-------|
| Key file | `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8` (admin key `Y7U2DJCZQK`) |
| Key ID | provided via `ASC_KEY_ID` env var |
| Issuer ID | provided via `ASC_ISSUER_ID` env var |

The `.p8` is the secret and stays **outside the repo** (and `*.p8` is gitignored
defensively). The issuer/key IDs are **not committed** — set them via env vars or a
gitignored `fastlane/.env` (template: [`fastlane/.env.sample`](../../fastlane/.env.sample)):

```bash
export ASC_KEY_ID=Y7U2DJCZQK
export ASC_ISSUER_ID=<your issuer id>
```

## Step 1 — create the app record (manual, once)

App Store Connect → **Apps → ＋ → New App**:

| Field | Value (consistent with [01-app-information.md](01-app-information.md)) |
|-------|------|
| Platform | iOS |
| Name | `All Sensors` |
| Primary language | English (U.S.) |
| Bundle ID | `com.1moby.allsensors` (already registered) |
| SKU | `ALLSENSORS-IOS-1` |

## Step 2 — push the listing (automated)

From the repo root, with the env vars set:

```bash
bundle exec fastlane metadata        # text metadata only (name/subtitle/description/keywords/…)
bundle exec fastlane screenshots     # stage + upload the generated screenshots
bundle exec fastlane store_listing   # both, in one shot (still no binary)
```

These use the API key, never auto-submit (`submit_for_review(false)`), and push to the
draft so you can review in the web UI.

## Step 3 — build & submit

Binary upload is **not** done by `deliver` here (`skip_binary_upload(true)`). Use
`gym` to archive + `pilot`/`deliver` to upload the `.ipa`, then submit from the UI or a
`deliver(submit_for_review: true)` run once the `TODO-FILL` items below are resolved.

## fastlane layout

| File | Purpose |
|------|---------|
| `fastlane/Appfile` | `app_identifier` only; auth is API-key based |
| `fastlane/Deliverfile` | shared `deliver` config — **single source for paths**: `metadata_path ./docs/appstore/metadata`, `screenshots_path ./fastlane/screenshots` |
| `fastlane/Fastfile` | `metadata` / `screenshots` / `store_listing` lanes + API-key helper |
| `docs/appstore/metadata/` | the actual metadata text `deliver` uploads (lives in docs/) |
| `fastlane/screenshots/` | staged at runtime from `screenshots/` — **gitignored** |

`fastlane/screenshots/en-US/` is populated by the `prepare_screenshots` lane, which copies
the 5 marketing pages from `screenshots/iphone-6.9/` (1320×2868) and `screenshots/ipad-13/`
(2064×2752) and skips the numbered Show-Off captures. `deliver` maps each to its device
class by dimensions.

## Metadata mapping (docs/appstore → deliver)

| deliver file | Source doc | Value |
|--------------|-----------|-------|
| `en-US/name.txt` | [01](01-app-information.md) | `All Sensors` |
| `en-US/subtitle.txt` | [03](03-promotional-and-keywords.md) | `Live data from 21 sensors` (26 chars) |
| `en-US/description.txt` | [02](02-description.md) | full v1.0 description |
| `en-US/keywords.txt` | [03](03-promotional-and-keywords.md) | sensor,accelerometer,… (100 chars) |
| `en-US/promotional_text.txt` | [03](03-promotional-and-keywords.md) | 170-char promo |
| `en-US/release_notes.txt` | [03](03-promotional-and-keywords.md) | v1.0 "What's New" |
| `primary_category.txt` | [01](01-app-information.md) | `UTILITIES` |
| `secondary_category.txt` | [01](01-app-information.md) | `DEVELOPER_TOOLS` |

### URLs (done — GitHub Pages)

Support / marketing / privacy URLs are **live** on GitHub Pages (repo serves `main:/docs`):

| Metadata | URL | Source |
|----------|-----|--------|
| `en-US/privacy_url.txt` | https://anusoft.github.io/iphone-all-sensors/privacy.html | `docs/privacy.html` |
| `en-US/support_url.txt` | https://anusoft.github.io/iphone-all-sensors/support.html | `docs/support.html` |
| `en-US/marketing_url.txt` | https://anusoft.github.io/iphone-all-sensors/ | `docs/index.html` |

`copyright.txt` = `2026 1Moby`. The page content uses developer `1Moby` / contact
`contact@1moby.com` / effective date `2026-06-03`.

### Contact emails — two distinct addresses

| Use | Email | Where |
|-----|-------|-------|
| **Public** (website, app, store listing) | `contact@1moby.com` | privacy.html / support.html / landing page |
| **Apple-internal** (App Review contact + reviewer notes) | `anu@1moby.com` | `metadata/review_information/` ([07](07-review-information.md)) |

### Still TODO before submission

- Create the **app record** in App Store Connect (manual — the API can't), then run
  `fastlane store_listing`.
- Make sure both mailboxes are monitored (`contact@1moby.com` public, `anu@1moby.com` for Apple).
- (Legal entity name `1Moby` confirmed; App Review contact = Anu Anu / +66819188052 / anu@1moby.com.)

### Consistency note

[01-app-information.md](01-app-information.md) originally listed the subtitle as
`Live data from 21 device sensors` (32 chars — over Apple's 30-char limit). The canonical
value is the 26-char `Live data from 21 sensors` from [03](03-promotional-and-keywords.md);
both docs and the `deliver` metadata now use it.
