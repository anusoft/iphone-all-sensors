# Repository Audit — All Sensors (iPhoneSensors)

_Audit date: 2026-06-11 · Branch: `main` · Auditor: principal-engineer review (read-only)_
_Evidence is cited as `path:line`. Each finding is tagged **fact** (directly observed) or **judgment** (interpretation). Unverified claims are labelled._

---

## Executive Summary

**Health grade: C+ (a well-engineered logging core bolted onto a shaky, partly-fake feature surface).**

All Sensors is a maturing, single-developer SwiftUI iOS/iPadOS app (~22.8k LOC Swift, 5 weeks old, 46 commits, 1.0 build 2 already submitted to the App Store). It is genuinely strong where it counts on privacy: **no networking, no analytics/3rd-party SDKs, no hardcoded secrets**, opt-in & default-off logging, a real privacy manifest, and a clean, dependency-injected, **unit-tested logging subsystem**. That core deserves to be preserved.

The grade is held back by a **two-speed codebase**: outside the logging subsystem sit several user-facing features that are shipped but do **not actually work** — the Siri/Shortcuts "Get Sensor Reading" intent returns hardcoded fake data, the "Export Sensor Data" intent is a no-op that reports success, and the home-screen widget can never receive real data (no app-group entitlement, nothing writes the shared keys). Two `DispatchSemaphore`-on-the-main-actor patterns are concurrency-broken (one is dead code; one silently neuters the terminate-time flush). Testing covers only the logging layer; there is no CI. None of these are hard to fix.

**Top 3 risks:** (1) Apple/App-Store reputational + Guideline 2.3.1 ("accurate metadata") / 5.x exposure from features that demonstrably misrepresent themselves (fake App Intents, placeholder widget advertised as "real-time"); (2) no CI + tests only on the logging slice means the next pbxproj-hand-edit or refactor can ship a regression silently; (3) main-thread-blocking semaphores are latent hangs.
**Top 3 opportunities:** (1) make-real-or-delete the three fake feature surfaces (≈1 day, high trust payoff); (2) add a CI workflow that builds + runs the existing tests (S, immediate safety net); (3) split the two god files and delete the dead `PermissionManager` (mechanical, de-risks everything downstream).

---

## Repo Map

**Purpose.** A SwiftUI iOS/iPadOS app that surfaces every iPhone/iPad sensor (motion, location, environment, health, system, camera, connectivity) with live readouts and charts, a theatrical "Show-Off Mode" (74 visualizations), and an opt-in data logger that exports CSV/JSON/SQLite. Fully on-device. Intended users: curious consumers + tinkerers; maturity = **indie consumer app in active App Store submission** (1.0 build 2). _(fact — CLAUDE.md, `Info.plist`, git log)_

**Stack.** Swift 5 language mode (`SWIFT_VERSION = 5.0`, `project.pbxproj:763`), SwiftUI + Combine + UIKit AppDelegate shim, iOS 17 deployment target (`project.pbxproj:759`). Single third-party dependency: **GRDB 7.10.0** (SQLite), pinned in `Package.resolved`. Frameworks: CoreMotion, CoreLocation, HealthKit, CoreBluetooth, AVFoundation, WidgetKit, AppIntents. Hand-written `project.pbxproj` (no xcodegen). _(fact)_

**Architecture sketch.**
```
iPhoneSensorsApp (@main)  ──@StateObject──>  7 sensor managers (CoreMotion/Location/…)
   │  injects via .environmentObject                 │ each exposes @Published readouts
   │                                                  └─ samplePublisher (Combine) ─┐
   ├─ LoggingService ────────────────────────────────────────────────────────────┘
   │     └─ SensorEventBus → LoggingCoordinator → Writers(CSV/JSON/SQLite) → LogStorageManager
   ├─ LocalizationManager (in-code 12-language dictionaries)
   ├─ DiagnosticManager / SensorRecorder / DataExportManager  (all in SensorManager.swift)
   └─ ScreenshotRouter (app:// deep link → ScreenshotHeroView, for store captures)
Widget target (separate process) ── reads UserDefaults(suiteName: group.com.iphone-sensors)
```

**Key directories (one line each).**
- `iPhoneSensors/iPhoneSensors/Services/` — sensor managers + `LocalizationManager` + the `Logging/` subsystem (the real engine).
- `iPhoneSensors/iPhoneSensors/Services/Logging/` — DI'd, tested persistence pipeline (bus, coordinator, writers, storage, session manager).
- `iPhoneSensors/iPhoneSensors/Views/` — `Dashboard/`, `Sensors/` (21 per-sensor detail views), `ShowOff/` (visualizations), `Logger/`, `Components/`, `Screenshots/`.
- `iPhoneSensors/iPhoneSensorsWidget/` — home-screen widget (separate target).
- `iPhoneSensors/iPhoneSensorsTests/` — 15 test files, ~460 LOC, **logging subsystem only**.
- `docs/` — 70 markdown files (features, App Store runbooks, screenshots). `screenshots/`, `fastlane/`, `Scripts/` — release tooling.

**The core 20% (where the real work — and the review effort — went):**
1. `Services/Logging/*` (12 files) — the data persistence/export pipeline. _Mature, tested._
2. The 7 `Services/*SensorManager.swift` — sensor acquisition. _Lower quality, untested._
3. `App/iPhoneSensorsApp.swift` + `Services/SensorManager.swift` — composition root & glue (and the bug nest).
4. `Services/LocalizationManager.swift` — 5,172 lines, touches every screen.

**Lighter review (acknowledged):** the 21 `Views/Sensors/*DetailView.swift`, all of `Views/ShowOff/*` (~4.5k LOC of visualization), `Views/Screenshots/`, and the `docs/`/`screenshots/`/`fastlane/` tooling were sampled, not read line-by-line.

**Surprising things.** (a) Multiple source files are several independent files **concatenated** — `SensorManager.swift` has 9 `import` lines and 4 top-level classes; `iPhoneSensorsApp.swift` mixes the App, AppDelegate, and 4 App Intents. (b) An entire 101-line `PermissionManager` class is **dead** (zero references). (c) Three user-facing features (2 App Intents + the widget) are shipped as **placeholders that pretend to work**.

---

## Audit Report

### Architecture & design

- **[High · judgment] God files: unrelated types concatenated into one source file.** `Services/SensorManager.swift` is 617 lines holding four distinct classes — `SensorManager` (`:4`), `DataExportManager` + `ShareSheet` (`:116`,`:253`), `SensorRecorder` + recording models (`:289`), and `DiagnosticManager` (`:447`) — with `import` statements repeated at lines 1, 100, 262, 417. `App/iPhoneSensorsApp.swift` similarly fuses the `App`, `AppDelegate` (`:56`), and four `AppIntent`s (`:101`–`:161`). _Consequence:_ navigation, code review, and merge-conflict surface all suffer; the file name lies about its contents.

- **[Medium · fact] Two divergent architectural styles in one app.** The `Logging/` subsystem uses constructor dependency injection (`LoggingService.init(storage:configStore:)`, `LoggingService.swift:24`), is documented, and is unit-tested. The sensor/permission/diagnostic layer uses global singletons (`SensorRecorder.shared`, `DiagnosticManager.shared`, `DataExportManager.shared`), `print` logging, and blocking semaphores. _Consequence:_ contributors must learn two idioms; the weaker half is where every correctness bug below lives.

- **[Medium · fact] Dead code.** `Services/PermissionManager.swift` (101 lines) is **never referenced** anywhere in the codebase (verified: no hits for `PermissionManager` outside its own definition, and none for its `check*Permission` methods). Inside `SensorRecorder.startRecording`, the `valueProvider` closure parameter is immediately discarded (`SensorManager.swift:300`, `_ = valueProvider`) and the recorder's `timer` is declared but **never scheduled** — so `recording.dataPoints` is always empty and `SensorRecorder.exportRecording` (`:354`) always exports an empty series. _Consequence:_ misleading surface area; the in-memory "recorder" silently records nothing (real recording is delegated to `LoggingService`).

### Code quality

- **[Medium · fact] 186 `print()` calls in production code**, concentrated in the sensor managers (`MotionSensorManager.swift` 44, `HealthSensorManager.swift` 33, `CameraSensorManager.swift` 25, `SystemSensorManager.swift` 20, …). No use of `os.Logger`/`OSLog`. _Consequence:_ unconditional stdout spam in release builds, no log levels/subsystems/privacy redaction, minor perf cost on hot sensor paths.

- **[Medium · judgment] `LocalizationManager.swift` is a 5,172-line Swift file of hand-maintained dictionaries** for 12 languages (~4,900 string entries; `:657` english, `:1193` thai, …). There are **no `.strings`/`.xcstrings`/`.lproj` catalogs** in the repo — localization is entirely in-code. _Consequence:_ slow type-checking of one giant literal, painful diffs/merges, no Xcode localization tooling, no String Catalog → App Store metadata sync, and translation drift is invisible to tooling (note the trio of `add_keys.py` codegen scripts that exist precisely to mutate this file).

- **[Low · fact] One-off codegen scripts committed at repo root.** `add_keys.py`, `add_radio_key.py`, `add_activity_unknown.py` are throwaway scripts that rewrite `LocalizationManager.swift`. _Consequence:_ root-level clutter; unclear which are still authoritative.

### Correctness — shipped features that do not work _(the headline group)_

- **[High · fact] Siri/Shortcuts "Get Sensor Reading" returns hardcoded fake data.** `GetSensorReadingIntent.getSensorValue` (`App/iPhoneSensorsApp.swift:113`–`125`) returns constant strings — `"0.98 G"`, GPS `"13.7563°N, 100.5018°E"` (Bangkok), `"85%"` battery — with the comment _"This would normally read from SensorManager … For now, return a placeholder"_ (`:114`–`115`). _Consequence:_ a user invoking the published Shortcut gets fabricated readings; this is exactly the kind of misrepresentation App Review penalizes (Guideline 2.3.1 / 5.x).

- **[High · fact] "Export Sensor Data" intent is a no-op that reports success.** `ExportSensorDataIntent.perform` (`:157`–`160`) does nothing and returns the dialog _"Sensor data exported successfully."_ _Consequence:_ the Shortcut claims success while exporting nothing.

- **[High · fact] Home-screen widget can never show real data.** `iPhoneSensorsWidget.swift:39` reads `UserDefaults(suiteName: "group.com.iphone-sensors")`, but: (a) **nothing in the app writes** the `widget_sensor_*` keys and there is no `WidgetCenter.reloadTimelines` call anywhere; (b) there is **no `com.apple.security.application-groups` entitlement** in the project (entitlements file contains only `healthkit`); (c) the group id `group.com.iphone-sensors` doesn't match the bundle namespace `com.1moby.allsensors`. So `getTimeline` always falls through to defaults — `"Accelerometer" / "0.00" / "G"` (`:40`–`43`) — yet the widget is advertised as _"Display real-time sensor data on your home screen."_ (`:168`). _Consequence:_ a permanently-static widget presented as live.

- **[High · fact/reasoning] Terminate-time flush is a silent no-op due to a main-actor/semaphore deadlock.** `AppDelegate.applicationWillTerminate` (`App/iPhoneSensorsApp.swift:59`–`66`) spawns `Task { @MainActor in await flush(); sem.signal() }` then blocks the **main thread** on `sem.wait(timeout: .now() + .milliseconds(200))`. The `@MainActor` task body needs the main thread to run, but the main thread is parked in `sem.wait` → the flush body cannot execute → the wait always times out at 200 ms and termination proceeds **without flushing**. (The app survives because a separate `willResignActive` flush exists at `LoggingService.swift:46`–`54`.) _Consequence:_ dead-weight code that looks like a safety net but isn't, plus a 200 ms hang on every termination.

- **[Medium · fact/reasoning] `PermissionManager.checkMotionPermission` blocks the main thread ~1s and always returns false.** `PermissionManager.swift:24`–`49` (a `@MainActor` class) calls `manager.startActivityUpdates(to: .main){…}` then `semaphore.wait()` on the main thread; the `.main` callback can't fire while main is blocked, so only the 1-second `asyncAfter` fallback signals, after which `granted` is still `false`. Currently latent because the class is dead code (above), but it is a landmine if ever wired up. _Consequence:_ guaranteed 1s UI freeze + wrong result if used.

### Security

- **[Medium · judgment] Bare `"app"` URL scheme.** `Info.plist` registers the deep-link scheme as literally `app` (`CFBundleURLSchemes` → `app`). This is maximally generic and trivially claimable by any other installed app; CLAUDE.md itself notes the collision. The handler (`screenshotRouter.handle`, `iPhoneSensorsApp.swift:36`) only routes into screenshot hero views — no sensitive action — so real-world impact is low, but it is poor hygiene and unreliable for its own intended use. _Recommend:_ namespace it (e.g. `allsensors://`).

- **[Low · fact] Location-stripping export relies on string heuristics.** `LoggingService.exportSessionStrippingLocation` (`:172`–`199`) removes location data by filename substring (`gps`/`heading`/`location`, `:184`) and `DELETE … WHERE sensor_id LIKE 'location.%'` (`:194`). Correct for current naming, but a future location-bearing sensor not matching those tokens would silently leak into a "stripped" export. _Recommend:_ derive the strip-set from `SensorID.category == .location` and add a regression test.

- **[Low · judgment] Privacy manifest vs. App Store listing mismatch.** `PrivacyInfo.xcprivacy` declares Health as **collected** (`NSPrivacyCollectedDataTypeHealth`, App-Functionality purpose, not linked/not tracking) while the App Store submission publishes **"Data Not Collected"** (CLAUDE.md). Defensible — data never leaves the device — but the two should be reconciled and the rationale documented to avoid a reviewer flag.

### Testing

- **[High · judgment] Coverage is narrow and lopsided; no CI.** 15 test files (~460 LOC) exercise **only** the logging subsystem — writers (CSV/JSON/SQLite), schema, config store, coordinator, session lifecycle, `SensorID`, `SensorPayload`. There are **zero** tests for the 7 sensor managers, data export, diagnostics, the App Intents, or the widget — i.e. none of the four High-severity correctness bugs above sit under any test. No `.github/workflows`, no other CI config. _Consequence:_ the fake-feature regressions shipped undetected; future hand-edits to `project.pbxproj` (per CLAUDE.md, a manual 4-section process) have no automated gate.

### Performance

Healthy — no action needed. Chart/series buffers are explicitly bounded (`SensorComponents.swift:794`–`796` trims to `maxPoints`; `MotionSensorManager.swift:179`–`180` caps history at 50); no unbounded `@Published` growth, no networking, no N+1, no obvious blocking I/O on the render path. The only main-thread blocks are the two semaphore bugs already listed under Correctness.

### Dependencies

Healthy. Single dependency **GRDB 7.10.0** — reputable, current, pinned via committed `Package.resolved` (revision `36e30a6…`). No transitive sprawl, no known-CVE surface introduced. **[Low · fact]** caveat: `SWIFT_VERSION = 5.0` despite heavy `@MainActor`/`async` usage, so Swift 6 strict-concurrency checking that would have flagged findings #10/#11 is off.

### DevEx & operations

- **[Medium · fact] No CI/build/test/lint automation.** No `.github/workflows`, no SwiftLint/swift-format config. Given the hand-maintained `project.pbxproj`, the absence of an automated build is the single biggest operational gap.
- **[Low · fact] No linter config** → style consistency (and the `print`-spam, force-unwraps) is unenforced.

### Documentation

Strong overall — 70 markdown docs, a thorough `CLAUDE.md`, feature references, and detailed App Store / fastlane / API-publish runbooks. **[Low]** the only doc defects are the privacy-manifest/listing reconciliation (above) and the root-level orphan codegen scripts.

### Strengths (preserve these)

1. **Privacy posture is real:** zero networking, zero analytics/3rd-party SDKs, zero hardcoded secrets (all verified by grep), a populated `PrivacyInfo.xcprivacy`, HealthKit **read-only**, logging **opt-in and default-off** (`LoggingService.swift:81`,`108`), and a location-stripping export path.
2. **The logging subsystem is exemplary** for this repo: dependency-injected, documented, and the only part with unit tests.
3. **Bounded buffers / no memory growth** on the live data paths.
4. **Lean, pinned, reputable dependency graph** (GRDB only).
5. **Excellent release documentation** and reproducible screenshot/submission tooling.

---

## Improvement Strategy

Five findings-clusters explain almost everything above.

**Theme 1 — "Real or delete": no feature in the binary may misrepresent itself.**
_Target state:_ every user-reachable surface (App Intents, widget, terminate flush) either returns genuine data or is removed before the next submission. _Principle:_ shipped ≠ stubbed; a placeholder that claims success is worse than an absent feature (and an App Review liability). _Done when:_ `GetSensorReadingIntent` reads live `SensorManager` values, `ExportSensorDataIntent` invokes `DataExportManager` (or both are removed), the widget shows app-written data via a real app group (or is removed), and the terminate-flush either works or is deleted. Signal: zero hardcoded placeholder returns in `App/`, widget renders a value the app wrote.

**Theme 2 — A safety net before any refactor.**
_Target state:_ CI builds the app + widget and runs the existing test bundle on every push; smoke tests exist for the sensor managers and the (now-real) App Intents/widget glue. _Principle:_ you cannot safely restructure a hand-edited `pbxproj` project without an automated build gate. _Done when:_ a green/red CI check exists and core non-logging paths have at least smoke coverage. Signal: "CI fails on build or test failure"; core-path coverage > 0 and trending up.

**Theme 3 — One concern per file; delete the dead.**
_Target state:_ `SensorManager.swift` and `iPhoneSensorsApp.swift` split so each type lives in its own file; `PermissionManager` and the no-op recorder paths removed. _Principle:_ files should name their contents; dead code is pure liability. _Done when:_ no source file contains more than one top-level class and no `import` appears twice in a file; `PermissionManager` is gone or revived-and-fixed. Signal: grep for duplicate `^import` per file returns nothing.

**Theme 4 — Use the platform's tooling for logging & localization (debt, not emergency).**
_Target state:_ `print` → `os.Logger` with subsystems; eventually migrate the in-code dictionaries to a String Catalog (`.xcstrings`). _Principle:_ platform tooling buys you log levels/privacy redaction and translation/metadata sync for free. _Done when:_ zero `print(` in `Services/`; (later) `LocalizationManager` backed by `.xcstrings`.

**Theme 5 — Tighten concurrency & hygiene.**
_Target state:_ remove main-thread semaphore blocks; namespace the URL scheme; reconcile the privacy manifest. _Principle:_ correctness on the main actor and honest store metadata. _Done when:_ no `DispatchSemaphore.wait()` on the main actor; scheme is `allsensors://`; manifest/listing rationale documented.

**Explicit trade-offs — what NOT to fix now and why:**
- **Do not migrate `LocalizationManager` to `.xcstrings` pre-launch** (XL, churns every screen, regression-prone while a build is in review). Defer to M3; the in-code approach works today.
- **Do not adopt Swift 6 strict concurrency now** — large mechanical churn; fix the two concrete concurrency bugs directly instead.
- **Do not build observability/crash-reporting infra** — this is an on-device indie app with a deliberate no-SDK privacy stance; `os.Logger` is the right ceiling. Adding a crash SDK would *break* a documented selling point.
- **Do not chase the `try?`/`print` long tail** beyond converting to `os.Logger` — the swallow-on-failure in the log writers is intentional and commented.

---

## Task Plan

Effort key: **S** <2h · **M** half-day · **L** 1–2 days · **XL** needs breakdown. "Risk" = risk of the change itself.

### ⚡ Quick wins (high impact, S effort) — do these first
- **QW1** Add a GitHub Actions workflow that `xcodebuild build` + `test`s the scheme (Theme 2 / T2 below).
- **QW2** Delete `PermissionManager.swift` (dead) and the dead `valueProvider`/`timer` paths in `SensorRecorder` (Theme 3 / T5).
- **QW3** Namespace the URL scheme `app` → `allsensors` in `Info.plist` + update `ScreenshotRouter` callers/docs (Theme 5).
- **QW4** Either delete `ExportSensorDataIntent`/the fake `GetSensorReadingIntent` body, or wire them to real managers (T1) — at minimum stop returning "success" from a no-op before the next submission.

### M0 — Safety net (build the gate before refactoring)
- **T0.1 · CI build+test workflow** — _S, low risk._ Add `.github/workflows/ci.yml`: checkout, select Xcode, `xcodebuild -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build test`. Affects: new file only. _Acceptance:_ PR shows a required check that fails on build or test failure. _Deps:_ none.
- **T0.2 · Smoke tests for the non-logging core** — _M, low risk._ Add tests asserting each sensor manager's `availability` flags and that `DataExportManager.exportCSV/JSON` produce non-empty, parseable output for a known snapshot. Affects: `iPhoneSensorsTests/`. _Acceptance:_ ≥1 test per sensor manager + export; all green in CI. _Deps:_ T0.1.

### M1 — Critical correctness (the "real or delete" cluster)
- **T1.1 · Make `GetSensorReadingIntent` return live data (or remove it).** _M, medium risk (App Intents + main-actor data access)._ Affects: `App/iPhoneSensorsApp.swift:101`–`126`, needs a shared accessor to current `SensorManager` readouts. _Acceptance:_ Shortcut returns the device's actual current reading; a test verifies non-placeholder output; if descoped, the intent is deleted and removed from any donated shortcuts. _Deps:_ T0.1.
- **T1.2 · Make `ExportSensorDataIntent` actually export (or remove it).** _S–M, medium risk._ Affects: `App/iPhoneSensorsApp.swift:153`–`161`. _Acceptance:_ intent invokes `DataExportManager` and returns a real file/URL, or is deleted; no path returns "success" without doing work. _Deps:_ T1.1 (shared accessor).
- **T1.3 · Fix or remove the home-screen widget.** _L, medium risk (entitlements + cross-process)._ Add a `com.apple.security.application-groups` entitlement to **both** targets with a correctly-namespaced id (`group.com.1moby.allsensors`), have the app write `widget_sensor_*` to that suite and call `WidgetCenter.shared.reloadTimelines`, and update `iPhoneSensorsWidget.swift:39`. Affects: entitlements (2 targets), `pbxproj`, app write-path, widget. _Acceptance:_ widget displays a value the app wrote within one refresh; if descoped, the widget target + its store-listing claim are removed. _Deps:_ T0.1.
- **T1.4 · Fix or delete the terminate-time flush.** _S, low risk._ Replace the semaphore-on-main-actor in `applicationWillTerminate` (`:59`–`66`) with a synchronous flush, or remove it and rely on the `willResignActive` flush. Affects: `App/iPhoneSensorsApp.swift`. _Acceptance:_ no `DispatchSemaphore.wait()` on the main actor; logged data survives a force-quit (manual verify). _Deps:_ none.

### M2 — High-leverage structure & observability
- **T2.1 · Split the two god files.** _M, low–medium risk (pbxproj edits per CLAUDE.md)._ Extract `DataExportManager`/`ShareSheet`, `SensorRecorder`, `DiagnosticManager` out of `SensorManager.swift`; extract the four App Intents out of `iPhoneSensorsApp.swift`. Affects: those 2 files + `pbxproj` (4 sections each). _Acceptance:_ one top-level type per file; build green in CI. _Deps:_ T0.1 (so the split is verified).
- **T2.2 · `print` → `os.Logger`.** _M, low risk._ Introduce a `Logger` per subsystem; replace the 186 `print(` calls (start with `Services/`). Affects: sensor managers + misc. _Acceptance:_ zero `print(` in `Services/`; release builds quiet by default. _Deps:_ none.
- **T2.3 · Harden location-stripping export + test.** _S, low risk._ Derive the strip-set from `SensorID.category == .location` instead of filename substrings (`LoggingService.swift:184`,`194`); add a test that a stripped session contains no location rows/files. _Acceptance:_ test passes; no substring heuristic remains. _Deps:_ T0.1.

### M3 — Quality & polish (defer; not launch-blocking)
- **T3.1 · Reconcile privacy manifest vs. "Data Not Collected"** — _S._ Document the rationale or align the manifest; affects `PrivacyInfo.xcprivacy` + `docs/appstore/`.
- **T3.2 · Add SwiftLint** with a minimal ruleset (force-unwrap, file length) wired into CI — _S._
- **T3.3 · Relocate the `add_*.py` codegen scripts** under `Scripts/` (or delete if superseded) — _S._
- **T3.4 · (XL — needs breakdown) Migrate `LocalizationManager` to a String Catalog (`.xcstrings`).** Do **not** start until a build is out of review; break per-language.

### Implementation sketches — top 3 tasks

**① T1.3 — Fix the widget (highest user-visible payoff, most moving parts).**
_Approach:_ create one App Group shared by app + widget, write the latest reading on a throttle, and reload the timeline.
_Key steps:_ (1) In the project, add capability `com.apple.security.application-groups` = `["group.com.1moby.allsensors"]` to **both** the app and widget targets (hand-edit the entitlements files + the two `*.entitlements` references and `CODE_SIGN_ENTITLEMENTS`/build phases in `pbxproj` — this is the riskiest part given the manual project format). (2) Add a tiny `WidgetBridge` that, on a ≥1/min throttle from the foreground sensor stream, writes `widget_sensor_name/value/unit/active` into `UserDefaults(suiteName: "group.com.1moby.allsensors")` and calls `WidgetCenter.shared.reloadTimelines(ofKind: "iPhoneSensorsWidget")`. (3) Update `iPhoneSensorsWidget.swift:39` to the new suite id. (4) Add a unit test that the bridge writes the expected keys.
_Gotchas:_ the suite id must be **byte-identical** in entitlement, writer, and reader; provisioning profiles must regenerate to include the App Group (will fail to install otherwise); don't write on every sensor tick (battery/IPC) — throttle. If this proves too heavy before the next submission, the honest fallback is removing the widget target and its store-listing line.

**② T1.1 — Real `GetSensorReadingIntent`.**
_Approach:_ expose a main-actor snapshot accessor and read it from the intent.
_Key steps:_ (1) Give `SensorManager` (or a small `@MainActor` shared snapshot holder updated by the managers) a `currentValue(for: SensorType) -> String` that formats the live `@Published` readouts (accelerometer magnitude, heading, battery, …). (2) In `perform()`, `await` that accessor instead of the hardcoded switch (`:113`–`125`). (3) Handle "sensor unavailable / permission not granted" explicitly (return a localized "unavailable" rather than a fake number). (4) Test asserts the returned string reflects an injected reading, not a constant.
_Gotchas:_ App Intents may run while the app is backgrounded/not launched — decide whether to briefly start the sensor or return "open the app first"; never fabricate. Keep formatting consistent with the in-app detail views.

**③ T0.1 — CI build+test (unblocks everything, do literally first).**
_Approach:_ minimal GitHub Actions job on macOS.
_Key steps:_ (1) `.github/workflows/ci.yml` on `push`/`pull_request`: `runs-on: macos-15`, `xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' clean build test`. (2) Cache SPM (`~/Library/Developer/Xcode/DerivedData` / SPM cache) for speed. (3) Mark the check required on `main`.
_Gotchas:_ the runner's default Xcode must support iOS 17 + the chosen simulator name (pin with `xcode-select`/`xcodes` and a simulator that exists on the image, e.g. iPhone 16 Pro Max on macos-15); the scheme must be **shared** (`xcshareddata/xcschemes` — verify `iPhoneSensors.xcscheme` is checked in, it is). First run will surface any test that assumed a local-only resource.

---

## Open Questions (need a human decision)

1. **App Intents & widget — fix or cut?** Are the Siri "Get Sensor Reading"/"Export" Shortcuts and the home-screen widget intended 1.0 features, or aspirational scaffolding? This decides whether M1 is "implement" or "delete + remove store-listing claims." (Either is fine; **shipping them as-is is not** — they misrepresent themselves.)
2. **Privacy stance for HealthKit:** is the App Store "Data Not Collected" declaration the deliberate final answer (justified by on-device-only), and should `PrivacyInfo.xcprivacy` be aligned to match, or kept as-is with documented rationale?
3. **Localization direction:** keep the in-code dictionary approach (fast to hand-edit, but unscalable and tooling-blind) or commit to a String Catalog migration (T3.4)? This is a real fork worth ~1 day later.
4. **Performance/refresh targets:** is the widget's 15-minute refresh and the app's live sampling cadence acceptable, or is there a battery budget to design against?
5. **Deprecation candidates:** confirm `PermissionManager` and the in-memory `SensorRecorder` data-point path are safe to delete (audit found no live callers, but the maintainer may know of reflection/Shortcuts usage not visible to grep).
6. **Is a CI runner / Apple Developer team available** to the project for automated builds (T0.1 needs a macOS runner; signing-free simulator build does not need secrets, which is the recommended scope)?

---

_End of audit. Generated read-only; no source files were modified._
