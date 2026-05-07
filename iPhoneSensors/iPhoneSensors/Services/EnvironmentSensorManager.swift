import Foundation
import CoreMotion
import AVFoundation
import UIKit
import Combine

@MainActor
class EnvironmentSensorManager: ObservableObject {
    private let altimeter = CMAltimeter()
    private var isStarted = false

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

    /// Stream of sensor samples for the logging pipeline.
    /// Note: altimeter samples are emitted by `MotionSensorManager` (single source of truth).
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    private var observersRegistered = false

    func startUpdates() {
        guard !isStarted else {
            print("[Environment] ⚠ Already started")
            return
        }
        isStarted = true
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
        samplePublisher.send(SensorSample(
            sensorID: .brightness,
            payload: .brightness(level: Double(UIScreen.main.brightness))))

        UIDevice.current.isProximityMonitoringEnabled = true
        isProximityMonitoringEnabled = UIDevice.current.isProximityMonitoringEnabled
        proximityState = UIDevice.current.proximityState
        print("[Environment] Proximity monitoring enabled: \(isProximityMonitoringEnabled)")
        samplePublisher.send(SensorSample(
            sensorID: .proximity,
            payload: .proximity(near: UIDevice.current.proximityState)))

        if let device = AVCaptureDevice.default(for: .video) {
            isTorchAvailable = device.hasTorch
            torchLevel = device.torchLevel
            print("[Environment] Torch available: \(isTorchAvailable), level: \(torchLevel)")
        } else {
            print("[Environment] ⚠ No video capture device for torch")
        }

        updateAudioInfo()
        registerObservers()
        print("[Environment] ✅ Environment sensors initialization complete")
    }

    private func registerObservers() {
        guard !observersRegistered else { return }
        observersRegistered = true
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleProximityChange),
                       name: UIDevice.proximityStateDidChangeNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(handleBrightnessChange),
                       name: UIScreen.brightnessDidChangeNotification,
                       object: nil)
        nc.addObserver(self,
                       selector: #selector(handleAudioRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil)
        print("[Environment] ✓ Registered proximity/brightness/audio observers")
    }

    @objc private nonisolated func handleProximityChange(_ note: Notification) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let near = UIDevice.current.proximityState
            self.proximityState = near
            self.samplePublisher.send(SensorSample(
                sensorID: .proximity,
                payload: .proximity(near: near)))
        }
    }

    @objc private nonisolated func handleBrightnessChange(_ note: Notification) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let level = Double(UIScreen.main.brightness)
            self.screenBrightness = level
            self.samplePublisher.send(SensorSample(
                sensorID: .brightness,
                payload: .brightness(level: level)))
        }
    }

    @objc private nonisolated func handleAudioRouteChange(_ note: Notification) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let session = AVAudioSession.sharedInstance()
            self.audioSessionCategory = session.category.rawValue
            self.audioVolume = session.outputVolume
            self.audioOutputDevices = session.currentRoute.outputs.map { $0.portName }
            self.samplePublisher.send(SensorSample(
                sensorID: .audio,
                payload: .audio(AudioPayload(
                    category: session.category.rawValue,
                    sampleRate: session.sampleRate,
                    channels: Int(session.outputNumberOfChannels),
                    volume: Double(session.outputVolume),
                    inputs: session.currentRoute.inputs.map { $0.portName },
                    outputs: session.currentRoute.outputs.map { $0.portName }))))
        }
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        print("[Environment] ■ Stopping environment sensors")
        altimeter.stopRelativeAltitudeUpdates()
        UIDevice.current.isProximityMonitoringEnabled = false
        if observersRegistered {
            NotificationCenter.default.removeObserver(self)
            observersRegistered = false
        }
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
        samplePublisher.send(SensorSample(
            sensorID: .torch,
            payload: .torch(level: Double(device.torchLevel))))
        print("[Environment] 🔦 Torch set to \(level)")
    }

    func setScreenBrightness(_ brightness: Double) {
        UIScreen.main.brightness = brightness
        screenBrightness = brightness
        samplePublisher.send(SensorSample(
            sensorID: .brightness,
            payload: .brightness(level: brightness)))
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
            samplePublisher.send(SensorSample(
                sensorID: .audio,
                payload: .audio(AudioPayload(
                    category: session.category.rawValue,
                    sampleRate: session.sampleRate,
                    channels: Int(session.outputNumberOfChannels),
                    volume: Double(session.outputVolume),
                    inputs: session.currentRoute.inputs.map { $0.portName },
                    outputs: session.currentRoute.outputs.map { $0.portName }))))
            print("[Environment] Audio category: \(audioSessionCategory)")
            print("[Environment] Audio volume: \(audioVolume)")
            print("[Environment] Audio inputs: \(audioInputDevices)")
            print("[Environment] Audio outputs: \(audioOutputDevices)")
        } catch {
            print("[Environment] ❌ Audio session error: \(error.localizedDescription)")
        }
    }
}
