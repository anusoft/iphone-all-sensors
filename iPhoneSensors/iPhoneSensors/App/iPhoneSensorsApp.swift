import SwiftUI
import UIKit

@main
struct iPhoneSensorsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var locManager = LocalizationManager()
    @StateObject private var loggingService = LoggingService()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var diagnosticManager = DiagnosticManager()
    @StateObject private var recorder = SensorRecorder()
    @StateObject private var screenshotRouter = ScreenshotRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sensorManager)
                .environmentObject(sensorManager.motionManager)
                .environmentObject(sensorManager.locationManager)
                .environmentObject(sensorManager.environmentManager)
                .environmentObject(sensorManager.systemManager)
                .environmentObject(sensorManager.healthManager)
                .environmentObject(sensorManager.connectivityManager)
                .environmentObject(sensorManager.cameraManager)
                .environmentObject(locManager)
                .environmentObject(loggingService)
                .environmentObject(themeManager)
                .environmentObject(diagnosticManager)
                .environmentObject(recorder)
                .environmentObject(screenshotRouter)
                .preferredColorScheme(themeManager.colorScheme)
                .onOpenURL { url in
                    // Deep link: allsensors://<namespace>.<app>/screenshots/<page-name>
                    // Routes into ScreenshotHeroView for App Store capture.
                    screenshotRouter.handle(url)
                }
                .task {
                    // Make the live sensor manager reachable from App Intents /
                    // the home-screen widget bridge while the app is running.
                    AppDelegate.sensorManager = sensorManager
                    await loggingService.bootstrap()
                    // Register publishers for every sensor manager. Per-sensor logging is
                    // driven by LoggingConfiguration.default(for:) (via LoggingConfigStore
                    // falling back to defaults), so no per-sensor smoke helper is needed.
                    loggingService.attach(sensorManager.motionManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.locationManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.environmentManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.systemManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.connectivityManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.cameraManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attach(sensorManager.healthManager.samplePublisher.eraseToAnyPublisher())
                    loggingService.attachThrottleSource(sensorManager)
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var loggingService: LoggingService?

    /// Weak handle to the live, foreground `SensorManager`. Set while the app is
    /// running so App Intents / the widget bridge can read real readings; `nil`
    /// when the app isn't running (callers then report "open the app").
    static weak var sensorManager: SensorManager?

    // NOTE: We intentionally do NOT flush on `applicationWillTerminate`. The
    // earlier implementation blocked the main thread on a DispatchSemaphore while
    // awaiting an @MainActor flush — a guaranteed self-deadlock (the flush task
    // can't run while the main thread is parked), so it timed out after 200 ms
    // and never actually flushed. Persistence is handled by the
    // `willResignActiveNotification` flush registered in `LoggingService.bootstrap()`,
    // which reliably fires before suspension/termination.
}
