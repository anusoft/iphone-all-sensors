# Feature 01: Add Purpose Strings to Info.plist

## Checklist

- [ ] Add `NSLocationWhenInUseUsageDescription`
- [ ] Add `NSMotionUsageDescription`
- [ ] Add `NSCameraUsageDescription`
- [ ] Add `NSMicrophoneUsageDescription`
- [ ] Add `NSBluetoothAlwaysUsageDescription`
- [ ] Add `NSHealthShareUsageDescription`
- [ ] Verify all strings are localized in 12 languages
- [ ] Build and confirm no warnings

## Details

**File:** `iPhoneSensors/Info.plist`

**Required Purpose Strings:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to display GPS coordinates, altitude, speed, and compass heading.</string>

<key>NSMotionUsageDescription</key>
<string>We use motion sensors to display accelerometer, gyroscope, pedometer, and activity data.</string>

<key>NSCameraUsageDescription</key>
<string>We use the camera to show camera capabilities and control the torch/flashlight.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone to show audio input device information.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth to scan for nearby devices and display Bluetooth status.</string>

<key>NSHealthShareUsageDescription</key>
<string>We read health data such as steps, heart rate, and activity to display in the Health tab.</string>
```

## App Store Guideline
Section 5.1.1(ii) — Apps that collect user or usage data must secure user consent with purpose strings that clearly describe the use of the data.
