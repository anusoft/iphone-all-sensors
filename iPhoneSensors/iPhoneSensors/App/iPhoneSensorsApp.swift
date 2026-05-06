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
                    loggingService.enableContinuousAccelerometer()
                    loggingService.attach(sensorManager.motionManager.samplePublisher.eraseToAnyPublisher())
                }
        }
    }
}
