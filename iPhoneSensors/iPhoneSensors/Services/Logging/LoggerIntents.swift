import AppIntents
import Foundation

/// Siri / Shortcuts entry point for starting a sensor logging session.
struct StartLoggerSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sensor Logging Session"
    static var description = IntentDescription("Begin a new sensor logging session.")

    @MainActor
    func perform() async throws -> some IntentResult {
        if let svc = AppDelegate.loggingService {
            await svc.startSessionFromUI(note: "Siri")
        }
        return .result()
    }
}

/// Siri / Shortcuts entry point for ending the active sensor logging session.
struct StopLoggerSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Sensor Logging Session"
    static var description = IntentDescription("End the current sensor logging session.")

    @MainActor
    func perform() async throws -> some IntentResult {
        if let svc = AppDelegate.loggingService {
            await svc.stopSessionFromUI()
        }
        return .result()
    }
}

struct LoggerAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartLoggerSessionIntent(),
            phrases: [
                "Start sensor recording in \(.applicationName)",
                "Start logging sensors in \(.applicationName)"
            ],
            shortTitle: "Start Recording",
            systemImageName: "record.circle"
        )

        AppShortcut(
            intent: StopLoggerSessionIntent(),
            phrases: [
                "Stop sensor recording in \(.applicationName)",
                "Stop logging sensors in \(.applicationName)"
            ],
            shortTitle: "Stop Recording",
            systemImageName: "stop.circle"
        )
    }
}
