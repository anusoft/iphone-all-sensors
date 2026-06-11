import Foundation
import os

/// Lightweight wrapper over `os.Logger` used in place of `print(...)` across the
/// app. Routes through the unified logging system (queryable in Console.app /
/// `log stream`) and is compiled out of release builds, so production runs stay
/// quiet and free of stdout spam. Replaces the ~180 ad-hoc `print` calls the
/// audit flagged in the sensor managers.
enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.1moby.allsensors"

    /// Shared category logger for general app/sensor diagnostics.
    static let general = Logger(subsystem: subsystem, category: "app")
}

/// Drop-in replacement for `print` that logs at debug level and is elided from
/// release builds. The existing call sites pass a single interpolated string,
/// e.g. `appLog("[Motion] started \(rate)")`, which maps cleanly here.
@inline(__always)
func appLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    let text = message()
    AppLog.general.debug("\(text, privacy: .public)")
    #endif
}
