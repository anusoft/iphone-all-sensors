import SwiftUI

@main
struct iPhoneSensorsApp: App {
    @StateObject private var sensorManager = SensorManager()
    @StateObject private var locManager = LocalizationManager()

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
        }
    }
}
