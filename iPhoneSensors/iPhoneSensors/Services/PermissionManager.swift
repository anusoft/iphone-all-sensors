import Foundation
import CoreLocation
import CoreMotion
import HealthKit
import CoreBluetooth
import AVFoundation
import UIKit
import SwiftUI

@MainActor
class PermissionManager: ObservableObject {
    @Published var motionAuthorized = false
    @Published var locationAuthorized = false
    @Published var healthAuthorized = false
    @Published var bluetoothAuthorized = false
    @Published var cameraAuthorized = false
    @Published var microphoneAuthorized = false

    @Published var showPermissionAlert = false
    @Published var permissionAlertTitle = ""
    @Published var permissionAlertMessage = ""
    @Published var permissionAlertSettingsLink = false

    func checkMotionPermission() -> Bool {
        print("[Permission] Checking motion permission...")
        if CMMotionActivityManager.isActivityAvailable() {
            let manager = CMMotionActivityManager()
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false

            manager.startActivityUpdates(to: .main) { _ in
                granted = true
                manager.stopActivityUpdates()
                semaphore.signal()
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                manager.stopActivityUpdates()
                semaphore.signal()
            }

            semaphore.wait()
            motionAuthorized = granted
            print("[Permission] Motion: \(granted ? "✅" : "❌")")
            return granted
        }
        motionAuthorized = true
        return true
    }

    func checkLocationPermission() -> CLAuthorizationStatus {
        let status = CLLocationManager().authorizationStatus
        locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        print("[Permission] Location status: \(status.rawValue) (authorized: \(locationAuthorized))")
        return status
    }

    func requestLocationPermission() {
        print("[Permission] Requesting location permission...")
    }

    func checkHealthPermission() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[Permission] HealthKit not available")
            healthAuthorized = false
            return false
        }
        let status = HKHealthStore().authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
        healthAuthorized = status == .sharingAuthorized
        print("[Permission] Health status: \(status.rawValue) (authorized: \(healthAuthorized))")
        return healthAuthorized
    }

    func checkCameraPermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAuthorized = status == .authorized
        print("[Permission] Camera status: \(status.rawValue) (authorized: \(cameraAuthorized))")
        return cameraAuthorized
    }

    func checkMicrophonePermission() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneAuthorized = status == .authorized
        print("[Permission] Microphone status: \(status.rawValue) (authorized: \(microphoneAuthorized))")
        return microphoneAuthorized
    }

    func showSettingsAlert(title: String, message: String) {
        permissionAlertTitle = title
        permissionAlertMessage = message
        permissionAlertSettingsLink = true
        showPermissionAlert = true
        print("[Permission] ⚠ Showing alert: \(title)")
    }

    func openAppSettings() {
        print("[Permission] Opening app settings...")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
