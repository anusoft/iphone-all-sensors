# Feature 10: Liquid Glass Design Refactor

## Goal
Refactor custom glass morphism cards to use native SwiftUI Material background types, ensuring visual harmony with iOS 26's Liquid Glass design language and compliance with HIG.

## App Store Compliance Justification
Prevents rejection under Guideline 4.0 (Design) for unpolished, legacy UI that clashes with modern system elements.

## Requirements

### Core Functionality
- [ ] Audit all custom card backgrounds across 22 detail screens
- [ ] Replace custom glass morphism with native `.material` or `.ultraThinMaterial`
- [ ] Ensure navigation bars, tab bars, and sheets automatically inherit Liquid Glass
- [ ] Custom components (CircularGauge, ThreeAxisView, RotationCube) must not clash with system materials

### UI/UX
- [ ] Cards use `Rectangle().fill(.ultraThinMaterial)` instead of custom blur
- [ ] Background colors adapt to system theme automatically
- [ ] No opaque backgrounds alongside translucent system elements
- [ ] Maintain readability and contrast in both light and dark modes

### Technical Details
- SwiftUI `.background(.ultraThinMaterial)` or `.regularMaterial`
- Remove manual blur effects if they conflict with system rendering
- Test on both light and dark mode
- Ensure compatibility with iOS 17+ (fallback for older versions)

## Files to Modify
- `iPhoneSensors/Views/Components/SensorComponents.swift` (glass modifiers)
- All `*DetailView.swift` files with custom backgrounds
- `iPhoneSensors/ContentView.swift` (tab bar, navigation)

## Acceptance Criteria
- [ ] All cards use native Material backgrounds
- [ ] No visual clashes between custom and system UI
- [ ] Light/dark mode both look polished
- [ ] iOS 17+ compatibility maintained
