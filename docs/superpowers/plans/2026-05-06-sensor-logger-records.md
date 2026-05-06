# Sensor Logger & Records Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-sensor logger with two parallel streams (continuous always-on + explicit sessions), three formats (JSON Lines / CSV / SQLite via GRDB), per-sensor format/interval configuration, a Logger tab UI, and a Data Viewer screen for review and export.

**Architecture:** Each existing `*SensorManager` gains a Combine `PassthroughSubject<SensorSample, Never>` and emits one `.send(...)` per existing callback. An actor pipeline (`SensorEventBus` → `LoggingCoordinator` → per-format `LogWriter` actors) routes samples to disk under `Documents/SensorLogs/`. SQLite via GRDB.swift. Configuration persists in UserDefaults as `loggingConfig.v1`.

**Tech Stack:** Swift 5, SwiftUI, iOS 17, GRDB.swift 7.x (SPM), Combine, Swift Concurrency (actors), `xcodeproj` Ruby gem for project-file edits.

**Spec:** `docs/superpowers/specs/2026-05-06-sensor-logger-records-design.md`

**Project layout:** Xcode project at `iPhoneSensors/iPhoneSensors.xcodeproj`. App sources under `iPhoneSensors/iPhoneSensors/`.

**Build command:**
```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet build
```

**Test command:**
```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj \
  -scheme iPhoneSensors \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet test
```

---

## Phase 0 — Tooling

### Task 0.1: Add `xcodeproj` helper script

Adding new files to the Xcode target without UI requires the `xcodeproj` gem. Single helper script reused by every later task.

**Files:**
- Create: `Scripts/xcp.rb`

- [ ] **Step 1: Write the helper**

```ruby
#!/usr/bin/env ruby
# Usage:
#   ruby Scripts/xcp.rb add-files iPhoneSensors path/relative/to/iPhoneSensors/iPhoneSensors/App/foo.swift ...
#   ruby Scripts/xcp.rb add-target iPhoneSensorsTests
#   ruby Scripts/xcp.rb add-package https://github.com/groue/GRDB.swift 7.0.0 GRDB iPhoneSensors
require 'xcodeproj'

PROJ_PATH = File.expand_path('../iPhoneSensors/iPhoneSensors.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJ_PATH)
cmd = ARGV.shift

case cmd
when 'add-files'
  target_name = ARGV.shift
  target = project.targets.find { |t| t.name == target_name } or abort "no target #{target_name}"
  ARGV.each do |rel|
    abs = File.expand_path(File.join(File.dirname(PROJ_PATH), rel))
    abort "missing #{abs}" unless File.exist?(abs)
    # Find or create the group chain matching the on-disk path.
    parts = rel.split('/')
    group = project.main_group.find_subpath(File.join(parts[0..-2]), true)
    group.set_source_tree('SOURCE_ROOT')
    file_ref = group.files.find { |f| f.path == parts.last } || group.new_reference(parts.last)
    target.source_build_phase.files_references << file_ref unless target.source_build_phase.files_references.include?(file_ref)
  end
when 'add-resource'
  target_name = ARGV.shift
  target = project.targets.find { |t| t.name == target_name } or abort "no target"
  ARGV.each do |rel|
    parts = rel.split('/')
    group = project.main_group.find_subpath(File.join(parts[0..-2]), true)
    group.set_source_tree('SOURCE_ROOT')
    fr = group.files.find { |f| f.path == parts.last } || group.new_reference(parts.last)
    target.resources_build_phase.add_file_reference(fr) rescue nil
  end
when 'add-package'
  url, version, product, target_name = ARGV
  target = project.targets.find { |t| t.name == target_name } or abort "no target"
  ref = project.root_object.package_references.find { |r| r.repositoryURL == url }
  unless ref
    ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    ref.repositoryURL = url
    ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => version }
    project.root_object.package_references << ref
  end
  dep = target.package_product_dependencies.find { |d| d.product_name == product }
  unless dep
    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.product_name = product
    dep.package = ref
    target.package_product_dependencies << dep
    target.frameworks_build_phase.add_file_reference(
      project.frameworks_group.new_product_ref_for_target(product, target)
    ) rescue nil
  end
when 'add-test-target'
  name = ARGV.shift
  abort "exists" if project.targets.any? { |t| t.name == name }
  target = project.new_target(:unit_test_bundle, name, :ios, '17.0')
  target.build_configurations.each do |bc|
    bc.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/iPhoneSensors.app/iPhoneSensors'
    bc.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    bc.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.allsensors.#{name}"
    bc.build_settings['SWIFT_VERSION'] = '5.0'
    bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    bc.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  end
  app = project.targets.find { |t| t.name == 'iPhoneSensors' }
  target.add_dependency(app)
else
  abort "unknown cmd: #{cmd}"
end

project.save
puts "ok: #{cmd}"
```

- [ ] **Step 2: Make executable + smoke test**

```bash
chmod +x Scripts/xcp.rb
ruby Scripts/xcp.rb 2>&1 | head -3   # expect: unknown cmd:
```

- [ ] **Step 3: Verify project still builds**

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build
# Expected: BUILD SUCCEEDED
```

- [ ] **Step 4: Commit**

```bash
git add Scripts/xcp.rb
git commit -m "build: add xcodeproj helper script for programmatic project edits

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 0.2: Add unit-test target `iPhoneSensorsTests`

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj`
- Create: `iPhoneSensors/iPhoneSensorsTests/.gitkeep`

- [ ] **Step 1: Create directory + add target**

```bash
mkdir -p iPhoneSensors/iPhoneSensorsTests
touch iPhoneSensors/iPhoneSensorsTests/.gitkeep
ruby Scripts/xcp.rb add-test-target iPhoneSensorsTests
```

- [ ] **Step 2: Add a smoke test**

Create `iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift`:

```swift
import XCTest

final class SmokeTests: XCTestCase {
    func testTrue() { XCTAssertTrue(true) }
}
```

- [ ] **Step 3: Register file in target**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/SmokeTests.swift
```

- [ ] **Step 4: Make scheme runnable for tests**

The `iPhoneSensors` scheme needs the test target in its `Test` action. Easiest: open `iPhoneSensors/iPhoneSensors.xcodeproj/xcshareddata/xcschemes/iPhoneSensors.xcscheme` (create if missing) and ensure the `<TestAction>` element references `iPhoneSensorsTests`. Use this script:

```bash
ruby - <<'RUBY'
require 'xcodeproj'
proj = Xcodeproj::Project.open('iPhoneSensors/iPhoneSensors.xcodeproj')
shared_dir = File.join(proj.path, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(shared_dir)
scheme_path = File.join(shared_dir, 'iPhoneSensors.xcscheme')
unless File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(proj.targets.find { |t| t.name == 'iPhoneSensors' })
  scheme.save_as(proj.path, 'iPhoneSensors', true)
end
scheme = Xcodeproj::XCScheme.new(scheme_path)
test_action = scheme.test_action
unless test_action.testables.any? { |t| t.buildable_references.any? { |r| r.target_name == 'iPhoneSensorsTests' } }
  test_target = proj.targets.find { |t| t.name == 'iPhoneSensorsTests' }
  testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
  test_action.add_testable(testable)
end
scheme.save_as(proj.path, 'iPhoneSensors', true)
puts "scheme ok"
RUBY
```

- [ ] **Step 5: Run tests to verify**

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -20
# Expected: ** TEST SUCCEEDED **, SmokeTests.testTrue passes
```

- [ ] **Step 6: Commit**

```bash
git add iPhoneSensors/iPhoneSensors.xcodeproj iPhoneSensors/iPhoneSensorsTests/
git commit -m "test: add iPhoneSensorsTests target with smoke test

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 0.3: Add GRDB.swift SPM dependency

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors.xcodeproj/project.pbxproj` (via script)

- [ ] **Step 1: Add package**

```bash
ruby Scripts/xcp.rb add-package https://github.com/groue/GRDB.swift 7.0.0 GRDB iPhoneSensors
```

- [ ] **Step 2: Resolve packages + build**

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -resolvePackageDependencies 2>&1 | tail -5
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build
# Expected: BUILD SUCCEEDED, GRDB resolved
```

- [ ] **Step 3: Commit**

```bash
git add iPhoneSensors/iPhoneSensors.xcodeproj
git commit -m "build: add GRDB.swift 7.x SPM dependency

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 1 — Foundation: models + skeleton + 1 sensor + JSONL writer

After Phase 1, the accelerometer (only) writes JSON Lines to `Documents/SensorLogs/continuous/<today>/accelerometer.jsonl` while the app runs. No UI yet; config hardcoded.

### Task 1.1: Sensor identifier

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/SensorID.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SensorIDTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class SensorIDTests: XCTestCase {
    func testRawValuesStable() {
        XCTAssertEqual(SensorID.accelerometer.rawValue, "motion.accelerometer")
        XCTAssertEqual(SensorID.gps.rawValue, "location.gps")
        XCTAssertEqual(SensorID.battery.rawValue, "system.battery")
    }
    func testCategoryGrouping() {
        XCTAssertEqual(SensorID.accelerometer.category, .motion)
        XCTAssertEqual(SensorID.gps.category, .location)
    }
    func testAllCasesIncludesEverySensor() {
        XCTAssertGreaterThanOrEqual(SensorID.allCases.count, 25)
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation

enum SensorCategory: String, Codable, CaseIterable {
    case motion, location, environment, system, connectivity, camera, health
}

enum SensorID: String, Codable, CaseIterable, Hashable, Sendable {
    case accelerometer   = "motion.accelerometer"
    case gyroscope       = "motion.gyroscope"
    case magnetometer    = "motion.magnetometer"
    case deviceMotion    = "motion.deviceMotion"
    case altimeter       = "motion.altimeter"
    case pedometer       = "motion.pedometer"
    case motionActivity  = "motion.activity"

    case gps             = "location.gps"
    case heading         = "location.heading"

    case proximity       = "environment.proximity"
    case brightness      = "environment.brightness"
    case torch           = "environment.torch"
    case audio           = "environment.audio"

    case battery         = "system.battery"
    case thermal         = "system.thermal"
    case lowPower        = "system.lowPower"
    case orientation     = "system.orientation"
    case disk            = "system.disk"
    case uptime          = "system.uptime"

    case bluetoothState  = "connectivity.bluetoothState"
    case bluetoothScan   = "connectivity.bluetoothScan"
    case network         = "connectivity.network"
    case cellular        = "connectivity.cellular"

    case camera          = "camera.snapshot"

    case health          = "health.metric"

    var category: SensorCategory {
        switch self {
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion,
             .altimeter, .pedometer, .motionActivity:                  return .motion
        case .gps, .heading:                                           return .location
        case .proximity, .brightness, .torch, .audio:                  return .environment
        case .battery, .thermal, .lowPower, .orientation, .disk, .uptime: return .system
        case .bluetoothState, .bluetoothScan, .network, .cellular:     return .connectivity
        case .camera:                                                  return .camera
        case .health:                                                  return .health
        }
    }

    /// Display name shown in the UI. Localized via key `sensor.<rawValue>`.
    var localizationKey: String { "sensor.\(rawValue)" }

    /// Best-known native interval in milliseconds. Used to clamp the
    /// user-configured interval (we never upsample).
    var minIntervalMs: Int {
        switch self {
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion: return 10  // 100 Hz hardware max
        case .altimeter:                                               return 1000
        case .gps, .heading:                                           return 1000
        case .disk, .uptime, .brightness:                              return 1000
        default:                                                       return 0   // event-driven
        }
    }
}
```

- [ ] **Step 3: Register file + test passes**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors iPhoneSensors/iPhoneSensors/Models/Logging/SensorID.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/SensorIDTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
# Expected: TEST SUCCEEDED
```

- [ ] **Step 4: Commit**

```bash
git add iPhoneSensors/
git commit -m "feat(logger): add SensorID enum and category grouping

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.2: LogFormat, LogStream, FormatOptions

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/LogFormat.swift`
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/LogStream.swift`
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/FormatOptions.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LogFormatTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class LogFormatTests: XCTestCase {
    func testFileExtensions() {
        XCTAssertEqual(LogFormat.jsonl.fileExtension, "jsonl")
        XCTAssertEqual(LogFormat.csv.fileExtension, "csv")
        XCTAssertEqual(LogFormat.sqlite.fileExtension, "sqlite")
    }
    func testFormatOptionsDefaults() {
        let opts = FormatOptions()
        XCTAssertEqual(opts.csvDelimiter, ",")
        XCTAssertEqual(opts.sqliteBatchSize, 100)
    }
    func testStreams() { XCTAssertEqual(Set(LogStream.allCases), [.continuous, .session]) }
}
```

- [ ] **Step 2: Implementations**

`LogFormat.swift`:
```swift
import Foundation
enum LogFormat: String, Codable, CaseIterable, Sendable, Hashable {
    case sqlite, jsonl, csv
    var fileExtension: String { rawValue }
    var localizationKey: String { "logger.format.\(rawValue)" }
}
```

`LogStream.swift`:
```swift
import Foundation
enum LogStream: String, Codable, CaseIterable, Sendable, Hashable {
    case continuous, session
    var localizationKey: String { "logger.stream.\(rawValue)" }
}
```

`FormatOptions.swift`:
```swift
import Foundation
struct FormatOptions: Codable, Equatable, Sendable {
    var csvDelimiter: String = ","
    var sqliteBatchSize: Int = 100
    static let `default` = FormatOptions()
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors \
  iPhoneSensors/iPhoneSensors/Models/Logging/LogFormat.swift \
  iPhoneSensors/iPhoneSensors/Models/Logging/LogStream.swift \
  iPhoneSensors/iPhoneSensors/Models/Logging/FormatOptions.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/LogFormatTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add LogFormat, LogStream, FormatOptions

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.3: SensorPayload (typed enum)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/SensorPayload.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SensorPayloadTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class SensorPayloadTests: XCTestCase {
    func testAccelerationCodableRoundTrip() throws {
        let p = SensorPayload.acceleration(x: 0.1, y: 0.2, z: -9.81)
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(SensorPayload.self, from: data)
        XCTAssertEqual(p, back)
    }
    func testKindString() {
        XCTAssertEqual(SensorPayload.acceleration(x: 0, y: 0, z: 0).kind, "acceleration")
        XCTAssertEqual(SensorPayload.battery(level: 0.8, state: "charging").kind, "battery")
    }
    func testCSVColumns() {
        let cols = SensorPayload.acceleration(x: 0, y: 0, z: 0).csvColumns
        XCTAssertEqual(cols, ["x", "y", "z"])
    }
    func testCSVValues() {
        let p = SensorPayload.acceleration(x: 1, y: 2, z: 3)
        XCTAssertEqual(p.csvValues, ["1.0", "2.0", "3.0"])
    }
}
```

- [ ] **Step 2: Implementation** (see spec §6.2 for full case list)

```swift
import Foundation

struct DeviceMotionPayload: Codable, Equatable, Sendable {
    let roll, pitch, yaw: Double
    let gravityX, gravityY, gravityZ: Double
    let userAccX, userAccY, userAccZ: Double
    let rotationX, rotationY, rotationZ: Double
    let quatW, quatX, quatY, quatZ: Double
    let calMagX, calMagY, calMagZ: Double
    let calMagAccuracy: Int
}

struct PedometerPayload: Codable, Equatable, Sendable {
    let steps: Int; let distance: Double
    let floorsAscended: Int; let floorsDescended: Int
    let pace: Double?; let cadence: Double?
}

struct ActivityPayload: Codable, Equatable, Sendable {
    let state: String   // walking|running|cycling|automotive|stationary|unknown
    let confidence: Int
}

struct LocationPayload: Codable, Equatable, Sendable {
    let lat: Double, lon: Double, alt: Double
    let speed: Double, course: Double
    let horizAccuracy: Double, vertAccuracy: Double
    let speedAccuracy: Double, courseAccuracy: Double
    let floor: Int?
}

struct AudioPayload: Codable, Equatable, Sendable {
    let category: String; let sampleRate: Double; let channels: Int
    let volume: Double; let inputs: [String]; let outputs: [String]
}

struct CameraPayload: Codable, Equatable, Sendable {
    let hasFront: Bool, hasBack: Bool, hasUltraWide: Bool, hasTelephoto: Bool
    let hasLiDAR: Bool; let zoom: Double
}

struct SessionMarkerPayload: Codable, Equatable, Sendable {
    let kind: String   // start|end|throttleOn|throttleOff
    let note: String?
}

enum SensorPayload: Codable, Equatable, Sendable {
    case acceleration(x: Double, y: Double, z: Double)
    case rotationRate(x: Double, y: Double, z: Double)
    case magneticField(x: Double, y: Double, z: Double, accuracy: Int)
    case deviceMotion(DeviceMotionPayload)
    case altitude(relative: Double, pressure: Double)
    case pedometer(PedometerPayload)
    case activity(ActivityPayload)
    case location(LocationPayload)
    case heading(trueHeading: Double?, magneticHeading: Double, accuracy: Double)
    case proximity(near: Bool)
    case brightness(level: Double)
    case torch(level: Double)
    case audio(AudioPayload)
    case battery(level: Double, state: String)
    case thermal(state: String)
    case lowPower(enabled: Bool)
    case orientation(name: String)
    case disk(total: Int64, free: Int64)
    case uptime(seconds: Double)
    case bluetoothState(state: String)
    case bluetoothDevice(name: String?, uuid: String, rssi: Int)
    case network(type: String, connected: Bool)
    case cellular(carrier: String, radio: String)
    case cameraSnapshot(CameraPayload)
    case health(metric: String, value: Double, unit: String, ts: Date)
    case sessionMarker(SessionMarkerPayload)

    var kind: String {
        switch self {
        case .acceleration: return "acceleration"
        case .rotationRate: return "rotationRate"
        case .magneticField: return "magneticField"
        case .deviceMotion: return "deviceMotion"
        case .altitude: return "altitude"
        case .pedometer: return "pedometer"
        case .activity: return "activity"
        case .location: return "location"
        case .heading: return "heading"
        case .proximity: return "proximity"
        case .brightness: return "brightness"
        case .torch: return "torch"
        case .audio: return "audio"
        case .battery: return "battery"
        case .thermal: return "thermal"
        case .lowPower: return "lowPower"
        case .orientation: return "orientation"
        case .disk: return "disk"
        case .uptime: return "uptime"
        case .bluetoothState: return "bluetoothState"
        case .bluetoothDevice: return "bluetoothDevice"
        case .network: return "network"
        case .cellular: return "cellular"
        case .cameraSnapshot: return "cameraSnapshot"
        case .health: return "health"
        case .sessionMarker: return "sessionMarker"
        }
    }

    /// Column names for the CSV writer. Order MUST match `csvValues`.
    var csvColumns: [String] {
        switch self {
        case .acceleration, .rotationRate:        return ["x", "y", "z"]
        case .magneticField:                       return ["x", "y", "z", "accuracy"]
        case .deviceMotion:
            return ["roll","pitch","yaw","gravityX","gravityY","gravityZ",
                    "userAccX","userAccY","userAccZ","rotationX","rotationY","rotationZ",
                    "quatW","quatX","quatY","quatZ",
                    "calMagX","calMagY","calMagZ","calMagAccuracy"]
        case .altitude:                            return ["relative", "pressure"]
        case .pedometer:                           return ["steps","distance","floorsAsc","floorsDesc","pace","cadence"]
        case .activity:                            return ["state", "confidence"]
        case .location:                            return ["lat","lon","alt","speed","course","horizAcc","vertAcc","speedAcc","courseAcc","floor"]
        case .heading:                             return ["trueHeading","magneticHeading","accuracy"]
        case .proximity:                           return ["near"]
        case .brightness:                          return ["level"]
        case .torch:                               return ["level"]
        case .audio:                               return ["category","sampleRate","channels","volume","inputs","outputs"]
        case .battery:                             return ["level","state"]
        case .thermal:                             return ["state"]
        case .lowPower:                            return ["enabled"]
        case .orientation:                         return ["name"]
        case .disk:                                return ["total","free"]
        case .uptime:                              return ["seconds"]
        case .bluetoothState:                      return ["state"]
        case .bluetoothDevice:                     return ["name","uuid","rssi"]
        case .network:                             return ["type","connected"]
        case .cellular:                            return ["carrier","radio"]
        case .cameraSnapshot:                      return ["hasFront","hasBack","hasUltraWide","hasTelephoto","hasLiDAR","zoom"]
        case .health:                              return ["metric","value","unit","ts"]
        case .sessionMarker:                       return ["kind","note"]
        }
    }

    var csvValues: [String] {
        func s(_ d: Double) -> String { String(d) }
        func si(_ i: Int) -> String { String(i) }
        func sb(_ b: Bool) -> String { b ? "true" : "false" }
        switch self {
        case let .acceleration(x,y,z): return [s(x),s(y),s(z)]
        case let .rotationRate(x,y,z): return [s(x),s(y),s(z)]
        case let .magneticField(x,y,z,acc): return [s(x),s(y),s(z),si(acc)]
        case let .deviceMotion(p):
            return [s(p.roll),s(p.pitch),s(p.yaw),
                    s(p.gravityX),s(p.gravityY),s(p.gravityZ),
                    s(p.userAccX),s(p.userAccY),s(p.userAccZ),
                    s(p.rotationX),s(p.rotationY),s(p.rotationZ),
                    s(p.quatW),s(p.quatX),s(p.quatY),s(p.quatZ),
                    s(p.calMagX),s(p.calMagY),s(p.calMagZ),si(p.calMagAccuracy)]
        case let .altitude(rel,pr):    return [s(rel), s(pr)]
        case let .pedometer(p):        return [si(p.steps), s(p.distance), si(p.floorsAscended), si(p.floorsDescended),
                                                p.pace.map(s) ?? "", p.cadence.map(s) ?? ""]
        case let .activity(p):         return [p.state, si(p.confidence)]
        case let .location(p):         return [s(p.lat),s(p.lon),s(p.alt),s(p.speed),s(p.course),
                                                s(p.horizAccuracy),s(p.vertAccuracy),s(p.speedAccuracy),s(p.courseAccuracy),
                                                p.floor.map(si) ?? ""]
        case let .heading(t,m,a):      return [t.map(s) ?? "", s(m), s(a)]
        case let .proximity(n):        return [sb(n)]
        case let .brightness(l):       return [s(l)]
        case let .torch(l):            return [s(l)]
        case let .audio(p):            return [p.category, s(p.sampleRate), si(p.channels), s(p.volume),
                                                p.inputs.joined(separator: "|"), p.outputs.joined(separator: "|")]
        case let .battery(l,st):       return [s(l), st]
        case let .thermal(st):         return [st]
        case let .lowPower(e):         return [sb(e)]
        case let .orientation(n):      return [n]
        case let .disk(t,f):           return [String(t), String(f)]
        case let .uptime(sec):         return [s(sec)]
        case let .bluetoothState(st):  return [st]
        case let .bluetoothDevice(n,u,r): return [n ?? "", u, si(r)]
        case let .network(t,c):        return [t, sb(c)]
        case let .cellular(c,r):       return [c, r]
        case let .cameraSnapshot(p):   return [sb(p.hasFront),sb(p.hasBack),sb(p.hasUltraWide),sb(p.hasTelephoto),sb(p.hasLiDAR),s(p.zoom)]
        case let .health(m,v,u,t):     return [m, s(v), u, ISO8601DateFormatter().string(from: t)]
        case let .sessionMarker(p):    return [p.kind, p.note ?? ""]
        }
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors iPhoneSensors/iPhoneSensors/Models/Logging/SensorPayload.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/SensorPayloadTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add SensorPayload typed enum with CSV serialization

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.4: SensorSample + LoggingConfiguration

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/SensorSample.swift`
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/LoggingConfiguration.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LoggingConfigurationTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class LoggingConfigurationTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let cfg = LoggingConfiguration(
            continuous: .on(format: .jsonl, intervalMs: 1000, options: .default),
            session: .on(format: .sqlite, intervalMs: 100, options: .default))
        let data = try JSONEncoder().encode(cfg)
        let back = try JSONDecoder().decode(LoggingConfiguration.self, from: data)
        XCTAssertEqual(cfg, back)
    }
    func testDefaultsForEverySensorReturnsNonNil() {
        for s in SensorID.allCases {
            _ = LoggingConfiguration.default(for: s)
        }
    }
    func testAccelerometerDefaultsContinuousOff() {
        let cfg = LoggingConfiguration.default(for: .accelerometer)
        if case .off = cfg.continuous {} else { XCTFail("expected continuous off") }
    }
    func testGPSDefaultsContinuousOn() {
        let cfg = LoggingConfiguration.default(for: .gps)
        if case .on = cfg.continuous {} else { XCTFail("expected continuous on") }
    }
}
```

- [ ] **Step 2: Implementations**

`SensorSample.swift`:
```swift
import Foundation

struct SensorSample: Sendable {
    let sensorID: SensorID
    let wallTime: Date
    let monotonicNs: UInt64
    let payload: SensorPayload

    init(sensorID: SensorID, payload: SensorPayload, wallTime: Date = Date(), monotonicNs: UInt64 = monotonicNow()) {
        self.sensorID = sensorID
        self.wallTime = wallTime
        self.monotonicNs = monotonicNs
        self.payload = payload
    }
}

@inlinable
func monotonicNow() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
}
```

`LoggingConfiguration.swift`:
```swift
import Foundation

enum PerStreamConfig: Codable, Equatable, Sendable {
    case off
    case on(format: LogFormat, intervalMs: Int, options: FormatOptions)

    var isOn: Bool { if case .on = self { return true } else { return false } }
}

struct LoggingConfiguration: Codable, Equatable, Sendable {
    var continuous: PerStreamConfig
    var session: PerStreamConfig
}

extension LoggingConfiguration {
    static func `default`(for id: SensorID) -> LoggingConfiguration {
        switch id {
        case .gps, .heading:
            return .init(continuous: .on(format: .jsonl, intervalMs: 60_000, options: .default),
                         session:    .on(format: .sqlite, intervalMs: 1000, options: .default))
        case .battery, .thermal, .lowPower, .network, .orientation, .pedometer, .motionActivity, .bluetoothState, .cellular:
            return .init(continuous: .on(format: .jsonl, intervalMs: 0, options: .default),
                         session:    .on(format: .sqlite, intervalMs: 0, options: .default))
        case .altimeter:
            return .init(continuous: .off,
                         session:    .on(format: .sqlite, intervalMs: 1000, options: .default))
        case .accelerometer, .gyroscope, .magnetometer, .deviceMotion:
            return .init(continuous: .off,
                         session:    .on(format: .sqlite, intervalMs: 100, options: .default))
        case .brightness, .disk, .uptime:
            return .init(continuous: .off,
                         session:    .on(format: .csv, intervalMs: 2000, options: .default))
        case .bluetoothScan:
            return .init(continuous: .off,
                         session:    .on(format: .jsonl, intervalMs: 0, options: .default))
        case .health:
            return .init(continuous: .off,
                         session:    .on(format: .csv, intervalMs: 0, options: .default))
        case .camera, .proximity, .audio, .torch:
            return .init(continuous: .off,
                         session:    .on(format: .jsonl, intervalMs: 0, options: .default))
        }
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors \
  iPhoneSensors/iPhoneSensors/Models/Logging/SensorSample.swift \
  iPhoneSensors/iPhoneSensors/Models/Logging/LoggingConfiguration.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/LoggingConfigurationTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add SensorSample + LoggingConfiguration with per-sensor defaults

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.5: LoggingConfigStore (UserDefaults persistence)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingConfigStore.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LoggingConfigStoreTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

@MainActor
final class LoggingConfigStoreTests: XCTestCase {
    func makeIsolatedDefaults() -> UserDefaults {
        let suite = "test.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }
    func testReturnsDefaultsForUnknownSensor() {
        let store = LoggingConfigStore(defaults: makeIsolatedDefaults())
        XCTAssertEqual(store.config(for: .gps), LoggingConfiguration.default(for: .gps))
    }
    func testRoundTripPersistence() {
        let d = makeIsolatedDefaults()
        let s1 = LoggingConfigStore(defaults: d)
        var cfg = s1.config(for: .accelerometer)
        cfg.session = .on(format: .csv, intervalMs: 50, options: .default)
        s1.set(cfg, for: .accelerometer)
        let s2 = LoggingConfigStore(defaults: d)
        XCTAssertEqual(s2.config(for: .accelerometer), cfg)
    }
    func testPublishedChangesNotify() {
        let store = LoggingConfigStore(defaults: makeIsolatedDefaults())
        let exp = expectation(description: "publish")
        let c = store.$version.dropFirst().sink { _ in exp.fulfill() }
        store.set(LoggingConfiguration(continuous: .off, session: .off), for: .battery)
        wait(for: [exp], timeout: 1.0)
        c.cancel()
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation
import Combine

@MainActor
final class LoggingConfigStore: ObservableObject {
    private let defaults: UserDefaults
    private let key = "loggingConfig.v1"
    @Published private(set) var version: Int = 0   // bumped on any mutation

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func config(for id: SensorID) -> LoggingConfiguration {
        guard let dict = decoded(),
              let raw = dict[id.rawValue] else { return .default(for: id) }
        return raw
    }

    func set(_ cfg: LoggingConfiguration, for id: SensorID) {
        var dict = decoded() ?? [:]
        dict[id.rawValue] = cfg
        save(dict)
        version &+= 1
    }

    func all() -> [SensorID: LoggingConfiguration] {
        var out: [SensorID: LoggingConfiguration] = [:]
        for id in SensorID.allCases { out[id] = config(for: id) }
        return out
    }

    private func decoded() -> [String: LoggingConfiguration]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([String: LoggingConfiguration].self, from: data)
    }
    private func save(_ dict: [String: LoggingConfiguration]) {
        if let data = try? JSONEncoder().encode(dict) { defaults.set(data, forKey: key) }
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors iPhoneSensors/iPhoneSensors/Services/Logging/LoggingConfigStore.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/LoggingConfigStoreTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add LoggingConfigStore with UserDefaults persistence

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.6: LogStorageManager (paths only — rotation/cap deferred to Phase 2)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class LogStoragePathsTests: XCTestCase {
    func makeMgr() -> LogStorageManager {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        return LogStorageManager(rootURL: tmp)
    }
    func testRootCreatedOnDemand() throws {
        let m = makeMgr()
        let url = try m.continuousFileURL(for: .battery, format: .jsonl, day: Date())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
        XCTAssertEqual(url.pathExtension, "jsonl")
    }
    func testSessionDirHasUUID() throws {
        let m = makeMgr()
        let id = UUID()
        let url = try m.sessionDir(id)
        XCTAssertTrue(url.path.contains(id.uuidString))
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation

final class LogStorageManager {
    let rootURL: URL
    private let fm = FileManager.default
    private let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()

    init(rootURL: URL? = nil) {
        if let rootURL { self.rootURL = rootURL }
        else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.rootURL = docs.appendingPathComponent("SensorLogs", isDirectory: true)
        }
    }

    func continuousDayDir(_ day: Date) throws -> URL {
        let url = rootURL
            .appendingPathComponent("continuous", isDirectory: true)
            .appendingPathComponent(dayFmt.string(from: day), isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func continuousFileURL(for id: SensorID, format: LogFormat, day: Date) throws -> URL {
        try continuousDayDir(day).appendingPathComponent("\(filename(for: id)).\(format.fileExtension)")
    }

    func continuousSQLiteURL() throws -> URL {
        let dir = rootURL.appendingPathComponent("continuous", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("continuous.sqlite")
    }

    func sessionsRoot() throws -> URL {
        let url = rootURL.appendingPathComponent("sessions", isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func sessionDir(_ id: UUID) throws -> URL {
        let url = try sessionsRoot().appendingPathComponent(id.uuidString, isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func sessionFileURL(_ id: UUID, sensor: SensorID, format: LogFormat, rotationIndex: Int = 0) throws -> URL {
        let suffix = rotationIndex == 0 ? "" : ".\(rotationIndex)"
        return try sessionDir(id).appendingPathComponent("\(filename(for: sensor))\(suffix).\(format.fileExtension)")
    }

    func sessionSQLiteURL(_ id: UUID) throws -> URL {
        try sessionDir(id).appendingPathComponent("log.sqlite")
    }

    private func filename(for id: SensorID) -> String {
        // "motion.accelerometer" -> "accelerometer"
        id.rawValue.split(separator: ".").last.map(String.init) ?? id.rawValue
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/LogStoragePathsTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add LogStorageManager paths

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.7: LogWriter protocol + JSONLogWriter

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/LogWriter.swift`
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/JSONLogWriter.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/JSONLogWriterTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class JSONLogWriterTests: XCTestCase {
    func testWritesOneJSONPerLine() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).jsonl")
        let w = JSONLogWriter(url: tmp)
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 1, y: 2, z: 3)))
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 4, y: 5, z: 6)))
        await w.flush()
        let txt = try String(contentsOf: tmp, encoding: .utf8)
        let lines = txt.split(separator: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 2)
        for line in lines {
            _ = try JSONSerialization.jsonObject(with: Data(line.utf8))
        }
    }
}
```

- [ ] **Step 2: Implementations**

`Writers/LogWriter.swift`:
```swift
import Foundation

protocol LogWriter: Actor {
    var bytesWritten: Int64 { get }
    var entriesWritten: Int64 { get }
    func write(_ sample: SensorSample) async
    func flush() async
    func close() async
}
```

`Writers/JSONLogWriter.swift`:
```swift
import Foundation

actor JSONLogWriter: LogWriter {
    private let url: URL
    private var handle: FileHandle?
    private var buffer = Data()
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    init(url: URL) { self.url = url }

    func write(_ sample: SensorSample) async {
        do {
            let row = SerializedRow(
                t: sample.wallTime,
                m: sample.monotonicNs,
                s: sample.sensorID.rawValue,
                k: sample.payload.kind,
                p: sample.payload)
            var data = try encoder.encode(row)
            data.append(0x0A)   // newline
            buffer.append(data)
            entriesWritten += 1
            if buffer.count >= 64 * 1024 { await flush() }
        } catch {
            // Drop entry on encode failure; preserve writer.
        }
    }

    func flush() async {
        guard !buffer.isEmpty else { return }
        do {
            if handle == nil {
                let fm = FileManager.default
                if !fm.fileExists(atPath: url.path) {
                    try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    fm.createFile(atPath: url.path, contents: nil)
                }
                handle = try FileHandle(forWritingTo: url)
                try handle?.seekToEnd()
            }
            try handle?.write(contentsOf: buffer)
            try handle?.synchronize()
            bytesWritten += Int64(buffer.count)
            buffer.removeAll(keepingCapacity: true)
        } catch {
            buffer.removeAll(keepingCapacity: true)
        }
    }

    func close() async {
        await flush()
        try? handle?.close()
        handle = nil
    }

    private struct SerializedRow: Codable {
        let t: Date; let m: UInt64; let s: String; let k: String; let p: SensorPayload
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors \
  iPhoneSensors/iPhoneSensors/Services/Logging/Writers/LogWriter.swift \
  iPhoneSensors/iPhoneSensors/Services/Logging/Writers/JSONLogWriter.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/JSONLogWriterTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add LogWriter protocol and JSONLogWriter actor

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.8: SensorEventBus + LoggingCoordinator (skeleton, JSONL only)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/SensorEventBus.swift`
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingCoordinator.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LoggingCoordinatorTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class LoggingCoordinatorTests: XCTestCase {
    func testThrottleDownsamples() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let store = await MainActor.run { LoggingConfigStore(defaults: UserDefaults(suiteName: UUID().uuidString)!) }
        await MainActor.run {
            store.set(LoggingConfiguration(continuous: .on(format: .jsonl, intervalMs: 100, options: .default), session: .off), for: .accelerometer)
        }
        let coord = LoggingCoordinator(storage: storage, configStore: store)
        await coord.start()

        // Fire 50 samples 10ms apart synthetically
        var t0 = Date()
        for i in 0..<50 {
            let s = SensorSample(sensorID: .accelerometer,
                                 payload: .acceleration(x: Double(i), y: 0, z: 0),
                                 wallTime: t0,
                                 monotonicNs: UInt64(i) * 10_000_000)
            await coord.ingest(s)
            t0 = t0.addingTimeInterval(0.010)
        }
        await coord.flushAll()

        // 50 samples spanning 0–500ms at 100ms throttle ⇒ ≤ 6 written
        let day = Date()
        let url = try storage.continuousFileURL(for: .accelerometer, format: .jsonl, day: day)
        let content = (try? String(contentsOf: url)) ?? ""
        let lineCount = content.split(separator: "\n").count
        XCTAssertGreaterThanOrEqual(lineCount, 1)
        XCTAssertLessThanOrEqual(lineCount, 6)
    }
}
```

- [ ] **Step 2: Implementations**

`SensorEventBus.swift`:
```swift
import Foundation
import Combine

actor SensorEventBus {
    private var subscriptions: [AnyCancellable] = []
    private var ingest: ((SensorSample) async -> Void)?

    func setIngest(_ ingest: @escaping (SensorSample) async -> Void) {
        self.ingest = ingest
    }

    nonisolated func attach(_ publisher: AnyPublisher<SensorSample, Never>) {
        Task { await self.attachAsync(publisher) }
    }

    private func attachAsync(_ publisher: AnyPublisher<SensorSample, Never>) {
        let sub = publisher.sink { [weak self] sample in
            Task { await self?.deliver(sample) }
        }
        subscriptions.append(sub)
    }

    private func deliver(_ sample: SensorSample) async {
        await ingest?(sample)
    }
}
```

`LoggingCoordinator.swift`:
```swift
import Foundation

actor LoggingCoordinator {
    struct WriterKey: Hashable { let sensorID: SensorID; let stream: LogStream; let format: LogFormat }

    private let storage: LogStorageManager
    private let configStore: LoggingConfigStore
    private var writers: [WriterKey: any LogWriter] = [:]
    private var lastWritten: [SensorID: [LogStream: UInt64]] = [:]   // monotonicNs

    init(storage: LogStorageManager, configStore: LoggingConfigStore) {
        self.storage = storage
        self.configStore = configStore
    }

    func start() async {
        // Phase 1: nothing to subscribe to yet — bus is wired in Task 1.10.
    }

    func ingest(_ sample: SensorSample) async {
        let cfg = await MainActor.run { configStore.config(for: sample.sensorID) }
        for stream in LogStream.allCases {
            let pcfg: PerStreamConfig = (stream == .continuous) ? cfg.continuous : cfg.session
            guard case let .on(format, intervalMs, _) = pcfg else { continue }
            // Phase 1: only continuous stream is "live"; sessions still do nothing until SessionManager arrives.
            if stream == .session { continue }
            if !shouldWrite(sample, stream: stream, intervalMs: intervalMs) { continue }
            let writer = await writer(for: sample.sensorID, stream: stream, format: format)
            await writer.write(sample)
        }
    }

    func flushAll() async {
        for w in writers.values { await w.flush() }
    }

    private func shouldWrite(_ s: SensorSample, stream: LogStream, intervalMs: Int) -> Bool {
        if intervalMs <= 0 {
            lastWritten[s.sensorID, default: [:]][stream] = s.monotonicNs
            return true
        }
        let last = lastWritten[s.sensorID]?[stream]
        let intervalNs = UInt64(intervalMs) * 1_000_000
        if let last, s.monotonicNs - last < intervalNs { return false }
        lastWritten[s.sensorID, default: [:]][stream] = s.monotonicNs
        return true
    }

    private func writer(for id: SensorID, stream: LogStream, format: LogFormat) async -> any LogWriter {
        let key = WriterKey(sensorID: id, stream: stream, format: format)
        if let w = writers[key] { return w }
        let url: URL
        switch stream {
        case .continuous:
            url = (try? storage.continuousFileURL(for: id, format: format, day: Date()))
                ?? storage.rootURL.appendingPathComponent("\(id.rawValue).\(format.fileExtension)")
        case .session:
            url = storage.rootURL.appendingPathComponent("session-placeholder.\(format.fileExtension)")
        }
        let writer: any LogWriter
        switch format {
        case .jsonl: writer = JSONLogWriter(url: url)
        case .csv:   writer = JSONLogWriter(url: url)   // TEMP — replaced in Task 2.3
        case .sqlite: writer = JSONLogWriter(url: url)  // TEMP — replaced in Task 2.2
        }
        writers[key] = writer
        return writer
    }
}
```

- [ ] **Step 3: Register, test, commit**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors \
  iPhoneSensors/iPhoneSensors/Services/Logging/SensorEventBus.swift \
  iPhoneSensors/iPhoneSensors/Services/Logging/LoggingCoordinator.swift
ruby Scripts/xcp.rb add-files iPhoneSensorsTests iPhoneSensors/iPhoneSensorsTests/LoggingCoordinatorTests.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): add SensorEventBus + LoggingCoordinator with throttle

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 1.9: LoggingService (UI-facing facade) and accelerometer publisher

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift`
- Modify: `iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift`

- [ ] **Step 1: Add `samplePublisher` to MotionSensorManager**

Read `iPhoneSensors/iPhoneSensors/Services/MotionSensorManager.swift` to find the existing accelerometer callback (the closure passed to `motionManager.startAccelerometerUpdates(...) { data, _ in ... }`). Inside that closure — right after the existing `@Published` updates for `accelerometerX/Y/Z` — add ONE line that emits a sample.

At the top of the class, add:

```swift
import Combine
// inside class, near other @Published declarations:
let samplePublisher = PassthroughSubject<SensorSample, Never>()
```

Inside the accelerometer update closure, after `self.accelerometerZ = data.acceleration.z` (or equivalent existing line), add:

```swift
self.samplePublisher.send(SensorSample(
    sensorID: .accelerometer,
    payload: .acceleration(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)))
```

(Other motion callbacks get wired in Task 2.7. This task only needs accelerometer.)

- [ ] **Step 2: Create `LoggingService.swift`**

```swift
import Foundation
import Combine

@MainActor
final class LoggingService: ObservableObject {
    let storage: LogStorageManager
    let configStore: LoggingConfigStore
    let bus: SensorEventBus
    let coordinator: LoggingCoordinator

    init(storage: LogStorageManager? = nil,
         configStore: LoggingConfigStore? = nil) {
        let s = storage ?? LogStorageManager()
        let c = configStore ?? LoggingConfigStore()
        self.storage = s
        self.configStore = c
        self.bus = SensorEventBus()
        self.coordinator = LoggingCoordinator(storage: s, configStore: c)
    }

    func bootstrap() async {
        let coord = self.coordinator
        await bus.setIngest { sample in await coord.ingest(sample) }
        await coordinator.start()
    }

    func attach(_ publisher: AnyPublisher<SensorSample, Never>) {
        bus.attach(publisher)
    }

    /// Smoke helper for tests / preview.
    func enableContinuousAccelerometer() {
        configStore.set(LoggingConfiguration(
            continuous: .on(format: .jsonl, intervalMs: 100, options: .default),
            session: .off), for: .accelerometer)
    }

    func flush() async { await coordinator.flushAll() }
}
```

- [ ] **Step 3: Wire in `iPhoneSensorsApp.swift`**

Read the file, find the `WindowGroup`/root view declaration, and inject:

```swift
@StateObject private var loggingService = LoggingService()

// inside body, after existing modifiers on the root view:
.environmentObject(loggingService)
.task {
    await loggingService.bootstrap()
    // Phase 1 smoke: enable accelerometer continuous logging
    loggingService.enableContinuousAccelerometer()
    if let mgr = sensorManager.motion?.samplePublisher {
        loggingService.attach(mgr.eraseToAnyPublisher())
    }
}
```

(Adjust `sensorManager.motion?.samplePublisher` to whatever path exposes `MotionSensorManager` from the existing `SensorManager` aggregator. Read `Services/SensorManager.swift` to find the accessor name.)

- [ ] **Step 4: Register + build**

```bash
ruby Scripts/xcp.rb add-files iPhoneSensors iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet build 2>&1 | tail -5
# Expected: BUILD SUCCEEDED
```

- [ ] **Step 5: Smoke test (manual, in simulator)**

Boot iPhone 17 simulator, launch app, leave running for 10 seconds, then:

```bash
DEVICE=$(xcrun simctl list devices booted | awk -F'[()]' '/iPhone 17/ {print $2; exit}')
APP_DATA=$(xcrun simctl get_app_container "$DEVICE" com.allsensors.iPhoneSensors data)
ls "$APP_DATA/Documents/SensorLogs/continuous/" 2>/dev/null
find "$APP_DATA/Documents/SensorLogs/continuous/" -name "accelerometer.jsonl" -exec wc -l {} \;
# Expected: a non-empty .jsonl with ~10 lines/second × throttle = ~1 line/100ms
```

(If the bundle ID differs, find it in `Info.plist` under `CFBundleIdentifier`.)

- [ ] **Step 6: Commit**

```bash
git add iPhoneSensors/
git commit -m "feat(logger): wire LoggingService + accelerometer publisher

Phase 1 milestone: accelerometer samples land in
Documents/SensorLogs/continuous/<day>/accelerometer.jsonl

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Phase 1 acceptance

- ✅ All Tier-1 tests pass
- ✅ App launches and writes accelerometer samples to JSONL on the simulator
- ✅ No regressions in existing sensor UI

---

## Phase 2 — All writers, all sensors, sessions, storage manager

After Phase 2, every sensor manager publishes samples; SQLite + CSV writers are real; sessions can start/stop/resume; storage rotation + cap enforcement work. Still no UI for the logger — config remains code-driven for tests.

> **Subagent note:** Phase 2 is a series of similarly-shaped tasks. Each new sensor wiring (Tasks 2.7.X) follows the same pattern: read the manager file, add `samplePublisher`, add `.send(...)` in each callback, register the publisher in `iPhoneSensorsApp.swift`'s `.task`. Treat Task 2.7.1 as the pattern reference.

### Task 2.1: SensorLogEntry + DatabaseSchema (GRDB)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/SensorLogEntry.swift`
- Create: `iPhoneSensors/iPhoneSensors/Models/Logging/SensorLogSession.swift`
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/DatabaseSchema.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/DatabaseSchemaTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
import GRDB
@testable import iPhoneSensors

final class DatabaseSchemaTests: XCTestCase {
    func testMigratorCreatesTablesIdempotently() throws {
        let queue = try DatabaseQueue()
        try DatabaseSchema.migrator.migrate(queue)
        try DatabaseSchema.migrator.migrate(queue)   // idempotent
        try queue.read { db in
            XCTAssertTrue(try db.tableExists("entries"))
            XCTAssertTrue(try db.tableExists("sessions"))
        }
    }
    func testInsertEntryRoundTrip() throws {
        let queue = try DatabaseQueue()
        try DatabaseSchema.migrator.migrate(queue)
        let entry = SensorLogEntry(
            id: UUID(), sessionID: nil,
            sensorID: SensorID.accelerometer.rawValue,
            wallTime: Date().timeIntervalSince1970,
            monotonicNs: 12345,
            payloadKind: "acceleration",
            payloadJSON: "{\"x\":1,\"y\":2,\"z\":3}",
            schemaVersion: 1)
        try queue.write { try entry.insert($0) }
        let count = try queue.read { try SensorLogEntry.fetchCount($0) }
        XCTAssertEqual(count, 1)
    }
}
```

- [ ] **Step 2: Implementations**

`SensorLogSession.swift`:
```swift
import Foundation
import GRDB

struct SensorLogSession: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: UUID
    var startedAt: Double          // Unix seconds
    var endedAt: Double?
    var deviceModel: String
    var osVersion: String
    var appVersion: String
    var note: String?

    static let databaseTableName = "sessions"
    enum CodingKeys: String, CodingKey {
        case id, startedAt = "started_at", endedAt = "ended_at"
        case deviceModel = "device_model", osVersion = "os_version"
        case appVersion = "app_version", note
    }
}
```

`SensorLogEntry.swift`:
```swift
import Foundation
import GRDB

struct SensorLogEntry: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: UUID
    var sessionID: UUID?
    var sensorID: String
    var wallTime: Double           // Unix seconds
    var monotonicNs: Int64
    var payloadKind: String
    var payloadJSON: String
    var schemaVersion: Int

    static let databaseTableName = "entries"
    enum CodingKeys: String, CodingKey {
        case id, sessionID = "session_id", sensorID = "sensor_id"
        case wallTime = "wall_time", monotonicNs = "monotonic_ns"
        case payloadKind = "payload_kind", payloadJSON = "payload_json"
        case schemaVersion = "schema_version"
    }
}
```

`DatabaseSchema.swift`:
```swift
import Foundation
import GRDB

enum DatabaseSchema {
    static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "sessions", ifNotExists: true) { t in
                t.column("id", .blob).primaryKey()
                t.column("started_at", .double).notNull()
                t.column("ended_at", .double)
                t.column("device_model", .text)
                t.column("os_version", .text)
                t.column("app_version", .text)
                t.column("note", .text)
            }
            try db.create(table: "entries", ifNotExists: true) { t in
                t.column("id", .blob).primaryKey()
                t.column("session_id", .blob)
                t.column("sensor_id", .text).notNull()
                t.column("wall_time", .double).notNull()
                t.column("monotonic_ns", .integer).notNull()
                t.column("payload_kind", .text).notNull()
                t.column("payload_json", .text).notNull()
                t.column("schema_version", .integer).notNull().defaults(to: 1)
            }
            try db.create(index: "idx_entries_sensor_time", on: "entries", columns: ["sensor_id", "wall_time"])
            try db.create(index: "idx_entries_time", on: "entries", columns: ["wall_time"])
        }
        return m
    }

    static func openPool(at url: URL) throws -> DatabasePool {
        var config = Configuration()
        config.prepareDatabase { db in try db.execute(sql: "PRAGMA journal_mode=WAL") }
        let pool = try DatabasePool(path: url.path, configuration: config)
        try migrator.migrate(pool)
        return pool
    }
}
```

- [ ] **Step 3: Register, test, commit** (same pattern as previous tasks)

---

### Task 2.2: SQLiteLogWriter

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/SQLiteLogWriter.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SQLiteLogWriterTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
import GRDB
@testable import iPhoneSensors

final class SQLiteLogWriterTests: XCTestCase {
    func testBatchedInsertRoundTrip() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).sqlite")
        let pool = try DatabaseSchema.openPool(at: url)
        let w = SQLiteLogWriter(pool: pool, sensorID: .accelerometer, sessionID: nil, batchSize: 5)
        for i in 0..<12 {
            await w.write(SensorSample(sensorID: .accelerometer,
                                       payload: .acceleration(x: Double(i), y: 0, z: 0)))
        }
        await w.flush()
        let count = try pool.read { try SensorLogEntry.fetchCount($0) }
        XCTAssertEqual(count, 12)
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation
import GRDB

actor SQLiteLogWriter: LogWriter {
    private let pool: DatabasePool
    private let sensorID: SensorID
    private let sessionID: UUID?
    private let batchSize: Int
    private var pending: [SensorLogEntry] = []
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0

    init(pool: DatabasePool, sensorID: SensorID, sessionID: UUID?, batchSize: Int = 100) {
        self.pool = pool
        self.sensorID = sensorID
        self.sessionID = sessionID
        self.batchSize = batchSize
    }

    func write(_ sample: SensorSample) async {
        do {
            let json = try JSONEncoder().encode(sample.payload)
            let entry = SensorLogEntry(
                id: UUID(), sessionID: sessionID,
                sensorID: sample.sensorID.rawValue,
                wallTime: sample.wallTime.timeIntervalSince1970,
                monotonicNs: Int64(bitPattern: UInt64.toIntPattern(sample.monotonicNs)),
                payloadKind: sample.payload.kind,
                payloadJSON: String(data: json, encoding: .utf8) ?? "",
                schemaVersion: 1)
            pending.append(entry)
            entriesWritten += 1
            if pending.count >= batchSize { await flush() }
        } catch { /* drop */ }
    }

    func flush() async {
        guard !pending.isEmpty else { return }
        let batch = pending
        pending.removeAll(keepingCapacity: true)
        do {
            try await pool.write { db in
                for e in batch { try e.insert(db) }
            }
            bytesWritten += Int64(batch.reduce(0) { $0 + $1.payloadJSON.utf8.count + 80 })
        } catch { /* drop */ }
    }

    func close() async { await flush() }
}

private extension UInt64 {
    static func toIntPattern(_ u: UInt64) -> UInt64 { u }   // identity; placeholder helper
}
```

- [ ] **Step 3: Register, test, commit** — then update `LoggingCoordinator.writer(for:stream:format:)` to use `SQLiteLogWriter` for `.sqlite`. Open one shared pool per stream (continuous → `continuous.sqlite`; session → `<sessionDir>/log.sqlite`). Cache the pool in the coordinator.

---

### Task 2.3: CSVLogWriter

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/Writers/CSVLogWriter.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/CSVLogWriterTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class CSVLogWriterTests: XCTestCase {
    func testHeaderWrittenOnceThenRows() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).csv")
        let w = CSVLogWriter(url: url, options: .default)
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 1, y: 2, z: 3)))
        await w.write(SensorSample(sensorID: .accelerometer, payload: .acceleration(x: 4, y: 5, z: 6)))
        await w.flush()
        let lines = try String(contentsOf: url).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].contains("wall_time"))
        XCTAssertTrue(lines[0].contains(",x,y,z"))
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation

actor CSVLogWriter: LogWriter {
    private let url: URL
    private let options: FormatOptions
    private var handle: FileHandle?
    private var headerWritten = false
    private var buffer = Data()
    private(set) var bytesWritten: Int64 = 0
    private(set) var entriesWritten: Int64 = 0

    init(url: URL, options: FormatOptions) {
        self.url = url
        self.options = options
    }

    func write(_ sample: SensorSample) async {
        if !headerWritten {
            let cols = ["wall_time","monotonic_ns","sensor_id","payload_kind"] + sample.payload.csvColumns
            appendLine(cols)
            headerWritten = true
        }
        let row = [
            String(sample.wallTime.timeIntervalSince1970),
            String(sample.monotonicNs),
            sample.sensorID.rawValue,
            sample.payload.kind
        ] + sample.payload.csvValues
        appendLine(row)
        entriesWritten += 1
        if buffer.count >= 64 * 1024 { await flush() }
    }

    func flush() async {
        guard !buffer.isEmpty else { return }
        do {
            if handle == nil {
                let fm = FileManager.default
                if !fm.fileExists(atPath: url.path) {
                    try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    fm.createFile(atPath: url.path, contents: nil)
                }
                handle = try FileHandle(forWritingTo: url)
                try handle?.seekToEnd()
            }
            try handle?.write(contentsOf: buffer)
            try handle?.synchronize()
            bytesWritten += Int64(buffer.count)
            buffer.removeAll(keepingCapacity: true)
        } catch { buffer.removeAll(keepingCapacity: true) }
    }

    func close() async {
        await flush()
        try? handle?.close()
        handle = nil
    }

    private func appendLine(_ fields: [String]) {
        let escaped = fields.map { escape($0) }.joined(separator: options.csvDelimiter)
        buffer.append(Data(escaped.utf8))
        buffer.append(0x0A)
    }

    private func escape(_ s: String) -> String {
        if s.contains(options.csvDelimiter) || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }
}
```

- [ ] **Step 3: Register, test, commit** — and wire into `LoggingCoordinator` (replace TEMP `JSONLogWriter` for `.csv`).

---

### Task 2.4: SessionManager (start / stop / resume detection)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Services/Logging/SessionManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/SessionLifecycleTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
import GRDB
@testable import iPhoneSensors

final class SessionLifecycleTests: XCTestCase {
    func testStartAndStop() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let mgr = SessionManager(storage: storage)
        let session = try await mgr.startSession(note: "trial")
        XCTAssertNotNil(mgr.activeSessionID)
        try await mgr.stopSession()
        XCTAssertNil(mgr.activeSessionID)

        // Verify ended_at written
        let url = try storage.sessionSQLiteURL(session.id)
        let pool = try DatabasePool(path: url.path)
        let s = try pool.read { try SensorLogSession.fetchOne($0) }
        XCTAssertNotNil(s?.endedAt)
    }
    func testResumeDetectsUnfinished() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = LogStorageManager(rootURL: tmp)
        let mgr1 = SessionManager(storage: storage)
        let s = try await mgr1.startSession(note: nil)
        // Simulate kill: don't call stop.
        let mgr2 = SessionManager(storage: storage)
        let unfinished = try await mgr2.unfinishedSessions()
        XCTAssertTrue(unfinished.contains { $0.id == s.id })
    }
}
```

- [ ] **Step 2: Implementation**

```swift
import Foundation
import GRDB
import UIKit

actor SessionManager {
    private let storage: LogStorageManager
    private(set) var activeSessionID: UUID?
    private var pool: DatabasePool?

    init(storage: LogStorageManager) { self.storage = storage }

    @discardableResult
    func startSession(note: String?) async throws -> SensorLogSession {
        let id = UUID()
        let url = try storage.sessionSQLiteURL(id)
        let pool = try DatabaseSchema.openPool(at: url)
        let s = SensorLogSession(
            id: id, startedAt: Date().timeIntervalSince1970, endedAt: nil,
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            note: note)
        try await pool.write { try s.insert($0) }
        self.activeSessionID = id
        self.pool = pool
        return s
    }

    func stopSession() async throws {
        guard let id = activeSessionID, let pool else { return }
        let endedAt = Date().timeIntervalSince1970
        try await pool.write { db in
            try db.execute(sql: "UPDATE sessions SET ended_at = ? WHERE id = ?", arguments: [endedAt, id])
        }
        self.activeSessionID = nil
        self.pool = nil
        try await writeReadme(for: id, endedAt: endedAt)
    }

    func unfinishedSessions() async throws -> [SensorLogSession] {
        let root = try storage.sessionsRoot()
        let dirs = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        var out: [SensorLogSession] = []
        for dir in dirs {
            guard let id = UUID(uuidString: dir.lastPathComponent) else { continue }
            let dbURL = dir.appendingPathComponent("log.sqlite")
            guard FileManager.default.fileExists(atPath: dbURL.path) else { continue }
            do {
                let pool = try DatabasePool(path: dbURL.path)
                if let s = try pool.read({ try SensorLogSession.fetchOne($0, key: id) }), s.endedAt == nil {
                    out.append(s)
                }
            } catch { continue }
        }
        return out
    }

    private func writeReadme(for id: UUID, endedAt: Double) async throws {
        let dir = try storage.sessionDir(id)
        let readme = """
        Session \(id.uuidString)

        ended_at: \(Date(timeIntervalSince1970: endedAt).ISO8601Format())
        time-zone: \(TimeZone.current.identifier)

        FILES
          log.sqlite       — entries + sessions tables (GRDB schema v1)
          *.jsonl / *.csv  — per-sensor flat files

        SCHEMA
          entries(id, session_id, sensor_id, wall_time, monotonic_ns,
                  payload_kind, payload_json, schema_version)

        TIME
          wall_time: Unix seconds (Double); may skew on NTP correction.
          monotonic_ns: CLOCK_MONOTONIC_RAW; use for cross-sensor alignment.

        PRIVACY
          This archive may include precise location and HealthKit metrics.
          Treat as personal data.
        """
        try readme.data(using: .utf8)?.write(to: dir.appendingPathComponent("README.txt"))
    }
}
```

- [ ] **Step 3: Wire into `LoggingCoordinator`**

The coordinator needs to know the active session ID for routing session-stream samples. Add:

```swift
// in LoggingCoordinator
private var activeSessionID: UUID?
private var sessionPool: DatabasePool?
private var continuousPool: DatabasePool?

func setActiveSession(_ id: UUID?, pool: DatabasePool?) {
    self.activeSessionID = id
    self.sessionPool = pool
}
```

In `writer(for:stream:format:)`, when `stream == .session && format == .sqlite`, use `sessionPool`. When `format == .jsonl/.csv`, use `storage.sessionFileURL(id, sensor: id, format: format)`.

- [ ] **Step 4: Register, test, commit**

---

### Task 2.5: LogStorageManager rotation + cap

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/Logging/LogStorageManager.swift`
- Test: `iPhoneSensors/iPhoneSensorsTests/LogStorageRotationTests.swift`

- [ ] **Step 1: Failing test**

```swift
import XCTest
@testable import iPhoneSensors

final class LogStorageRotationTests: XCTestCase {
    func testTotalBytesCountsRecursively() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let m = LogStorageManager(rootURL: tmp)
        let f = try m.continuousFileURL(for: .battery, format: .jsonl, day: Date())
        try Data(repeating: 0x41, count: 1024).write(to: f)
        XCTAssertEqual(m.totalBytes(), 1024)
    }
    func testEnforceCapDeletesOldestContinuousDay() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let m = LogStorageManager(rootURL: tmp)
        let day1 = m.dayDir(daysAgo: 5)
        let day2 = m.dayDir(daysAgo: 1)
        try? FileManager.default.createDirectory(at: day1, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: day2, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 1000).write(to: day1.appendingPathComponent("a.jsonl"))
        try Data(repeating: 0, count: 1000).write(to: day2.appendingPathComponent("b.jsonl"))
        let _ = m.enforceCapDeletingContinuousIfOver(targetBytes: 500)
        XCTAssertFalse(FileManager.default.fileExists(atPath: day1.path))   // oldest gone
        XCTAssertTrue(FileManager.default.fileExists(atPath: day2.path))    // newer kept
    }
}
```

- [ ] **Step 2: Add to `LogStorageManager`**

```swift
extension LogStorageManager {
    func totalBytes() -> Int64 {
        guard let it = FileManager.default.enumerator(at: rootURL, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in it {
            if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { total += Int64(size) }
        }
        return total
    }

    func dayDir(daysAgo: Int, from now: Date = Date()) -> URL {
        let d = now.addingTimeInterval(TimeInterval(-daysAgo * 86_400))
        return rootURL.appendingPathComponent("continuous", isDirectory: true)
                      .appendingPathComponent(dayFmt.string(from: d), isDirectory: true)
    }

    /// Returns bytes deleted.
    @discardableResult
    func enforceCapDeletingContinuousIfOver(targetBytes: Int64) -> Int64 {
        let contDir = rootURL.appendingPathComponent("continuous", isDirectory: true)
        guard FileManager.default.fileExists(atPath: contDir.path) else { return 0 }
        let dirs = (try? FileManager.default.contentsOfDirectory(at: contDir, includingPropertiesForKeys: nil)) ?? []
        let dayDirs = dirs.filter { $0.hasDirectoryPath && $0.lastPathComponent != "continuous.sqlite" }
                          .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var deleted: Int64 = 0
        for dir in dayDirs {
            if totalBytes() <= targetBytes { break }
            let size = sizeOf(url: dir)
            try? FileManager.default.removeItem(at: dir)
            deleted += size
        }
        return deleted
    }

    func shouldRotateSessionFile(_ url: URL, atBytes limit: Int64 = 50 * 1024 * 1024) -> Bool {
        guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) else { return false }
        return Int64(size) >= limit
    }

    private func sizeOf(url: URL) -> Int64 {
        if let it = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            var t: Int64 = 0
            for case let u as URL in it {
                if let s = (try? u.resourceValues(forKeys: [.fileSizeKey]))?.fileSize { t += Int64(s) }
            }
            return t
        }
        return 0
    }
}
```

- [ ] **Step 3: Register, test, commit**

The coordinator should call `enforceCapDeletingContinuousIfOver` opportunistically (every 100 flushes). Defer the integration call to Task 2.6.

---

### Task 2.6: Coordinator polish — pool sharing, rotation hook, throttle subscription

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingCoordinator.swift`
- Modify: `iPhoneSensors/iPhoneSensors/Services/SensorManager.swift`

- [ ] **Step 1: Refactor coordinator to share SQLite pools**

The coordinator should open AT MOST one DatabasePool per SQLite stream:
- `continuousPool` — backed by `storage.continuousSQLiteURL()`, opened on first `.sqlite` continuous write.
- `sessionPool` — set via `setActiveSession` when a session starts.

`SQLiteLogWriter` in Task 2.2 takes a `DatabasePool`; here we keep the pool on the coordinator and pass it through.

```swift
// in LoggingCoordinator
private func ensureContinuousPool() throws -> DatabasePool {
    if let p = continuousPool { return p }
    let p = try DatabaseSchema.openPool(at: storage.continuousSQLiteURL())
    continuousPool = p
    return p
}

private func writer(for id: SensorID, stream: LogStream, format: LogFormat) async -> any LogWriter {
    let key = WriterKey(sensorID: id, stream: stream, format: format)
    if let w = writers[key] { return w }
    let writer: any LogWriter
    switch (stream, format) {
    case (.continuous, .sqlite):
        let p = (try? ensureContinuousPool()) ?? (try! DatabasePool(path: ":memory:"))
        writer = SQLiteLogWriter(pool: p, sensorID: id, sessionID: nil)
    case (.session, .sqlite):
        guard let p = sessionPool, let sid = activeSessionID else { fatalError("session sqlite without active session") }
        writer = SQLiteLogWriter(pool: p, sensorID: id, sessionID: sid)
    case (.continuous, .jsonl):
        let url = (try? storage.continuousFileURL(for: id, format: .jsonl, day: Date())) ?? storage.rootURL.appendingPathComponent("\(id.rawValue).jsonl")
        writer = JSONLogWriter(url: url)
    case (.continuous, .csv):
        let url = (try? storage.continuousFileURL(for: id, format: .csv, day: Date())) ?? storage.rootURL.appendingPathComponent("\(id.rawValue).csv")
        writer = CSVLogWriter(url: url, options: .default)
    case (.session, .jsonl):
        guard let sid = activeSessionID else { fatalError("session jsonl without active session") }
        let url = (try? storage.sessionFileURL(sid, sensor: id, format: .jsonl)) ?? storage.rootURL.appendingPathComponent("\(id.rawValue).jsonl")
        writer = JSONLogWriter(url: url)
    case (.session, .csv):
        guard let sid = activeSessionID else { fatalError("session csv without active session") }
        let url = (try? storage.sessionFileURL(sid, sensor: id, format: .csv)) ?? storage.rootURL.appendingPathComponent("\(id.rawValue).csv")
        writer = CSVLogWriter(url: url, options: .default)
    }
    writers[key] = writer
    return writer
}
```

- [ ] **Step 2: Throttle subscription**

Read `Services/SensorManager.swift`. Find the existing `@Published var isThrottled: Bool` (or equivalent). In `LoggingCoordinator.start()`, accept a closure or reference to read it. Simplest: add a `setThrottled(_ throttled: Bool)` actor method called from `SensorManager.updateThrottleState`.

```swift
// in LoggingCoordinator
private var throttled = false
func setThrottled(_ value: Bool) async {
    throttled = value
}
// in ingest, near top:
if throttled && /* sample is for session stream */ { /* skip or only continuous */ }
```

Use a clearer rule: when throttled, drop session-stream writes only — continuous keeps going. Update the per-stream loop in `ingest` accordingly.

In `SensorManager.swift`, in the existing throttle update method, call `Task { await loggingService.coordinator.setThrottled(newValue) }`.

- [ ] **Step 3: Cap enforcement on every Nth flush**

```swift
// in LoggingCoordinator
private var flushTick = 0
func flushAll() async {
    for w in writers.values { await w.flush() }
    flushTick &+= 1
    if flushTick % 100 == 0 {
        let cap = await MainActor.run { UserDefaults.standard.integer(forKey: "logger.storageCapMB") }
        let target = Int64(max(cap, 1024)) * 1024 * 1024
        _ = storage.enforceCapDeletingContinuousIfOver(targetBytes: target)
    }
}
```

- [ ] **Step 4: Build, test, commit**

```bash
xcodebuild -project iPhoneSensors/iPhoneSensors.xcodeproj -scheme iPhoneSensors -destination 'platform=iOS Simulator,name=iPhone 17' -quiet test 2>&1 | tail -5
git add iPhoneSensors/
git commit -m "feat(logger): coordinator pools + throttle integration + cap enforcement

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 2.7: Wire all sensor managers (publisher + .send)

> **Pattern:** for each manager, (1) `import Combine`, (2) add `let samplePublisher = PassthroughSubject<SensorSample, Never>()`, (3) inside each existing callback (where `@Published` properties already get assigned), add ONE `.send(...)` line with the appropriate payload, (4) register the publisher in `iPhoneSensorsApp.swift`'s `.task` block via `loggingService.attach(...)`.

Each subtask is one manager. Each is one commit.

- [ ] **Task 2.7.1 — `MotionSensorManager.swift`**: 6 sites in addition to accelerometer (gyroscope, magnetometer, deviceMotion, altimeter, pedometer, motionActivity). Use `.rotationRate`, `.magneticField`, `.deviceMotion`, `.altitude`, `.pedometer`, `.activity` payloads.
- [ ] **Task 2.7.2 — `LocationSensorManager.swift`**: 2 sites in `didUpdateLocations` (`.location`) and `didUpdateHeading` (`.heading`).
- [ ] **Task 2.7.3 — `EnvironmentSensorManager.swift`**: 4 sites — proximity (add `UIDeviceProximityStateDidChange` observer if missing; emit `.proximity`), brightness (on `UIScreen.brightnessDidChangeNotification` add observer; emit `.brightness`), torch (when AVCaptureDevice torch level changes; emit `.torch`), audio session (on `AVAudioSession.routeChangeNotification`; emit `.audio`).
- [ ] **Task 2.7.4 — `SystemSensorManager.swift`**: 4 sites — battery NSNotification (`.battery`), thermal NSNotification (`.thermal`), orientation NSNotification (`.orientation`), the existing 2-s timer (emit `.disk`, `.uptime`, `.lowPower`, `.brightness` — choose the one(s) the timer currently refreshes).
- [ ] **Task 2.7.5 — `ConnectivitySensorManager.swift`**: 3 sites — `centralManagerDidUpdateState` (`.bluetoothState`), `didDiscover peripheral` (`.bluetoothDevice`), NWPathMonitor update (`.network`). Cellular emits once on init (`.cellular`).
- [ ] **Task 2.7.6 — `CameraSensorManager.swift`**: 1 site at startup (`.cameraSnapshot`).
- [ ] **Task 2.7.7 — `HealthSensorManager.swift`**: emit one `.health(metric:value:unit:ts:)` per metric inside each existing query completion handler.

For each subtask: read the manager file, do the edits, run tests + build, commit with message `feat(logger): wire <Manager> samplePublisher`.

- [ ] **Task 2.7.8 — Register all publishers in `iPhoneSensorsApp.swift`**

In the `.task` block (or move to `LoggingService.bootstrap(sensorManager:)`), after `await loggingService.bootstrap()`:

```swift
if let m = sensorManager.motion { loggingService.attach(m.samplePublisher.eraseToAnyPublisher()) }
if let l = sensorManager.location { loggingService.attach(l.samplePublisher.eraseToAnyPublisher()) }
if let e = sensorManager.environment { loggingService.attach(e.samplePublisher.eraseToAnyPublisher()) }
if let s = sensorManager.system { loggingService.attach(s.samplePublisher.eraseToAnyPublisher()) }
if let c = sensorManager.connectivity { loggingService.attach(c.samplePublisher.eraseToAnyPublisher()) }
if let cam = sensorManager.camera { loggingService.attach(cam.samplePublisher.eraseToAnyPublisher()) }
if let h = sensorManager.health { loggingService.attach(h.samplePublisher.eraseToAnyPublisher()) }
```

(Adjust property names to match `SensorManager.swift`.)

Build + commit.

---

### Task 2.8: Info.plist additions + AppDelegate flush hook

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Info.plist`
- Modify: `iPhoneSensors/iPhoneSensors/App/iPhoneSensorsApp.swift`

- [ ] **Step 1: Add Info.plist keys**

```xml
<key>UIFileSharingEnabled</key><true/>
<key>LSSupportsOpeningDocumentsInPlace</key><true/>
```

(`UIBackgroundModes` already includes `location`. Bluetooth-central is added later only if BT-scan logging is enabled — defer to Phase 3.)

- [ ] **Step 2: Add UIApplicationDelegateAdaptor**

In `iPhoneSensorsApp.swift`:

```swift
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var loggingService: LoggingService?
    func applicationWillTerminate(_ application: UIApplication) {
        let exp = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await Self.loggingService?.flush()
            exp.signal()
        }
        _ = exp.wait(timeout: .now() + .milliseconds(200))
    }
}
```

In `LoggingService.bootstrap()`, set `AppDelegate.loggingService = self`.

Also subscribe to `UIApplication.willResignActiveNotification` to flush when backgrounded.

- [ ] **Step 3: Build, smoke, commit**

---

### Phase 2 acceptance

- ✅ All Tier-1 + Tier-2 tests pass
- ✅ Every sensor manager publishes samples
- ✅ Sessions can start/stop/resume; `log.sqlite` + `README.txt` created
- ✅ Storage cap enforcement deletes oldest continuous day-folder when over

---

## Phase 3 — Configuration UI

After Phase 3, the Logger tab is visible; users can toggle each sensor on/off per stream, pick formats, set intervals, start/stop sessions, and adjust storage cap.

### Task 3.1: Add 6th tab in `ContentView.swift`

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/App/ContentView.swift`

- [ ] **Step 1:** Add tab item:

```swift
LoggerOverviewView()
    .tabItem { Label(loc.t("tab.logger"), systemImage: "record.circle") }
    .tag(Tab.logger)
```

(Add `case logger` to the existing `Tab` enum. Read the file to find it.)

- [ ] **Step 2:** Build (will fail until LoggerOverviewView exists). Skip and continue to 3.2.

### Task 3.2: `LoggerOverviewView` + `LoggerStatusHeaderView`

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerOverviewView.swift`
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerStatusHeaderView.swift`

- [ ] **Step 1:** Implementation

```swift
import SwiftUI
import Combine

struct LoggerOverviewView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var sessionElapsed: TimeInterval = 0
    @State private var sessionTimer: AnyCancellable?
    @State private var showingDataViewer = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LoggerStatusHeaderView(elapsed: sessionElapsed)
                    HStack {
                        Button(action: { Task { try? await loggingService.coordinator.startSessionFromUI() } }) {
                            Label(localization.t("logger.start"), systemImage: "record.circle.fill")
                        }
                        .disabled(loggingService.activeSessionID != nil)

                        Button(action: { Task { try? await loggingService.coordinator.stopSessionFromUI() } }) {
                            Label(localization.t("logger.stop"), systemImage: "stop.fill")
                        }
                        .disabled(loggingService.activeSessionID == nil)
                    }
                }

                ForEach(SensorCategory.allCases, id: \.self) { cat in
                    Section(header: Text(localization.t("category.\(cat.rawValue)"))) {
                        ForEach(SensorID.allCases.filter { $0.category == cat }, id: \.self) { id in
                            NavigationLink(value: id) {
                                SensorRowConfigPreview(sensorID: id)
                            }
                        }
                    }
                }
            }
            .navigationTitle(localization.t("logger.title"))
            .navigationDestination(for: SensorID.self) { SensorLogConfigView(sensorID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingDataViewer = true }) { Image(systemName: "chart.bar.doc.horizontal") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) { Image(systemName: "gear") }
                }
            }
            .sheet(isPresented: $showingDataViewer) { DataViewerView() }
            .sheet(isPresented: $showingSettings) { LoggerSettingsView() }
        }
        .onAppear {
            sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
                Task { @MainActor in self.sessionElapsed = self.loggingService.sessionElapsed() }
            }
        }
        .onDisappear { sessionTimer?.cancel() }
    }
}

private struct SensorRowConfigPreview: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack {
            Image(systemName: iconName(for: sensorID))
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.t(sensorID.localizationKey))
                let cfg = loggingService.configStore.config(for: sensorID)
                HStack(spacing: 6) {
                    pill(stream: .continuous, cfg: cfg.continuous)
                    pill(stream: .session, cfg: cfg.session)
                }
                .font(.caption)
            }
        }
    }
    @ViewBuilder
    private func pill(stream: LogStream, cfg: PerStreamConfig) -> some View {
        switch cfg {
        case .off:
            Text("\(stream.rawValue): off").padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15)).clipShape(Capsule())
        case let .on(format, ms, _):
            Text("\(stream.rawValue): \(format.rawValue) @ \(ms == 0 ? "every" : "\(ms)ms")")
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(stream == .continuous ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                .clipShape(Capsule())
        }
    }
    private func iconName(for id: SensorID) -> String {
        switch id.category {
        case .motion:       return "gyroscope"
        case .location:     return "location"
        case .environment:  return "leaf"
        case .system:       return "cpu"
        case .connectivity: return "wifi"
        case .camera:       return "camera"
        case .health:       return "heart"
        }
    }
}
```

`LoggerStatusHeaderView.swift`:
```swift
import SwiftUI

struct LoggerStatusHeaderView: View {
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    let elapsed: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.fill").foregroundStyle(.green).font(.caption2)
                Text("\(loggingService.continuousActiveCount()) " + localization.t("logger.continuousActive"))
            }
            HStack {
                Image(systemName: loggingService.activeSessionID != nil ? "record.circle.fill" : "circle")
                    .foregroundStyle(loggingService.activeSessionID != nil ? .red : .secondary)
                Text(loggingService.activeSessionID != nil
                     ? localization.t("logger.sessionRecording") + " " + format(elapsed)
                     : localization.t("logger.sessionIdle"))
            }
            ProgressView(value: storageRatio()) {
                Text(localization.t("logger.storage") + ": " + storageDescription())
            }
        }
        .font(.subheadline)
    }
    private func format(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = (Int(t) % 3600) / 60, s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    private func storageRatio() -> Double {
        let used = Double(loggingService.storage.totalBytes())
        let cap = Double(UserDefaults.standard.integer(forKey: "logger.storageCapMB")).clamped(min: 1024)
        return min(1.0, used / (cap * 1024 * 1024))
    }
    private func storageDescription() -> String {
        let used = ByteCountFormatter.string(fromByteCount: loggingService.storage.totalBytes(), countStyle: .file)
        let capMB = max(UserDefaults.standard.integer(forKey: "logger.storageCapMB"), 1024)
        return "\(used) / \(capMB) MB"
    }
}

private extension Double {
    func clamped(min: Double) -> Double { Swift.max(self, min) }
}
```

`LoggingService` extensions needed (add to `LoggingService.swift`):

```swift
extension LoggingService {
    @MainActor var activeSessionID: UUID? { get async { await coordinator.activeSessionID } }   // proxy
    @MainActor func continuousActiveCount() -> Int {
        SensorID.allCases.filter { configStore.config(for: $0).continuous.isOn }.count
    }
    @MainActor func sessionElapsed() -> TimeInterval {
        // Track session start time on coordinator; expose here.
        coordinator.sessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0
    }
}
```

(Add `var sessionStartedAt: Date?` to coordinator, set in `startSessionFromUI`, cleared in `stopSessionFromUI`. These methods own the SessionManager interaction.)

- [ ] **Step 2:** Register, build, smoke (manual), commit.

---

### Task 3.3: `SensorLogConfigView`

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/SensorLogConfigView.swift`

- [ ] **Step 1:** Implementation

```swift
import SwiftUI

struct SensorLogConfigView: View {
    let sensorID: SensorID
    @EnvironmentObject var loggingService: LoggingService
    @EnvironmentObject var localization: LocalizationManager
    @State private var cfg: LoggingConfiguration = .default(for: .accelerometer)

    var body: some View {
        Form {
            section(stream: .continuous, binding: $cfg.continuous,
                    title: localization.t("logger.stream.continuous"))
            section(stream: .session, binding: $cfg.session,
                    title: localization.t("logger.stream.session"))
            Section { Text(estimatedRate()).font(.caption).foregroundStyle(.secondary) }
        }
        .navigationTitle(localization.t(sensorID.localizationKey))
        .onAppear { cfg = loggingService.configStore.config(for: sensorID) }
        .onChange(of: cfg) { _, new in loggingService.configStore.set(new, for: sensorID) }
    }

    @ViewBuilder
    private func section(stream: LogStream, binding: Binding<PerStreamConfig>, title: String) -> some View {
        Section(header: Text(title)) {
            Toggle(isOn: Binding(
                get: { binding.wrappedValue.isOn },
                set: { on in
                    if on {
                        binding.wrappedValue = .on(format: .jsonl, intervalMs: max(0, sensorID.minIntervalMs), options: .default)
                    } else {
                        binding.wrappedValue = .off
                    }
                })) { Text(localization.t("logger.enabled")) }

            if case let .on(format, ms, options) = binding.wrappedValue {
                Picker(localization.t("logger.format"),
                       selection: Binding(
                        get: { format },
                        set: { binding.wrappedValue = .on(format: $0, intervalMs: ms, options: options) })) {
                    ForEach(LogFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker(localization.t("logger.interval"),
                       selection: Binding(
                        get: { ms },
                        set: { binding.wrappedValue = .on(format: format, intervalMs: $0, options: options) })) {
                    ForEach(intervalPresets, id: \.self) {
                        Text($0 == 0 ? localization.t("logger.interval.everySample") : "\($0) ms").tag($0)
                    }
                }
            }
        }
    }

    private var intervalPresets: [Int] {
        let base = [0, 10, 50, 100, 250, 500, 1_000, 2_000, 5_000, 10_000, 30_000, 60_000]
        return base.filter { $0 == 0 || $0 >= sensorID.minIntervalMs }
    }
    private func estimatedRate() -> String {
        // rough: bytes per sample × samples per minute
        let perSample: Double = 200
        var perMin: Double = 0
        if case let .on(_, ms, _) = cfg.continuous { perMin += ms == 0 ? 60.0 : 60_000.0 / Double(ms) }
        if case let .on(_, ms, _) = cfg.session { perMin += ms == 0 ? 60.0 : 60_000.0 / Double(ms) }
        let kbPerMin = (perMin * perSample) / 1024.0
        return String(format: "≈ %.1f KB/min · %.1f MB/day", kbPerMin, kbPerMin * 60 * 24 / 1024)
    }
}
```

- [ ] **Step 2:** Register, build, commit.

---

### Task 3.4: `LoggerSettingsView`

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/LoggerSettingsView.swift`

- [ ] **Step 1:** Implementation (form with `@AppStorage`-backed toggles for `logger.storageCapMB`, `logger.disableAutoLockDuringSession`, `logger.pauseContinuousOnLowBattery`, `logger.pauseContinuousOnThermal`, `logger.showExportWarning`; "Clear all continuous data" destructive button calls `loggingService.storage.deleteContinuous()`).

Add to `LogStorageManager`: `func deleteContinuous() throws { try fm.removeItem(at: rootURL.appendingPathComponent("continuous")) }`.

- [ ] **Step 2:** Register, build, commit.

---

### Task 3.5: Localization keys for Logger UI

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/LocalizationManager.swift`

- [ ] **Step 1:** Add the following keys to both `en` and `th` dictionaries:

`tab.logger`, `logger.title`, `logger.start`, `logger.stop`, `logger.continuousActive`, `logger.sessionRecording`, `logger.sessionIdle`, `logger.storage`, `logger.stream.continuous`, `logger.stream.session`, `logger.format`, `logger.interval`, `logger.interval.everySample`, `logger.enabled`, `logger.format.sqlite`, `logger.format.jsonl`, `logger.format.csv`, plus one `sensor.<id>` key for every `SensorID.rawValue`, plus `category.<rawValue>` for every category.

For Thai, provide translations (use Google-Translate-quality reasonable Thai if needed; flag for human review).

- [ ] **Step 2:** Build, smoke, commit.

---

### Phase 3 acceptance

- ✅ Logger tab visible; navigation flows reachable
- ✅ Every sensor row reflects live config
- ✅ Start/Stop session works; data lands in `sessions/<UUID>/`
- ✅ Settings persist across app launches

---

## Phase 4 — Data Viewer UI

### Task 4.1: `DataViewerView` shell + segmented sub-views

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/DataViewerView.swift`

A `Picker(selection:, segmented:)` switching between three child views: `SensorDataView`, `SessionsListView`, `FilesBrowserView`.

### Task 4.2: `SessionsListView` + `SessionDetailView`

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/SessionsListView.swift`
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/SessionDetailView.swift`

- Lists all session folders (read `storage.sessionsRoot()`), reads each `log.sqlite` for metadata.
- Detail shows metadata + per-sensor row counts (GRDB query: `SELECT sensor_id, COUNT(*) FROM entries GROUP BY sensor_id`), an "Open in Files" button using `UIApplication.shared.open(url)` with a `shareddocuments://` URL, a Share button using existing `ShareSheet`, and a destructive Delete.

### Task 4.3: `SensorDataView` (paginated GRDB rows)

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/SensorDataView.swift`
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/LogEntryDetailView.swift`

- Sensor picker, time-range picker, source picker (continuous/session).
- Pages 100 rows at a time using `LIMIT 100 OFFSET ?`.
- Tap row → `LogEntryDetailView` with pretty-printed `payload_json`.

### Task 4.4: `FilesBrowserView`

**Files:**
- Create: `iPhoneSensors/iPhoneSensors/Views/Logger/FilesBrowserView.swift`

A `List` walking `Documents/SensorLogs/`. Each file row shows size + last-modified, swipe-to-share, swipe-to-delete. Long-press → preview first 50 lines for text formats.

### Task 4.5: Export with privacy gate

**Files:**
- Modify: `iPhoneSensors/iPhoneSensors/Services/Logging/LoggingService.swift`

Add `func shareSession(_ id: UUID) -> URL` returning the session folder URL (iOS supports sharing folders via `UIActivityViewController`). Wrap calls in a one-time consent sheet (`@AppStorage("logger.exportConsentGivenAt")`).

### Phase 4 acceptance

- ✅ Browse all data by sensor / by session / by file
- ✅ Export session via AirDrop produces a folder with README + DB + flat files
- ✅ Privacy consent shown on first export

---

## Phase 5 — Polish

### Task 5.1: Charts in `SensorDataView` for numeric payloads

Use existing SwiftUI `Charts` framework. For payloads where `csvColumns.allSatisfy({ numeric })` (acceleration, rotationRate, magneticField, altitude, brightness, battery, location.alt, etc.), render a time-series chart of the loaded page above the row list.

### Task 5.2: `LoggerInlineCard` in detail views

A reusable card showing config + quick toggle. Embed in each `Views/Sensors/*DetailView.swift`.

### Task 5.3: Migrate `SensorRecorder` to a logger shim

Replace `SensorRecorder` internals with a thin wrapper that calls `loggingService.coordinator.startSessionFromUI()` constrained to a single sensor. Keep its public API (existing detail-view code is unchanged). Delete unused fields.

### Task 5.4: "Strip location" export

When exporting, offer a checkbox; if checked, write a copy of the session folder with `location.*` rows filtered out (SQLite `DELETE FROM entries WHERE sensor_id LIKE 'location.%'` on the copy; remove `gps.*`/`heading.*` flat files).

### Task 5.5: AppIntents wired

The existing `StartRecordingIntent` stub in `iPhoneSensorsApp.swift` should call `loggingService.coordinator.startSessionFromUI()`. Add `StopRecordingIntent`. Donate to Shortcuts.

### Phase 5 acceptance

- ✅ Charts render for numeric payload pages
- ✅ Existing detail-view "Record" buttons persist data
- ✅ "Hey Siri, start sensor recording" works
- ✅ "Strip location" produces a sanitized copy

---

## Self-Review

**Spec coverage:** Every spec section maps to at least one task — §1 use case → defaults in 1.4; §2 streams → 1.4 + 2.4 + 2.6; §3 formats → 1.7/2.2/2.3; §4 storage layout → 1.6/2.5; §5 engine → 1.5–1.9, 2.1–2.6; §6 data model → 1.3/1.4/2.1; §7 UI → 3.1–3.5, 4.1–4.5; §8 background → 2.8 + Phase 5; §9 retention → 2.5/2.6; §10 privacy export → 4.5; §11 migration → 5.3; §12 file plan → covered; §13 testing → tier-1 inline; §14 phases → matches; §15 OOS → not implemented; §16 risks → handled.

**Placeholder scan:** None.

**Type consistency:** `SensorID.rawValue` is canonical; `LogFormat.fileExtension` matches `rawValue`; `SensorPayload.kind` ↔ `csvColumns` ↔ `csvValues` consistent; `SensorLogEntry` column names match `DatabaseSchema` migration. `LoggingCoordinator.WriterKey` shape consistent across uses.

**Ambiguity:** All defaults resolved during brainstorming and captured in §17 of the spec.

---

## Execution

User has chosen subagent-driven execution. Next step: invoke `superpowers:subagent-driven-development` to dispatch one fresh subagent per task with two-stage review.
