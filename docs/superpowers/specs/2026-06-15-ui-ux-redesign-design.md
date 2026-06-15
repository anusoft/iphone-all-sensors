# All Sensors UI/UX Redesign Design

Date: 2026-06-15
Status: Draft for user review

## Context

All Sensors is an iOS/iPadOS SwiftUI app for live hardware sensors, Show-Off Mode, diagnostics, HealthKit-backed readings, and opt-in local data logging. The current app already has adaptive card grids, native material surfaces, App Store screenshot surfaces, and a broad Show-Off Mode implementation.

This pass should not replace the app architecture. It should make the existing breadth easier to understand, improve first launch, and add reusable SwiftUI visual assets that make the app feel more polished without weakening privacy, HealthKit, or logging behavior.

## Goals

1. Make first launch more intuitive while preserving explicit consent and optional permissions.
2. Make the Sensors dashboard feel like a command center rather than a dense catalog.
3. Make the logger easier to understand at a glance, especially opt-in state, active session state, and per-category coverage.
4. Create reusable SwiftUI assets for hero panels, category treatments, status badges, empty states, and permission progress.
5. Improve App Store perceived polish by making product screens and generated screenshots share the same visual language.
6. Preserve Show-Off Mode and make it more discoverable instead of rebuilding every theatrical view.

## Non-Goals

1. Do not rewrite sensor managers, logging backend, HealthKit integration, App Intents, screenshot routing, or export writers.
2. Do not add Clinical Health Records.
3. Do not enable unjustified background modes.
4. Do not create an app-specific appearance setting that conflicts with the system color scheme.
5. Do not replace SF Symbols with static icon images unless a concept cannot be represented by a symbol.
6. Do not rebuild every Show-Off variant in this pass.

## Design Direction

Use a balanced system pass with everyday usability as the anchor:

1. First-run setup becomes a privacy-first guided path.
2. The dashboard becomes the central sensor command surface.
3. The logger becomes a status-and-control surface rather than a plain settings list.
4. Shared components establish a consistent visual language across dashboard, detail, logger, diagnostics, health, and screenshots.
5. Show-Off Mode remains the premium differentiator and gets clearer entry points.

The visual tone should be native iOS, instrument-inspired, and restrained. Normal app screens should use system-respecting backgrounds, semantic text colors, native materials, and SF Symbols. Show-Off Mode can remain immersive and full-bleed.

## First-Run Setup

The current permission flow is functional but long. Users see many sequential steps before reaching the app, which can make the app feel permission-heavy even though most permissions are optional and local.

Replace the carousel feel with a guided setup model:

1. A top privacy promise panel explains local processing, no analytics, no tracking, and optional sensors.
2. A visible progress header shows where the user is in setup.
3. Each permission step uses a concise permission card with a hero SF Symbol, title, value statement, enabled examples, primary continue button, secondary skip action, and optional or unavailable state when applicable.
4. HealthKit receives explicit medical-disclaimer language and keeps the existing HealthKit entitlement assumptions.
5. Completion summarizes what is enabled and what can be enabled later in Settings.

Planned components:

1. `PermissionProgressHeader`
2. `PermissionCapabilityCard`
3. `PrivacyPromisePanel`

Continue using `PermissionRequestView`, `SensorManager`, `LocalizationManager`, `@AppStorage("hasCompletedPermissionFlow")`, `consentAccepted`, and `consentGivenAt`. Permission request side effects stay unchanged.

Edge states:

1. If a permission is denied, the user can continue and the app shows unavailable states later.
2. If a permission API returns quickly because it was already decided, the step advances without appearing stuck.
3. If HealthKit is unavailable, the Health step explains that the app still works without health data.
4. Completion must not imply skipped permissions were granted.

## Dashboard

The dashboard contains many useful cards but users need stronger hierarchy: what is live, what is unavailable, what they should try first, and where Show-Off and logging live.

Make the top of the Sensors tab a command center:

1. `SensorHeroPanel` shows total readiness, current active sensor groups, and the strongest live signal available.
2. `QuickActionRail` provides clear entry points for Show-Off Mode, logging, diagnostics, and search.
3. Category sections show a category icon tile, availability count, short subtitle, and adaptive card grid.
4. Sensor cards show icon, name, live value or concise state, availability badge, and a Show-Off affordance for eligible sensors.
5. Search results keep a flat list but gain empty-state guidance and category hints.

Planned components:

1. `SensorHeroPanel`
2. `QuickActionRail`
3. `SensorCategoryHeader`
4. `SensorStatusBadge`
5. `DashboardEmptyState`

Use existing environment objects: `SensorManager`, `MotionSensorManager`, `LocationSensorManager`, `EnvironmentSensorManager`, `SystemSensorManager`, `ConnectivitySensorManager`, `CameraSensorManager`, `LoggingService`, and `LocalizationManager`.

The dashboard should derive presentation values in small local presentation structs instead of embedding large arrays directly in the view body.

Edge states:

1. Sensor unavailable: card remains visible but clearly marked unavailable.
2. Permission missing: card explains permission needed when applicable.
3. Data waiting: use waiting state without making zero values look broken.
4. Throttling: keep `ThrottleBanner`, aligned with the new status badge system.

## Logger

The current logger is accurate and privacy-safe but reads like configuration. Users need fast answers:

1. Is logging enabled?
2. Is a session running?
3. Which sensors are included?
4. Where do I view or export data?

Keep logging opt-in and preserve all existing controls, but reorganize the overview:

1. Top `LoggerHeroPanel` for master state, session state, elapsed time, enabled stream count, and output formats.
2. Primary session controls immediately below the hero.
3. Data viewer and settings as explicit action buttons with icons.
4. Category summary cards before per-sensor rows.
5. Per-sensor rows keep NavigationLink drill-down but gain clearer badges for off/on, format, and interval.

Planned components:

1. `LoggerHeroPanel`
2. `LoggerActionStrip`
3. `LoggerCategorySummaryCard`
4. `LoggerStreamBadge`

Continue using `LoggingService`, `LoggingConfigStore`, `SensorID`, `SensorCategory`, `PerStreamConfig`, and `LogFormat`. The master switch still uses `LoggingService.masterEnabledKey`; turning it off still stops active sessions.

Edge states:

1. Master disabled: show a calm opt-in explanation and keep configuration hidden or visually disabled.
2. Active session with no streams: show an explicit warning and next action.
3. Export or data viewer empty: explain the empty state instead of showing a blank list.

## Shared Visual Assets

The assets should be SwiftUI components rather than static images so they adapt to live data, light mode, dark mode, Dynamic Type, and iPad.

New or refined components:

1. `SensorHeroPanel`
2. `MetricPill`
3. `SensorStatusBadge`
4. `QuickActionTile`
5. `CategoryGlyphTile`
6. `PermissionProgressHeader`
7. `PrivacyPromisePanel`
8. `EmptyStatePanel`
9. `LoggerHeroPanel`
10. `LoggerCategorySummaryCard`

Style rules:

1. Use SF Symbols with hierarchical rendering for most icons.
2. Use semantic text colors: primary, secondary, tertiary.
3. Use native materials for cards and controls.
4. Preserve iOS 17 compatibility.
5. Support both light and dark appearances.
6. Preserve Dynamic Type behavior and avoid fixed small text for important content.
7. Minimum touch targets must be 44 by 44 points.

## Show-Off Mode Integration

Keep existing Show-Off variants and routing. Make Show-Off visible from the dashboard hero and eligible sensor cards, add clearer copy around Show-Off as a live demonstration mode, and ensure App Store screenshot surfaces continue to use the same visual language.

Do not rewrite each Show-Off variant as part of this pass. That belongs in a later theatrical-visualization pass.

## Architecture

Shared visual components live in `Views/Components`. Dashboard-specific presentation helpers live near `DashboardView`. Logger-specific presentation helpers live near `LoggerOverviewView`. Permission-specific components live near `PermissionRequestView` unless they become broadly reusable. Avoid adding new service dependencies for purely presentational state.

Add small value types where useful:

1. dashboard readiness snapshot
2. category availability summary
3. quick action description
4. logger category summary
5. permission capability description

These types should be deterministic and unit-testable where they contain non-trivial logic.

## Localization

1. New user-facing strings must go through `LocalizationManager`.
2. English, Thai, and Chinese should receive first-pass values where the existing localization dictionary supports them.
3. Avoid putting hardcoded text into generated visual assets.
4. Copy should be concise enough to fit in longer localized strings later.

## Accessibility

1. Preserve Dynamic Type and test at accessibility sizes.
2. Avoid color-only states; badges need text or symbols.
3. Use semantic colors for readable text.
4. Make action tiles and permission controls at least 44 by 44 points.
5. Add accessibility labels to icon-only actions.
6. Respect Reduce Motion in any new animation.
7. Keep skipped permissions navigable and understandable with VoiceOver.

## Testing and Verification

Build:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Focused tests:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

If full tests are too slow or simulator availability blocks them, run targeted test classes for presentation logic and affected managers.

Visual verification should inspect first-run setup, Sensors dashboard, Logger overview, light mode, dark mode, iPhone compact width, iPad regular width, and larger Dynamic Type. Use the existing screenshot pipeline when changes affect App Store screenshot surfaces.

## Acceptance Criteria

1. First-run setup clearly communicates local privacy, optional permissions, progress, skip behavior, and completion state.
2. Dashboard top area provides immediate readiness, live status, and major actions.
3. Sensor cards communicate active, waiting, unavailable, and permission-needed states without relying only on color.
4. Logger overview clearly shows master opt-in state, session state, enabled stream count, and data/settings actions.
5. New UI assets are reusable SwiftUI components and follow the app's material/background system.
6. No HealthKit entitlement regression and no Clinical Health Records entitlement is added.
7. No App Store privacy statement regression: logging remains opt-in and local.
8. The app builds on the iPhone simulator destination.
9. Changed screens are visually checked in light and dark appearances.
10. Existing Show-Off Mode remains accessible and more discoverable.

