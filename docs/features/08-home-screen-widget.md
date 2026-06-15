# Feature 08: Add iOS Home Screen Widget

> Status: Future work. The source scaffold exists, but there is no widget target in `iPhoneSensors.xcodeproj`, no matching App Group entitlement, and App Store copy must not claim this feature until those are fixed.

## Status: Deferred — Requires Target, App Group, And Data Bridge

## Checklist

- [x] Create Widget scaffold files
- [x] Prototype small widget: single sensor value with status dot
- [x] Prototype medium widget: sensor name + large value display
- [ ] Large widget: Full sensor dashboard (deferred)
- [ ] Selectable sensor in widget configuration (deferred)
- [x] Update every 15 minutes (WidgetKit limit)
- [x] Dark/light theme support (uses containerBackground)
- [x] Tap widget to open app (automatic via WidgetKit)
- [x] Localize widget strings (uses same LocalizationManager pattern)
- [ ] Add widget to App Store screenshots after the extension target ships

## Implementation

**Widget Extension Files Created:**
- `iPhoneSensorsWidget/iPhoneSensorsWidget.swift`
- `iPhoneSensorsWidget/Info.plist`
- `iPhoneSensorsWidget/Assets.xcassets/Contents.json`

**Widget Features:**
- **Small (systemSmall):** Shows sensor icon, value, unit, and active status dot
- **Medium (systemMedium):** Shows sensor name, last update time, large value, and unit
- **Timeline:** Updates every 15 minutes using `UserDefaults(suiteName:)`
- **Data Source:** Intended to read from shared `UserDefaults`; reconcile suite name and App Group entitlement before shipping

## Manual Steps Required in Xcode

### 1. Add Widget Extension Target
1. Open `iPhoneSensors.xcodeproj` in Xcode
2. File → New → Target
3. Select **Widget Extension**
4. Name it `iPhoneSensorsWidgetExtension`
5. Make sure "Include Configuration Intent" is **unchecked**
6. Activate the scheme when prompted

### 2. Replace Generated Files
After Xcode creates the widget target, replace the generated files with the pre-created ones:
- Replace `iPhoneSensorsWidget.swift` with the version in `iPhoneSensorsWidget/`
- Replace `Info.plist` with the version in `iPhoneSensorsWidget/`
- Use the provided `Assets.xcassets` (or keep Xcode's generated one)

### 3. Add App Group Capability (Required for Data Sharing)
1. Select the **main app target** → Signing & Capabilities
2. Click **+ Capability**
3. Add **App Groups**
4. Create/Select the group: `group.com.1moby.iPhoneSensors`
5. Repeat for the **widget extension target**

### 4. Update Main App to Save Widget Data
In `SensorManager.swift` (or relevant sensor managers), add code to save current values to shared UserDefaults:

```swift
let sharedDefaults = UserDefaults(suiteName: "group.com.1moby.iPhoneSensors")
sharedDefaults?.set("Accelerometer", forKey: "widget_sensor_name")
sharedDefaults?.set(String(format: "%.2f", value), forKey: "widget_sensor_value")
sharedDefaults?.set("G", forKey: "widget_sensor_unit")
sharedDefaults?.set(true, forKey: "widget_sensor_active")
```

### 5. Build and Test
1. Build the widget scheme
2. Run on simulator
3. Add widget to home screen via long-press → Edit Home Screen → + → All Sensors

## Why This Matters

Widgets are highly visible App Store features. They increase "app-like" quality and daily engagement. Apple often features apps with well-designed widgets.

**Note:** The widget source is a deferred scaffold, not a shipping feature. Before enabling it, add a real extension target, align the suite name with App Group entitlements, implement app-side data writes, and update App Store copy/screenshots.
