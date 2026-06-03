# Feature 13: TestFlight Beta Documentation

## Goal
Create comprehensive documentation for the TestFlight external beta process to ensure a smooth App Store submission.

## App Store Compliance Justification
Running a 5-day external beta is a crucial safety net to expose edge-case crashes before review. Proper documentation ensures the team follows best practices if rejection occurs.

## Requirements

### Core Functionality
- [ ] Document the TestFlight external beta process in `docs/testflight-beta.md`
- [ ] Include checklist for beta preparation
- [ ] Include instructions for handling rejections
- [ ] Document video demonstration requirements for hardware-dependent features

### Documentation Contents
- [ ] **Pre-Beta Checklist:**
  - All features implemented and tested on physical device
  - All 12 languages verified
  - Privacy manifest validated
  - No crashes during 30-minute stress test
- [ ] **Beta Duration:** Minimum 5 business days
- [ ] **Tester Recruitment:** 10-20 external testers with diverse devices
- [ ] **Feedback Collection:** TestFlight feedback + email channel
- [ ] **Post-Beta Fixes:** Address all reported crashes before submission
- [ ] **Rejection Protocol:**
  - Fix ONLY the specific issue Apple flagged
  - Do NOT bundle unrelated updates into resubmission
  - Respond directly in Resolution Center with documentation
  - Do NOT silently upload new binary (resets queue)
- [ ] **Video Demonstration Requirements:**
  - Physical camera recording (not simulator screen recording)
  - Show device being manipulated in real world
  - Demonstrate Pedometer (actual walking), Altimeter (elevation change), Gyroscope (rotation)
  - Show on-screen reaction alongside physical manipulation

## Files to Create
- `docs/testflight-beta.md`

## Files to Modify
- `docs/appstore-info.md` (reference the beta doc)

## Acceptance Criteria
- [ ] TestFlight beta document is complete and actionable
- [ ] Video demo checklist covers all hardware-dependent features
- [ ] Rejection protocol is clearly documented
