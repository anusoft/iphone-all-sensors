# All Sensors UI UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make All Sensors more intuitive and polished by adding reusable SwiftUI visual assets, improving first-run setup, elevating the dashboard into a command surface, and turning logger overview into a clear status/control screen.

**Architecture:** Keep the existing SwiftUI app architecture, sensor managers, HealthKit integration, logging backend, export writers, App Intents, and Show-Off Mode routing intact. Add deterministic presentation value types beside the views that consume them, and add reusable visual components to `Views/Components/SensorComponents.swift` so dashboard, logger, permission flow, and screenshots share one visual language.

**Tech Stack:** Swift 5, SwiftUI, iOS 17, XCTest, `@EnvironmentObject`, `@AppStorage`, SF Symbols, existing `LocalizationManager`, existing `LoggingService`, existing sensor manager environment objects.

---

## File Structure

- Modify `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift`: add `SensorVisualStatus`, `SensorStatusBadge`, `MetricPill`, `QuickActionTile`, `CategoryGlyphTile`, and `EmptyStatePanel`.
- Modify `iPhoneSensors/iPhoneSensors/Views/Components/PermissionRequestView.swift`: replace the centered carousel with guided setup components while preserving permission side effects.
- Modify `iPhoneSensors/iPhoneSensors/Views/Dashboard/DashboardView.swift`: add dashboard presentation summary, hero panel, quick actions, and a direct Show-Off sheet.
- Modify `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerOverviewView.swift`: add logger presentation summary, hero panel, category summaries, and a `ScrollView`-based status/control layout.
- Modify `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`: add English, Thai, and Chinese strings for the new user-facing UI.
- Modify `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`: add focused tests for deterministic presentation logic and required localization keys.

## Task 1: Shared Visual Asset Components

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write the failing test**

Append this test method to `SmokeTests`:

```swift
func testSensorVisualStatusPresentationIsTextBacked() {
    XCTAssertEqual(SensorVisualStatus.active.labelKey, "status.active")
    XCTAssertEqual(SensorVisualStatus.waiting.labelKey, "status.waiting")
    XCTAssertEqual(SensorVisualStatus.permissionNeeded.labelKey, "status.permissionNeeded")
    XCTAssertEqual(SensorVisualStatus.unavailable.labelKey, "status.unavailable")

    XCTAssertEqual(SensorVisualStatus.active.symbolName, "checkmark.circle.fill")
    XCTAssertEqual(SensorVisualStatus.waiting.symbolName, "clock.fill")
    XCTAssertEqual(SensorVisualStatus.permissionNeeded.symbolName, "hand.raised.fill")
    XCTAssertEqual(SensorVisualStatus.unavailable.symbolName, "xmark.circle.fill")
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testSensorVisualStatusPresentationIsTextBacked
```

Expected: FAIL because `SensorVisualStatus` is not defined.

- [ ] **Step 3: Add shared visual primitives**

Add this block in `SensorComponents.swift` after `StatusBadge`:

```swift
enum SensorVisualStatus: Equatable {
    case active
    case waiting
    case permissionNeeded
    case unavailable
    case optional
    case warning

    var labelKey: String {
        switch self {
        case .active: return "status.active"
        case .waiting: return "status.waiting"
        case .permissionNeeded: return "status.permissionNeeded"
        case .unavailable: return "status.unavailable"
        case .optional: return "status.optional"
        case .warning: return "diagnostic.warning"
        }
    }

    var symbolName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .waiting: return "clock.fill"
        case .permissionNeeded: return "hand.raised.fill"
        case .unavailable: return "xmark.circle.fill"
        case .optional: return "circle.dotted"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .waiting: return .orange
        case .permissionNeeded: return .blue
        case .unavailable: return .gray
        case .optional: return .secondary
        case .warning: return .yellow
        }
    }
}

struct SensorStatusBadge: View {
    let status: SensorVisualStatus
    var labelOverride: String?
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        Label(labelOverride ?? locManager.t(status.labelKey), systemImage: status.symbolName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .symbolRenderingMode(.hierarchical)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(status.color)
            .background(status.color.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QuickActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .padding(12)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)
        .accessibilityElement(children: .combine)
    }
}

struct CategoryGlyphTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var trailingText: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            if let trailingText {
                Text(trailingText)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12), in: Capsule())
            }
        }
    }
}

struct EmptyStatePanel: View {
    let title: String
    let message: String
    let icon: String
    var color: Color = .secondary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)
    }
}
```

- [ ] **Step 4: Use the new badge in `SensorCard`**

Replace `StatusBadge(text: locManager.t("status.unavailable"), color: .gray)` with `SensorStatusBadge(status: .unavailable)`.

- [ ] **Step 5: Run the targeted test and verify it passes**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testSensorVisualStatusPresentationIsTextBacked
```

Expected: PASS.

- [ ] **Step 6: Commit shared assets**

Run:

```bash
git add iPhoneSensors/iPhoneSensors/Views/Components/SensorComponents.swift iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "feat(ui): add shared sensor visual assets"
```

## Task 2: First-Run Guided Setup

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Views/Components/PermissionRequestView.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write the failing localization test**

Append this test method to `SmokeTests`:

```swift
func testGuidedSetupLocalizationKeysResolve() {
    let keys = [
        "setup.progress",
        "setup.privacy.local",
        "setup.privacy.noAnalytics",
        "setup.privacy.optional",
        "setup.enabledLater",
        "status.optional",
        "status.permissionNeeded",
        "diagnostic.warning"
    ]

    for language in [AppLanguage.english, .thai, .chinese] {
        for key in keys {
            XCTAssertNotEqual(
                Translations.get(key, language: language),
                key,
                "Missing \(language.rawValue).\(key)"
            )
        }
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testGuidedSetupLocalizationKeysResolve
```

Expected: FAIL because at least one new key returns itself.

- [ ] **Step 3: Add setup localization keys**

In `LocalizationManager.swift`, add these keys near existing permission and status strings in the English dictionary:

```swift
"setup.progress": "Step %d of %d",
"setup.privacy.local": "Processed on device",
"setup.privacy.noAnalytics": "No analytics or tracking",
"setup.privacy.optional": "Sensor permissions are optional",
"setup.enabledLater": "Skipped sensors can be enabled later in Settings.",
"status.optional": "Optional",
"status.permissionNeeded": "Permission needed",
"diagnostic.warning": "Warning",
```

Add these keys near the same translated section in the Thai dictionary:

```swift
"setup.progress": "ขั้นตอน %d จาก %d",
"setup.privacy.local": "ประมวลผลบนอุปกรณ์",
"setup.privacy.noAnalytics": "ไม่มีการวิเคราะห์หรือการติดตาม",
"setup.privacy.optional": "สิทธิ์เซ็นเซอร์เป็นทางเลือก",
"setup.enabledLater": "เซ็นเซอร์ที่ข้ามสามารถเปิดใช้ภายหลังในการตั้งค่า",
"status.optional": "ทางเลือก",
"status.permissionNeeded": "ต้องการสิทธิ์",
"diagnostic.warning": "คำเตือน",
```

Add these keys near the same translated section in the Chinese dictionary:

```swift
"setup.progress": "第 %d 步，共 %d 步",
"setup.privacy.local": "在设备上处理",
"setup.privacy.noAnalytics": "无分析或跟踪",
"setup.privacy.optional": "传感器权限是可选的",
"setup.enabledLater": "跳过的传感器稍后可在设置中启用。",
"status.optional": "可选",
"status.permissionNeeded": "需要权限",
"diagnostic.warning": "警告",
```

- [ ] **Step 4: Add guided setup components**

In `PermissionRequestView.swift`, add these types after `PermissionStep`:

```swift
struct PermissionProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let tint: Color
    @EnvironmentObject private var locManager: LocalizationManager

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep + 1) / Double(totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(format: locManager.t("setup.progress"), currentStep + 1, totalSteps))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(tint)
            }
            ProgressView(value: progress)
                .tint(tint)
        }
        .accessibilityElement(children: .combine)
    }
}

struct PrivacyPromisePanel: View {
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(locManager.t("setup.privacy.local"), systemImage: "lock.shield.fill")
            Label(locManager.t("setup.privacy.noAnalytics"), systemImage: "eye.slash.fill")
            Label(locManager.t("setup.privacy.optional"), systemImage: "checklist")
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .symbolRenderingMode(.hierarchical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .appMaterialSurface(cornerRadius: 16, material: .thinMaterial)
    }
}

struct PermissionCapabilityCard: View {
    let step: PermissionStep
    let isProcessing: Bool
    let onPrimary: () -> Void
    let onSkip: () -> Void
    let canSkip: Bool
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                GlowIcon(icon: step.icon, color: step.color, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if !step.subtitle.isEmpty {
                            Text(step.subtitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(step.color)
                                .lineLimit(1)
                        }
                        SensorStatusBadge(status: .optional)
                    }
                    Text(step.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(step.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(locManager.t("setup.enabledLater"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button(action: onPrimary) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(step.buttonTitle)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryButtonStyle(color: step.color))
                .disabled(isProcessing)

                if canSkip {
                    Button(action: onSkip) {
                        Text(locManager.t("permission.notNow"))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(isProcessing)
                }
            }
        }
        .padding(20)
        .appMaterialSurface(cornerRadius: 24, material: .regularMaterial)
    }
}
```

- [ ] **Step 5: Recompose the permission body**

Replace the existing inner `VStack(spacing: 0)` in `PermissionRequestView.body` with:

```swift
ScrollView {
    VStack(spacing: 18) {
        PermissionProgressHeader(
            currentStep: currentStep,
            totalSteps: steps.count,
            tint: steps[currentStep].color
        )

        PrivacyPromisePanel()

        PermissionCapabilityCard(
            step: steps[currentStep],
            isProcessing: isProcessing,
            onPrimary: handleMainButton,
            onSkip: skipStep,
            canSkip: currentStep > 0 && currentStep < steps.count - 1
        )

        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? steps[currentStep].color : Color.gray.opacity(0.28))
                    .frame(height: 5)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
        .accessibilityHidden(true)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 24)
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity)
}
```

Keep the existing background and all `requestLocation`, `requestMotion`, `requestCamera`, `requestMicrophone`, `requestBluetooth`, and `requestHealth` methods unchanged.

- [ ] **Step 6: Run targeted first-run tests**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testGuidedSetupLocalizationKeysResolve -only-testing:iPhoneSensorsTests/SmokeTests/testPermissionPromptActionTranslationsUseNeutralContinueCopy -only-testing:iPhoneSensorsTests/SmokeTests/testFirstRunShowsPermissionFlowAsDedicatedRootSurface
```

Expected: PASS.

- [ ] **Step 7: Commit guided setup**

Run:

```bash
git add iPhoneSensors/iPhoneSensors/Views/Components/PermissionRequestView.swift iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "feat(ui): redesign first-run setup"
```

## Task 3: Dashboard Command Center

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Views/Dashboard/DashboardView.swift`
- Modify: `iPhoneSensors/iPhoneSensors/App/ContentView.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write the failing dashboard summary test**

Append this test method to `SmokeTests`:

```swift
func testDashboardCommandCenterSummaryText() {
    let summary = DashboardCommandSummary(
        readiness: DashboardReadinessSnapshot(
            motion: .init(available: 7, total: 7),
            location: .init(available: 0, total: 2),
            environment: .init(available: 3, total: 3),
            system: .init(available: 5, total: 5),
            connectivity: .init(available: 2, total: 2),
            camera: .init(available: 2, total: 2)
        ),
        isLocationAuthorized: false,
        isNetworkConnected: true,
        isLoggingEnabled: true,
        isRecording: false
    )

    XCTAssertEqual(summary.readinessText, "19/21")
    XCTAssertEqual(summary.activeGroupCount, 5)
    XCTAssertEqual(summary.loggingStatusKey, "logger.sessionIdle")
    XCTAssertEqual(summary.strongestSignalKey, "status.permissionNeeded")
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testDashboardCommandCenterSummaryText
```

Expected: FAIL because `DashboardCommandSummary` is not defined.

- [ ] **Step 3: Add dashboard localization keys**

In `LocalizationManager.swift`, add these keys near existing dashboard and Show-Off strings in the English dictionary:

```swift
"dashboard.commandCenter": "Sensor Command Center",
"dashboard.commandCenter.subtitle": "Live readiness, logging, diagnostics, and Show-Off access in one place.",
"dashboard.activeGroups": "Active groups",
"showoff.title": "Show-Off Mode",
"showoff.subtitle": "Open a full-screen live sensor demo.",
"dashboard.diagnostics.subtitle": "Review sensor and permission health.",
"dashboard.search.subtitle": "Find a sensor by name or category.",
"search.emptyHint": "Try motion, location, camera, battery, or network.",
```

Add these keys near the same translated section in the Thai dictionary:

```swift
"dashboard.commandCenter": "ศูนย์ควบคุมเซ็นเซอร์",
"dashboard.commandCenter.subtitle": "ดูความพร้อม การบันทึก การวินิจฉัย และ Show-Off ได้ในที่เดียว",
"dashboard.activeGroups": "กลุ่มที่ใช้งาน",
"showoff.title": "โหมด Show-Off",
"showoff.subtitle": "เปิดเดโมเซ็นเซอร์สดแบบเต็มหน้าจอ",
"dashboard.diagnostics.subtitle": "ตรวจสอบสุขภาพเซ็นเซอร์และสิทธิ์",
"dashboard.search.subtitle": "ค้นหาเซ็นเซอร์ตามชื่อหรือหมวดหมู่",
"search.emptyHint": "ลองค้นหา motion, location, camera, battery หรือ network",
```

Add these keys near the same translated section in the Chinese dictionary:

```swift
"dashboard.commandCenter": "传感器控制中心",
"dashboard.commandCenter.subtitle": "集中查看实时状态、记录、诊断和 Show-Off 入口。",
"dashboard.activeGroups": "活动分组",
"showoff.title": "Show-Off 模式",
"showoff.subtitle": "打开全屏实时传感器演示。",
"dashboard.diagnostics.subtitle": "检查传感器和权限状态。",
"dashboard.search.subtitle": "按名称或类别查找传感器。",
"search.emptyHint": "可尝试 motion、location、camera、battery 或 network。",
```

- [ ] **Step 4: Add tab routing to `DashboardView`**

In `ContentView`, change the `DashboardView()` tab to pass a binding:

```swift
DashboardView(selectedTab: $selectedTab)
```

In `DashboardView`, add this property near the environment objects:

```swift
@Binding var selectedTab: Int
```

Add this preview/test-friendly initializer below the stored properties:

```swift
init(selectedTab: Binding<Int> = .constant(0)) {
    self._selectedTab = selectedTab
}
```

- [ ] **Step 5: Add deterministic dashboard summary type**

In `DashboardView.swift`, add this type after `DashboardReadinessSnapshot`:

```swift
struct DashboardCommandSummary {
    let readiness: DashboardReadinessSnapshot
    let isLocationAuthorized: Bool
    let isNetworkConnected: Bool
    let isLoggingEnabled: Bool
    let isRecording: Bool

    var readinessText: String {
        readiness.readinessValue
    }

    var activeGroupCount: Int {
        [
            readiness.motion.available > 0,
            readiness.location.available > 0,
            readiness.environment.available > 0,
            readiness.system.available > 0,
            readiness.connectivity.available > 0,
            readiness.camera.available > 0
        ].availableCount
    }

    var loggingStatusKey: String {
        if !isLoggingEnabled { return "logger.master.disabledNote" }
        return isRecording ? "logger.sessionRecording" : "logger.sessionIdle"
    }

    var strongestSignalKey: String {
        if !isLocationAuthorized { return "status.permissionNeeded" }
        if isNetworkConnected { return "status.active" }
        return "status.waiting"
    }
}
```

- [ ] **Step 6: Move readiness calculation into `DashboardView`**

Add this computed property to `DashboardView`, using the same counts currently inside `DashboardSensorSummary`:

```swift
private var readiness: DashboardReadinessSnapshot {
    DashboardReadinessSnapshot(
        motion: .init(
            available: [
                motion.isAccelerometerAvailable,
                motion.isGyroscopeAvailable,
                motion.isMagnetometerAvailable,
                motion.isDeviceMotionAvailable,
                motion.isPedometerAvailable,
                motion.isAltimeterAvailable,
                motion.isActivityAvailable
            ].availableCount,
            total: 7
        ),
        location: .init(available: loc.isAuthorized ? 2 : 0, total: 2),
        environment: .init(
            available: [env.isAltimeterAvailable, env.isProximityMonitoringEnabled, true].availableCount,
            total: 3
        ),
        system: .init(
            available: [sys.isBatteryMonitoringEnabled, true, true, true, true].availableCount,
            total: 5
        ),
        connectivity: .init(
            available: [conn.bluetoothState == .poweredOn, true].availableCount,
            total: 2
        ),
        camera: .init(
            available: [cam.isRearCameraAvailable, cam.isTorchAvailable].availableCount,
            total: 2
        )
    )
}
```

Change `DashboardSensorSummary` to accept `let readiness: DashboardReadinessSnapshot`, then remove its old private `readiness` property.

- [ ] **Step 7: Add dashboard command state and hero**

In `DashboardView`, add:

```swift
@EnvironmentObject var loggingService: LoggingService
@AppStorage(LoggingService.masterEnabledKey) private var masterEnabled = false
@State private var showShowOff = false
```

Add this computed property:

```swift
private var commandSummary: DashboardCommandSummary {
    DashboardCommandSummary(
        readiness: readiness,
        isLocationAuthorized: loc.isAuthorized,
        isNetworkConnected: conn.isConnectedToNetwork,
        isLoggingEnabled: masterEnabled,
        isRecording: loggingService.activeSessionDisplayID != nil
    )
}
```

Add this view near `DashboardSensorSummary`:

```swift
struct SensorHeroPanel: View {
    let summary: DashboardCommandSummary
    let onShowOff: () -> Void
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .font(.title.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .frame(width: 58, height: 58)
                    .background(Color.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(locManager.t("dashboard.commandCenter"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(locManager.t("dashboard.commandCenter.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ViewThatFits {
                HStack(spacing: 10) { metrics }
                VStack(spacing: 10) { metrics }
            }

            Button(action: onShowOff) {
                Label(locManager.t("showoff.title"), systemImage: "sparkles.tv.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppPrimaryButtonStyle(color: .indigo))
            .accessibilityHint(locManager.t("showoff.subtitle"))
        }
        .padding(18)
        .appMaterialSurface(cornerRadius: 24, material: .regularMaterial)
    }

    @ViewBuilder
    private var metrics: some View {
        MetricPill(title: locManager.t("status.available"), value: summary.readinessText, icon: "checkmark.seal.fill", color: .green)
        MetricPill(title: locManager.t("dashboard.activeGroups"), value: "\(summary.activeGroupCount)", icon: "square.grid.2x2.fill", color: .blue)
        MetricPill(title: locManager.t("tab.logger"), value: locManager.t(summary.loggingStatusKey), icon: "record.circle", color: summary.isRecording ? .red : .orange)
    }
}
```

- [ ] **Step 8: Replace dashboard top content**

In `DashboardView.body`, replace `DashboardShowOffButton()`, `AllSensorsLogSessionBar()`, and `DashboardSensorSummary()` with:

```swift
SensorHeroPanel(summary: commandSummary) {
    showShowOff = true
}

AdaptiveCardGrid(minWidth: 260, spacing: 10) {
    QuickActionTile(title: locManager.t("showoff.title"), subtitle: locManager.t("showoff.subtitle"), icon: "sparkles.tv.fill", color: .indigo) {
        showShowOff = true
    }
    QuickActionTile(title: locManager.t("tab.logger"), subtitle: locManager.t(commandSummary.loggingStatusKey), icon: "record.circle", color: commandSummary.isRecording ? .red : .blue) {
        selectedTab = 5
    }
    QuickActionTile(title: locManager.t("diagnostic.title"), subtitle: locManager.t("dashboard.diagnostics.subtitle"), icon: "stethoscope", color: .orange) {
        selectedTab = 3
    }
}

AllSensorsLogSessionBar()

DashboardSensorSummary(readiness: readiness)
```

Add this modifier to the `NavigationStack` content:

```swift
.sheet(isPresented: $showShowOff) {
    ShowOffMode(initialSensorID: SOSensors.all.first?.id ?? "01")
}
```

- [ ] **Step 9: Replace search empty state**

In `searchResults`, replace the empty `VStack` with:

```swift
EmptyStatePanel(
    title: locManager.t("search.noResults"),
    message: locManager.t("search.emptyHint"),
    icon: "magnifyingglass",
    color: .blue
)
.padding(.top, 40)
```

- [ ] **Step 10: Run targeted dashboard tests**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testDashboardCommandCenterSummaryText -only-testing:iPhoneSensorsTests/SmokeTests/testDashboardReadinessSummaryCountsEveryVisibleSensor -only-testing:iPhoneSensorsTests/SmokeTests/testDashboardReadinessSummaryReportsPermissionGatedLocationSensors
```

Expected: PASS.

- [ ] **Step 11: Commit dashboard command center**

Run:

```bash
git add iPhoneSensors/iPhoneSensors/Views/Dashboard/DashboardView.swift iPhoneSensors/iPhoneSensors/App/ContentView.swift iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "feat(ui): add dashboard command center"
```

## Task 4: Logger Overview Polish

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerOverviewView.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`

- [ ] **Step 1: Write the failing logger summary test**

Append this test method to `SmokeTests`:

```swift
func testLoggerOverviewSummaryStatus() {
    let disabled = LoggerOverviewSummary(
        masterEnabled: false,
        isRecording: true,
        enabledStreams: 3,
        totalStreams: 10,
        elapsed: 12
    )

    XCTAssertEqual(disabled.statusKey, "logger.master.disabledNote")
    XCTAssertEqual(disabled.enabledStreamsText, "3/10")

    let recording = LoggerOverviewSummary(
        masterEnabled: true,
        isRecording: true,
        enabledStreams: 8,
        totalStreams: 10,
        elapsed: 65
    )

    XCTAssertEqual(recording.statusKey, "logger.sessionRecording")
    XCTAssertEqual(recording.elapsedText, "01:05")
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testLoggerOverviewSummaryStatus
```

Expected: FAIL because `LoggerOverviewSummary` is not defined.

- [ ] **Step 3: Add logger localization keys**

In `LocalizationManager.swift`, add these keys near existing logger strings in the English dictionary:

```swift
"logger.hero.subtitle": "Opt-in local recording for selected sensors.",
"logger.enabledStreams": "Enabled streams",
"logger.elapsed": "Elapsed",
"logger.dataViewer": "Data Viewer",
"logger.dataViewer.subtitle": "Browse saved local sessions.",
"logger.settings.subtitle": "Formats, retention, and storage controls.",
```

Add these keys near the same translated section in the Thai dictionary:

```swift
"logger.hero.subtitle": "การบันทึกในเครื่องแบบเลือกเปิดสำหรับเซ็นเซอร์ที่เลือก",
"logger.enabledStreams": "สตรีมที่เปิด",
"logger.elapsed": "เวลาที่ผ่านไป",
"logger.dataViewer": "ตัวดูข้อมูล",
"logger.dataViewer.subtitle": "ดูเซสชันในเครื่องที่บันทึกไว้",
"logger.settings.subtitle": "รูปแบบ การเก็บรักษา และการจัดเก็บ",
```

Add these keys near the same translated section in the Chinese dictionary:

```swift
"logger.hero.subtitle": "为选定传感器提供本地、可选择开启的记录。",
"logger.enabledStreams": "已启用流",
"logger.elapsed": "已用时间",
"logger.dataViewer": "数据查看器",
"logger.dataViewer.subtitle": "浏览已保存的本地会话。",
"logger.settings.subtitle": "格式、保留和存储控制。",
```

- [ ] **Step 4: Add deterministic logger summary type**

In `LoggerOverviewView.swift`, add this type after `LoggerOverviewView`:

```swift
struct LoggerOverviewSummary {
    let masterEnabled: Bool
    let isRecording: Bool
    let enabledStreams: Int
    let totalStreams: Int
    let elapsed: TimeInterval

    var statusKey: String {
        if !masterEnabled { return "logger.master.disabledNote" }
        return isRecording ? "logger.sessionRecording" : "logger.sessionIdle"
    }

    var enabledStreamsText: String {
        "\(enabledStreams)/\(totalStreams)"
    }

    var elapsedText: String {
        let totalSeconds = max(0, Int(elapsed))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

- [ ] **Step 5: Add logger hero and category summary components**

In `LoggerOverviewView.swift`, add these types after `LoggerOverviewSummary`:

```swift
struct LoggerHeroPanel: View {
    let summary: LoggerOverviewSummary
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: summary.isRecording ? "waveform.circle.fill" : "record.circle")
                    .font(.largeTitle.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(summary.isRecording ? .red : .blue)
                    .frame(width: 58, height: 58)
                    .background((summary.isRecording ? Color.red : Color.blue).opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.t("logger.title"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(localization.t("logger.hero.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            ViewThatFits {
                HStack(spacing: 10) { metrics }
                VStack(spacing: 10) { metrics }
            }
        }
        .padding(18)
        .appMaterialSurface(cornerRadius: 24, material: .regularMaterial)
    }

    @ViewBuilder
    private var metrics: some View {
        MetricPill(title: localization.t("status.active"), value: localization.t(summary.statusKey), icon: summary.isRecording ? "stopwatch.fill" : "power.circle.fill", color: summary.isRecording ? .red : .blue)
        MetricPill(title: localization.t("logger.enabledStreams"), value: summary.enabledStreamsText, icon: "slider.horizontal.3", color: .green)
        MetricPill(title: localization.t("logger.elapsed"), value: summary.elapsedText, icon: "timer", color: .orange)
    }
}

struct LoggerCategorySummary: View {
    let category: SensorCategory
    let enabledText: String
    let ids: [SensorID]
    @EnvironmentObject private var localization: LocalizationManager

    private var icon: String {
        switch category {
        case .motion: return "gyroscope"
        case .location: return "location.fill"
        case .environment: return "leaf.fill"
        case .system: return "cpu"
        case .connectivity: return "wifi"
        case .camera: return "camera.fill"
        case .health: return "heart.fill"
        }
    }

    private var color: Color {
        switch category {
        case .motion: return .blue
        case .location: return .green
        case .environment: return .orange
        case .system: return .purple
        case .connectivity: return .cyan
        case .camera: return .yellow
        case .health: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryGlyphTile(
                title: localization.t("category.\(category.rawValue)"),
                subtitle: enabledText,
                icon: icon,
                color: color,
                trailingText: "\(ids.count)"
            )
            LoggerBulkActionMenu(ids: ids)
        }
        .padding(12)
        .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)
    }
}
```

- [ ] **Step 6: Add summary property to `LoggerOverviewView`**

Inside `LoggerOverviewView`, add:

```swift
private var overviewSummary: LoggerOverviewSummary {
    LoggerOverviewSummary(
        masterEnabled: masterEnabled,
        isRecording: loggingService.activeSessionDisplayID != nil,
        enabledStreams: loggingService.sessionEnabledCount(in: SensorID.allCases),
        totalStreams: SensorID.allCases.count,
        elapsed: sessionElapsed
    )
}
```

- [ ] **Step 7: Replace the `List` body with the polished scroll layout**

Replace the `List { ... }` inside `NavigationStack` with:

```swift
ScrollView {
    LazyVStack(alignment: .leading, spacing: 16) {
        LoggerHeroPanel(summary: overviewSummary)

        LoggerMasterToggle(isOn: $masterEnabled)
            .padding(16)
            .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)

        VStack(spacing: 12) {
            LoggerStatusHeaderView(elapsed: sessionElapsed)
            LoggerSessionControl(style: .fullWidth)
        }
        .padding(16)
        .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)
        .disabled(!masterEnabled)

        AdaptiveCardGrid(minWidth: 260, spacing: 10) {
            QuickActionTile(title: localization.t("logger.dataViewer"), subtitle: localization.t("logger.dataViewer.subtitle"), icon: "chart.bar.doc.horizontal", color: .blue) {
                showingDataViewer = true
            }
            QuickActionTile(title: localization.t("logger.settings"), subtitle: localization.t("logger.settings.subtitle"), icon: "gearshape.fill", color: .gray) {
                showingSettings = true
            }
        }

        if masterEnabled {
            HStack {
                Label(localization.t("logger.bulk.allSensors"), systemImage: "square.stack.3d.up.fill")
                    .font(.headline.weight(.semibold))
                Spacer()
                Text(enabledSummary(for: SensorID.allCases))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                LoggerBulkActionMenu(ids: SensorID.allCases)
            }
            .padding(14)
            .appMaterialSurface(cornerRadius: 18, material: .thinMaterial)

            ForEach(SensorCategory.allCases, id: \.self) { cat in
                let ids = SensorID.allCases.filter { $0.category == cat }
                VStack(alignment: .leading, spacing: 10) {
                    LoggerCategorySummary(category: cat, enabledText: enabledSummary(for: ids), ids: ids)

                    VStack(spacing: 0) {
                        ForEach(ids, id: \.self) { id in
                            NavigationLink(destination: SensorLogConfigView(sensorID: id)) {
                                SensorRowConfigPreview(sensorID: id)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)

                            if id != ids.last {
                                Divider().padding(.leading, 44)
                            }
                        }
                    }
                    .appMaterialSurface(cornerRadius: 16, material: .thinMaterial)
                }
            }
        } else {
            EmptyStatePanel(title: localization.t("logger.title"), message: localization.t("logger.master.disabledNote"), icon: "lock.circle", color: .blue)
        }
    }
    .responsivePage()
}
.appBackground()
```

Keep the existing `.navigationTitle`, toolbar buttons, sheets, `onAppear`, `onDisappear`, and `enabledSummary(for:)` implementation.

- [ ] **Step 8: Run targeted logger tests**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test -only-testing:iPhoneSensorsTests/SmokeTests/testLoggerOverviewSummaryStatus
```

Expected: PASS.

- [ ] **Step 9: Commit logger overview**

Run:

```bash
git add iPhoneSensors/iPhoneSensors/Views/Logger/LoggerOverviewView.swift iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
git commit -m "feat(ui): redesign logger overview"
```

## Task 5: Full Verification and Visual Sanity

**Files:**
- Verify: `iPhoneSensors/iPhoneSensors.xcodeproj`
- Inspect if needed: `CLAUDE.md`
- Inspect if needed: `docs/screenshots.md`
- Inspect if needed: `screenshots/README.md`

- [ ] **Step 1: Run full test suite**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

Expected: PASS. If simulator availability blocks the run, capture the exact destination error and run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -showdestinations
```

- [ ] **Step 2: Run simulator build**

Run:

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

Expected: PASS.

- [ ] **Step 3: Verify HealthKit entitlements were not regressed**

Run:

```bash
git diff -- iPhoneSensors/iPhoneSensors.entitlements iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj | rg -n "healthkit|clinical|background|com.apple.developer.healthkit|UIBackgroundModes" || true
```

Expected: `com.apple.developer.healthkit` remains enabled; no Clinical Health Records entitlement appears; no unjustified background mode is added.

- [ ] **Step 4: Visual sanity check changed screens**

Inspect first-run setup, Sensors dashboard, and Logger overview in light and dark appearances on compact and regular width. If using the repository screenshot pipeline, first read the current instructions:

```bash
sed -n '1,220p' CLAUDE.md
sed -n '1,220p' docs/screenshots.md
sed -n '1,220p' screenshots/README.md
```

Expected:
- First-run setup shows progress, privacy promise, optional skip behavior, and large touch targets.
- Dashboard top area shows readiness, active groups, logging status, Show-Off entry, and logger and diagnostics navigation.
- Logger overview shows opt-in state, session state, enabled stream count, elapsed time, data viewer, settings, categories, and per-sensor rows.
- No overlapping text at normal and large Dynamic Type sizes.

- [ ] **Step 5: Commit verification fixes only if needed**

If verification requires code changes, commit only the touched files:

```bash
git add <verified-fix-files>
git commit -m "fix(ui): address redesign verification issues"
```

If no changes are needed, do not create an empty commit.

## Self-Review

- Spec coverage: The plan covers shared SwiftUI visual assets, guided first-run setup, dashboard command center, logger status/control overview, Show-Off discoverability, localization, accessibility-oriented text-backed states, HealthKit/Clinical Health Records guardrails, and build/test/visual verification.
- Placeholder scan: No task uses `TBD`, `TODO`, `implement later`, "similar to", or unbounded "add tests" phrasing. Each implementation step includes exact files, code or replacement snippets, commands, and expected outcomes.
- Type consistency: `SensorVisualStatus`, `DashboardCommandSummary`, `LoggerOverviewSummary`, `SensorStatusBadge`, `MetricPill`, `QuickActionTile`, `CategoryGlyphTile`, and `EmptyStatePanel` are introduced before later tasks consume them. Test method names match the command invocations.
