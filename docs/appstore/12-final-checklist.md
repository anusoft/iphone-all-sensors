# 12 · Final submission checklist

Every form field in App Store Connect, what to paste, and where it's documented. Use this as your single tick-off list when you're ready to submit.

Search for `[FILL` to find every input you owe before submitting.

## Apple Developer account prerequisites

- [ ] Apple Developer Program membership active (`[FILL: team ID, currently 7K4XLR6VD4]`)
- [ ] Free Apps Agreement signed in App Store Connect → Agreements
- [ ] Tax form completed (`[FILL: W-9 / W-8BEN-E / W-8BEN]`) — only if you'll ever charge
- [ ] Bank account on file — only if paid
- [ ] App Store Connect user has the right role (Account Holder / Admin / App Manager)

## Create the app record

App Store Connect → My Apps → "+" → New App.

| Field              | Value                                | Source       |
|--------------------|--------------------------------------|--------------|
| Platform           | iOS                                  |              |
| Name               | `All Sensors`                        | [01](01-app-information.md) |
| Primary Language   | English (U.S.)                       | [01](01-app-information.md) |
| Bundle ID          | `com.1moby.allsensors`               | [01](01-app-information.md) |
| SKU                | `ALLSENSORS-IOS-1`                   | [01](01-app-information.md) |
| User Access        | Full Access                          |              |

## App Information panel

| Field                 | Value                                   | Source                  |
|-----------------------|------------------------------------------|-------------------------|
| Subtitle              | `Live data from 21 sensors`              | [03](03-promotional-and-keywords.md) |
| Privacy Policy URL    | `[FILL: https://...]`                    | [05](05-privacy-policy.md) |
| Category — Primary    | Utilities                                | [01](01-app-information.md) |
| Category — Secondary  | Developer Tools                          | [01](01-app-information.md) |
| Content Rights        | "Does NOT contain, show, or access third-party content" → check the box | |
| Age Rating            | 4+ (set via questionnaire)              | [08](08-age-rating.md)  |

## Pricing & Availability

| Field         | Value                                | Source                  |
|---------------|--------------------------------------|-------------------------|
| Price         | Free (Tier 0)                        | [10](10-categories-pricing-availability.md) |
| Availability  | All countries / regions              | [10](10-categories-pricing-availability.md) |
| Pre-orders    | Off                                  | [10](10-categories-pricing-availability.md) |
| Volume Purchase Program | Available with discount → Off | [10](10-categories-pricing-availability.md) |

## App Privacy panel

| Field                                  | Value             | Source                 |
|----------------------------------------|-------------------|------------------------|
| Data collection                        | None              | [04](04-app-privacy-labels.md) |
| Tracking                               | No                | [04](04-app-privacy-labels.md) |
| Privacy Policy URL                     | (same as App Info)| [05](05-privacy-policy.md)     |

## Version 1.0 page (iOS App)

| Field                | Value                                                          | Source                   |
|----------------------|----------------------------------------------------------------|--------------------------|
| What's New           | (paste from [03](03-promotional-and-keywords.md) "What's New") | [03](03-promotional-and-keywords.md) |
| Promotional Text     | (paste from [03](03-promotional-and-keywords.md))               | [03](03-promotional-and-keywords.md) |
| Description          | (paste from [02](02-description.md))                            | [02](02-description.md)  |
| Keywords             | `sensor,accelerometer,gyroscope,gps,compass,altimeter,barometer,magnetometer,pedometer,imu,logger,csv` | [03](03-promotional-and-keywords.md) |
| Support URL          | `[FILL: https://...]`                                           | [06](06-support-page.md) |
| Marketing URL        | `[FILL: optional, https://...]`                                 | [01](01-app-information.md) |
| Version              | `1.0`                                                           |                          |
| Copyright            | `2026 [FILL: legal name]`                                       | [01](01-app-information.md) |

### Screenshots

| Class            | Drag from                          | Count |
|------------------|------------------------------------|-------|
| iPhone 6.9"      | `screenshots/iphone-6.9/*.png`     | 5     |
| iPad 13"         | `screenshots/ipad-13/*.png`        | 5     |

Also accepted at smaller sizes if needed:
- iPhone 6.7" (1290 × 2796) — Apple auto-derives from 6.9" if not provided.
- iPad 12.9" (2048 × 2732) — Apple auto-derives from 13" if not provided.

### App Previews (optional)

If you record them per [11](11-build-and-screenshots.md):
- iPhone 6.9" preview: `[FILL: ./preview-iphone.mov]`
- iPad 13" preview: `[FILL: ./preview-ipad.mov]`

### Build

Upload via Xcode or the headless flow in [14-build-upload-submit-for-review.md](14-build-upload-submit-for-review.md).
After processing, attach the build to the editable version. The headless flow does this with
`scripts/appstore/asc.py attach-build --build-version <BUILD>`.

## App Review Information

| Field                  | Value                              | Source                   |
|------------------------|-------------------------------------|--------------------------|
| Sign-in required       | Off                                 | [07](07-review-information.md) |
| First name             | `[FILL]`                            | [07](07-review-information.md) |
| Last name              | `[FILL]`                            | [07](07-review-information.md) |
| Phone number           | `[FILL: +country code]`             | [07](07-review-information.md) |
| Email                  | `[FILL: yourname@yourdomain.com]`   | [07](07-review-information.md) |
| Notes                  | (paste block from [07](07-review-information.md))| [07](07-review-information.md) |
| Attachments            | walkthrough video (optional)        | [07](07-review-information.md) |

## Version Release

| Option                          | Pick |
|---------------------------------|------|
| Manually release this version   | Yes  |
| Automatic release               | No   |
| Schedule release                | No   |

## Export Compliance

For each build:

| Question                          | Answer | Source                  |
|-----------------------------------|--------|-------------------------|
| Uses encryption?                  | No (because `ITSAppUsesNonExemptEncryption=NO` in plist) | [09](09-export-compliance.md) |

If asked manually: see [09](09-export-compliance.md) for full answers.

## Submit for Review

App Store Connect → Version 1.0 → "Submit for Review", or automate with
[14-build-upload-submit-for-review.md](14-build-upload-submit-for-review.md).

Apple sends:

1. `Waiting for Review` — usually <24 hours.
2. `In Review` — usually <24 hours.
3. `Pending Developer Release` (you picked Manual) → press "Release this Version".
4. `Ready for Sale`.

## Post-launch

- [ ] Monitor reviews / ratings (App Store Connect → Ratings & Reviews)
- [ ] Respond to negative reviews directly via Connect
- [ ] Announce: post the App Store link on `[FILL: your channels — Twitter/Mastodon/blog/HackerNews]`
- [ ] Create a `[FILL: support email autoresponder]` so you don't ghost first emails
- [ ] Plan v1.0.1 — fix the real issues, ship within 2–4 weeks

## Files you still owe (search for `[FILL`)

| Where                                              | What                              |
|----------------------------------------------------|-----------------------------------|
| `01-app-information.md`                            | Privacy URL, Support URL, Marketing URL, Seller Name, Copyright holder |
| `05-privacy-policy.md`                             | Effective date, contact email, postal address |
| `06-support-page.md`                               | Support email, your first name, last updated date |
| `07-review-information.md`                         | First name, last name, phone, email, demo creds (only if forced) |
| `10-categories-pricing-availability.md`             | Tax form, bank account |
| `11-build-and-screenshots.md`                      | Source design path for icon |
| `12-final-checklist.md` (this file)                 | Channels you'll announce on |

Run this once you think you've filled everything:

```bash
grep -rn "\[FILL" docs/appstore/
```

If grep shows zero matches, you're ready to submit.
