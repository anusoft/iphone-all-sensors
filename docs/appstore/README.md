# App Store submission packet — All Sensors

This folder contains everything you need to fill in App Store Connect for v1.0.

Anything tagged **`[FILL: …]`** is something only you can answer (your real name, your domain, your demo Apple ID, your phone number). Search the folder for `[FILL` to find every input you still owe.

## Submission status

| File                                       | What it covers                                                                |
|--------------------------------------------|-------------------------------------------------------------------------------|
| [01-app-information.md](01-app-information.md) | App name, subtitle, bundle ID, primary/secondary category, support URLs        |
| [02-description.md](02-description.md)         | Long description (4 000 char limit) — copy-paste ready                          |
| [03-promotional-and-keywords.md](03-promotional-and-keywords.md) | Subtitle, promotional text, keywords (100 char), what's new                    |
| [04-app-privacy-labels.md](04-app-privacy-labels.md) | App Privacy "nutrition label" answers (data types, purposes, tracking)         |
| [05-privacy-policy.md](05-privacy-policy.md)   | Full privacy policy text — host this at the URL you give Apple                  |
| [06-support-page.md](06-support-page.md)       | Public support page content — host at your support URL                          |
| [07-review-information.md](07-review-information.md) | Notes for the reviewer + demo account + contact info                            |
| [08-age-rating.md](08-age-rating.md)           | Age-rating questionnaire answers                                               |
| [09-export-compliance.md](09-export-compliance.md) | Encryption / export compliance answers                                          |
| [10-categories-pricing-availability.md](10-categories-pricing-availability.md) | Category, price tier, country availability                                      |
| [11-build-and-screenshots.md](11-build-and-screenshots.md) | Build upload, app icon, screenshots, app preview                                |
| [12-final-checklist.md](12-final-checklist.md) | Every Apple form field, what to paste, where it lives                           |
| [13-api-publish-runbook.md](13-api-publish-runbook.md) | App Store Connect API build/upload/submit runbook and gotchas                   |
| [14-build-upload-submit-for-review.md](14-build-upload-submit-for-review.md) | Fast checklist for archiving, uploading, attaching, and submitting              |

## Critical "is-this-a-spam-app?" signals reviewers look for

App Store review rejects ~30% of submissions for spam-like signals. This packet is structured to neutralise each one:

1. **Generic copy** → [02](02-description.md) is specific about WHAT the app does, names exact iOS APIs (`CMMotionManager`, `CLLocationManager`), names the 21 sensors, and describes *who it's for*.
2. **No privacy posture** → [04](04-app-privacy-labels.md) declares "Data Not Collected" with a thoughtful caveat about HealthKit + sensor data staying on device. [05](05-privacy-policy.md) explains the local-only architecture in plain English.
3. **Generic reviewer notes** → [07](07-review-information.md) gives the reviewer a 3-step path to the headline feature (Show-Off Mode), which is unique and screenshotable.
4. **Permission descriptions that say "We need this"** → [01](01-app-information.md) §"Info.plist usage strings" lists each permission with a one-sentence honest reason. (These are already set in your Xcode build settings.)
5. **No support contact** → [06](06-support-page.md) gives a real public page with FAQ + contact form.
6. **No age rating attention** → [08](08-age-rating.md) walks through every question with the right answer for a sensor utility.

## Apple Developer Program account inputs you'll need

These never go in App Store Connect form fields, but you can't submit without them:

- Apple Developer Program membership (paid, $99/yr) under your real name or DUNS-registered org
- App Store Connect access for that team
- A signing certificate + provisioning profile for team `D62Y8JVXB9`
- Build uploaded via Xcode or the headless App Store Connect flow in [14](14-build-upload-submit-for-review.md)

## Order to fill in App Store Connect

1. Create the app record (App Information): bundle ID, SKU, primary language, name, [01](01-app-information.md)
2. Categories + age rating: [01](01-app-information.md), [08](08-age-rating.md)
3. Pricing & availability: [10](10-categories-pricing-availability.md)
4. App Privacy: [04](04-app-privacy-labels.md), [05](05-privacy-policy.md)
5. Upload build via Xcode or the headless flow in [14](14-build-upload-submit-for-review.md)
6. Version 1.0 page: paste in description / keywords / promo / what's new from [02](02-description.md), [03](03-promotional-and-keywords.md)
7. Screenshots: drag from `screenshots/iphone-6.9/` and `screenshots/ipad-13/` ([11](11-build-and-screenshots.md))
8. App Review Information: [07](07-review-information.md)
9. Export compliance: [09](09-export-compliance.md)
10. Submit for Review using [14](14-build-upload-submit-for-review.md) when automating

When the reviewer comes back with a question, the answer is already in [07](07-review-information.md) or [05](05-privacy-policy.md) — link them.
