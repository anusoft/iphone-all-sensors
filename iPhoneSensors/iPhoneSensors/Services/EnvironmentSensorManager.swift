import Foundation
import CoreMotion
import AVFoundation
import UIKit
import Combine

@MainActor
class EnvironmentSensorManager: ObservableObject {
    private let altimeter = CMAltimeter()

    @Published var relativeAltitude: Double = 0
    @Published var pressure: Double = 0
    @Published var isAltimeterAvailable = false

    @Published var screenBrightness: Double = 0
    @Published var isProximityMonitoringEnabled = false
    @Published var proximityState = false

    @Published var isTorchAvailable = false
    @Published var torchLevel: Float = 0

    @Published var audioInputDevices: [String] = []
    @Published var audioOutputDevices: [String] = []
    @Published var audioSessionCategory: String = ""
    @Published var isAudioSessionActive = false
    @Published var audioVolume: Float = 0

    func startUpdates() {
        print("[Environment] ── Starting Environment Sensors ──")

        if CMAltimeter.isRelativeAltitudeAvailable() {
            isAltimeterAvailable = true
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
                if let error = error {
                    print("[Environment] ❌ Altimeter error: \(error.localizedDescription)")
                    return
                }
                guard let data = data else { return }
                self?.relativeAltitude = data.relativeAltitude.doubleValue
                self?.pressure = data.pressure.doubleValue
            }
            print("[Environment] ✓ Altimeter started")
        } else {
            print("[Environment] ⚠ Altimeter not available")
        }

        screenBrightness = UIScreen.main.brightness
        print("[Environment] Screen brightness: \(screenBrightness)")

        UIDevice.current.isProximityMonitoringEnabled = true
        isProximityMonitoringEnabled = UIDevice.current.isProximityMonitoringEnabled
        proximityState = UIDevice.current.proximityState
        print("[Environment] Proximity monitoring enabled: \(isProximityMonitoringEnabled)")

        if let device = AVCaptureDevice.default(for: .video) {
            isTorchAvailable = device.hasTorch
            torchLevel = device.torchLevel
            print("[Environment] Torch available: \(isTorchAvailable), level: \(torchLevel)")
        } else {
            print("[Environment] ⚠ No video capture device for torch")
        }

        updateAudioInfo()
        print("[Environment] ✅ Environment sensors initialization complete")
    }

    func stopUpdates() {
        print("[Environment] ■ Stopping environment sensors")
        altimeter.stopRelativeAltitudeUpdates()
        UIDevice.current.isProximityMonitoringEnabled = false
    }

    func setTorchLevel(_ level: Float) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("[Environment] ❌ Cannot set torch - device not available")
            return
        }
        try? device.lockForConfiguration()
        device.torchMode = level > 0 ? .on : .off
        try? device.setTorchModeOn(level: level)
        device.unlockForConfiguration()
        torchLevel = level
        print("[Environment] 🔦 Torch set to \(level)")
    }

    func setScreenBrightness(_ brightness: Double) {
        UIScreen.main.brightness = brightness
        screenBrightness = brightness
        print("[Environment] ☀️ Brightness set to \(brightness)")
    }

    private func updateAudioInfo() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
            audioSessionCategory = session.category.rawValue
            isAudioSessionActive = session.isOtherAudioPlaying
            audioVolume = session.outputVolume
            audioInputDevices = session.availableInputs?.map { $0.portName } ?? []
            audioOutputDevices = session.currentRoute.outputs.map { $0.portName }
            print("[Environment] Audio category: \(audioSessionCategory)")
            print("[Environment] Audio volume: \(audioVolume)")
            print("[Environment] Audio inputs: \(audioInputDevices)")
            print("[Environment] Audio outputs: \(audioOutputDevices)")
        } catch {
            print("[Environment] ❌ Audio session error: \(error.localizedDescription)")
        }
    }
}
