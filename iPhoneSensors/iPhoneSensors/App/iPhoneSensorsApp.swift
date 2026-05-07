import SwiftUI

@main
struct iPhoneSensorsApp: App {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var locManager = LocalizationManager()
    @StateObject private var loggingService = LoggingService()

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
                .task {
                    await loggingService.bootstrap()
                    // Register publishers for every sensor manager. Per-sensor logging is
                    // now driven by LoggingConfiguration.default(for:) (via LoggingConfigStore
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
