# 14 - Build, upload, and submit for review

This is the operator checklist for turning the current All Sensors source tree into an
App Store Connect build and submitting the editable version for review. It captures the
working flow used for the 2026-06-08 resubmission of `1.0 (2)`.

For background and API gotchas, read [13-api-publish-runbook.md](13-api-publish-runbook.md).

## Constants

| Field | Value |
|---|---|
| Xcode project | `iPhoneSensors/iPhoneSensors.xcodeproj` |
| Scheme | `iPhoneSensors` |
| Bundle ID | `com.1moby.allsensors` |
| App Store Connect app ID | `6776145177` |
| Team ID | `D62Y8JVXB9` |
| App Store Connect key ID | `Y7U2DJCZQK` |
| Issuer ID | `69a6de71-ebf1-47e3-e053-5b8c7c11a4d1` |
| Key path | `~/.appstoreconnect/private_keys/AuthKey_Y7U2DJCZQK.p8` |

Do not commit the `.p8` key. The docs may name the key ID and path, but never the key
contents.

## 1. Pick the build number

Only change the build number the user asked for.

- Keep `MARKETING_VERSION` unchanged unless the user explicitly asks for a new app
  version.
- Update `CURRENT_PROJECT_VERSION` in both app target configurations in
  `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`.
- For the June 2026 resubmission, version stayed `1.0` and build changed to `2`.

Verify:

```bash
rg -n "CURRENT_PROJECT_VERSION|MARKETING_VERSION" \
  iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj
```

## 2. Run checks before archiving

Run the test suite on the same iPad-class simulator Apple used when practical:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M3)' test
```

For privacy-sensitive review fixes, also verify:

```bash
plutil -p iPhoneSensors/PrivacyInfo.xcprivacy
plutil -p iPhoneSensors/iPhoneSensors/iPhoneSensors.entitlements
plutil -p iPhoneSensors/iPhoneSensors/Info.plist
```

Expected invariants:

- `com.apple.developer.healthkit` remains enabled.
- `ITSAppUsesNonExemptEncryption` is `false` or absent only if you will run the
  per-build encryption declaration.
- No unused `UIBackgroundModes`.
- Permission pre-prompts use neutral action text such as `Continue`, not
  `Allow <permission> Access`.

## 3. Archive and export

Use a fresh local archive/export directory:

```bash
rm -rf build/AllSensors.xcarchive build/export

xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/AllSensors.xcarchive -allowProvisioningUpdates archive
```

Export with App Store Connect signing:

```bash
xcodebuild -exportArchive \
  -archivePath build/AllSensors.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_Y7U2DJCZQK.p8" \
  -authenticationKeyID Y7U2DJCZQK \
  -authenticationKeyIssuerID 69a6de71-ebf1-47e3-e053-5b8c7c11a4d1
```

Confirm the exported build:

```bash
find build/export -maxdepth 2 -type f -print
plutil -p build/export/DistributionSummary.plist
```

The distribution summary should show:

- `versionNumber` equals the marketing version.
- `buildNumber` equals the requested build number.
- `get-task-allow` is `0`.
- `com.apple.developer.healthkit` is `1`.
- Signing certificate is an Apple distribution certificate or cloud-managed Apple
  distribution certificate.

## 4. Upload the IPA

```bash
xcrun altool --upload-app \
  -f build/export/iPhoneSensors.ipa \
  -t ios \
  --apiKey Y7U2DJCZQK \
  --apiIssuer 69a6de71-ebf1-47e3-e053-5b8c7c11a4d1
```

Keep the Delivery UUID from the successful upload. App Store Connect may list the
processed build by a build ID matching that UUID.

## 5. Prepare metadata gates

Set the API env once:

```bash
export ASC_KEY_ID=Y7U2DJCZQK
export ASC_ISSUER_ID=69a6de71-ebf1-47e3-e053-5b8c7c11a4d1
```

Refresh the automatable gates:

```bash
python3 scripts/appstore/asc.py status
python3 scripts/appstore/asc.py content-rights
python3 scripts/appstore/asc.py price-free
python3 scripts/appstore/asc.py age-rating-4plus
```

If `ITSAppUsesNonExemptEncryption` is not set to `false` in Info.plist, also run:

```bash
python3 scripts/appstore/asc.py encryption --build-version <BUILD_NUMBER>
```

App Privacy is still a UI-only gate. For this app, the published answer is "Data Not
Collected":

```text
https://appstoreconnect.apple.com/apps/6776145177/distribution/privacy
```

## 6. Wait for processing and attach the build

```bash
python3 scripts/appstore/asc.py wait-build --build-version <BUILD_NUMBER>
python3 scripts/appstore/asc.py attach-build --build-version <BUILD_NUMBER>
python3 scripts/appstore/asc.py status
```

Do not submit until `status` shows the editable version has the new build attached.

## 7. Submit for review

Try the helper first:

```bash
python3 scripts/appstore/asc.py submit
python3 scripts/appstore/asc.py status
```

Success means `status` shows the editable version state as `WAITING_FOR_REVIEW`.

### Fallback when Apple returns 409 during submit

On 2026-06-08, `asc.py submit` canceled the stale rejected submission and created a new
`READY_FOR_REVIEW` submission, but the first item add returned `409`. Retrying the
review-submission item creation manually succeeded.

Use this sequence only when `status` still shows `PREPARE_FOR_SUBMISSION` after
`asc.py submit`:

```bash
# 1. Find the open READY_FOR_REVIEW review submission.
python3 scripts/appstore/asc.py raw GET \
  '/v1/reviewSubmissions?filter[app]=6776145177&limit=10'

# 2. Confirm it has no items or does not include the target version.
python3 scripts/appstore/asc.py raw GET \
  '/v1/reviewSubmissions/<SUBMISSION_ID>/items?include=appStoreVersion'

# 3. Add the appStoreVersion item.
python3 scripts/appstore/asc.py raw POST '/v1/reviewSubmissionItems' --data \
'{"data":{"type":"reviewSubmissionItems","relationships":{"reviewSubmission":{"data":{"type":"reviewSubmissions","id":"<SUBMISSION_ID>"}},"appStoreVersion":{"data":{"type":"appStoreVersions","id":"<APP_STORE_VERSION_ID>"}}}}}'

# 4. Submit the review submission.
python3 scripts/appstore/asc.py raw PATCH '/v1/reviewSubmissions/<SUBMISSION_ID>' --data \
'{"data":{"type":"reviewSubmissions","id":"<SUBMISSION_ID>","attributes":{"submitted":true}}}'

# 5. Verify live state.
python3 scripts/appstore/asc.py status
```

Expected final state:

```text
Editable version: 1.0 state= WAITING_FOR_REVIEW
Attached build: <NEW_BUILD_ID>
```

## Known good submission record

- 2026-06-03: `1.0 (1)` submitted, later rejected under Guideline 5.1.1(iv) for
  permission pre-prompt button wording.
- 2026-06-08: permission prompt copy fixed, build number bumped to `2`, tests passed,
  archive/export/upload succeeded, build `2` processed as `VALID`, build
  `c18fc459-0bc4-4b47-9585-2a0f81713c75` attached, review submission
  `11897c83-839a-49e8-94c8-9009e0a69200` entered `WAITING_FOR_REVIEW`.
