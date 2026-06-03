# TestFlight External Beta Guide

## Overview
Running a TestFlight external beta for a minimum of **5 business days** prior to any production submission is a crucial safety net. This allows real-world testing to expose edge-case crashes across the fragmented landscape of older iPhones and varying iPad architectures.

---

## Pre-Beta Checklist

- [ ] All features implemented and tested on physical device
- [ ] All 12 languages verified
- [ ] Privacy manifest validated (PrivacyInfo.xcprivacy)
- [ ] No crashes during 30-minute stress test with all sensors active
- [ ] App icon and screenshots finalized
- [ ] App Store metadata complete
- [ ] Medical disclaimer tested and verified
- [ ] Permission onboarding flow tested on fresh install
- [ ] Data export (CSV/JSON) verified on device
- [ ] Recording and playback tested
- [ ] Diagnostic suite tested on multiple device types
- [ ] Power efficiency / thermal throttling tested

---

## Beta Duration

**Minimum:** 5 business days  
**Recommended:** 7-10 business days

## Tester Recruitment

- **Target:** 10-20 external testers
- **Device diversity:** Mix of iPhone models (SE, standard, Pro, Pro Max) and iPads
- **iOS versions:** Include at least one tester on latest iOS and one on iOS 17 (minimum supported)
- **Geographic diversity:** If possible, include testers in different regions (for localization and network testing)

## Feedback Collection

- **TestFlight built-in feedback:** Screenshots and crash reports auto-collected
- **Email channel:** Provide a dedicated feedback email in app settings
- **Feedback form:** Optional in-app feedback sheet

## Post-Beta Fixes

**Critical:** Address all reported crashes before submission.  
**Important:** Fix any UI layout issues on smaller/larger screens.  
**Nice to have:** Address feature requests for future updates.

---

## Rejection Protocol

If a rejection occurs, follow this strict protocol:

1. **Fix ONLY the specific issue Apple flagged**
2. **Do NOT bundle unrelated updates into the resubmission**
3. **Respond directly in the Resolution Center** with comprehensive documentation
4. **Do NOT silently upload a new binary** — this resets the queue and invites a different reviewer to find new issues
5. **Be concise and professional** in all communications
6. **Provide video evidence** if the rejection involves hardware-dependent features

---

## Video Demonstration Requirements

For hardware-dependent features, provide a physical camera recording (not simulator screen recording):

### Required Videos

1. **Pedometer** — Show actual device being carried while walking/running, step count increasing
2. **Altimeter / Barometer** — Show device at different elevations (stairs, elevator, hill), pressure/altitude changing
3. **Gyroscope** — Show rapid rotation of device, 3D cube responding in real-time
4. **Compass** — Show device being rotated, compass dial aligning with real-world direction
5. **GPS** — Show device being moved outdoors, coordinates updating

### Video Specifications

- **Format:** MP4, 1080p minimum
- **Length:** 15-30 seconds per feature
- **Content:** Physical device in frame + on-screen reaction visible
- **No editing:** Single continuous take preferred
- **Upload:** Attach to App Store Connect "Notes for Review"

---

## Submission Notes Template

Use this template for the "Notes for Review" section in App Store Connect:

```
This application utilizes the CoreMotion, CoreLocation, and HealthKit frameworks to provide localized diagnostic telemetry directly to the user. All data processing occurs strictly on-device.

Hardware-dependent features:
- Barometer and Altimeter require physical atmospheric pressure changes. Video attached.
- Pedometer requires actual movement. Video attached.
- GPS requires outdoor location. Video attached.

Privacy:
- This application reads hardware parameters strictly for local, on-device diagnostic display.
- No heuristic data, combinatorial device signals, or fingerprinting identifiers are generated, hashed, persisted, or transmitted.
- All data remains siloed within the application's sandbox.
- We do not implement App Tracking Transparency (ATT) because we do not track users.

HealthKit:
- This application integrates with the Health app to provide physiological context alongside environmental sensor data.
- A mandatory medical disclaimer is presented before any HealthKit access.
- The app does not diagnose, treat, cure, or prevent any disease.
```

---

*Document Version: 1.0*  
*Generated: 2026-05-06*
