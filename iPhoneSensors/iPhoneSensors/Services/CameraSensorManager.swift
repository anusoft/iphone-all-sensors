import Foundation
import AVFoundation
import Combine

@MainActor
class CameraSensorManager: ObservableObject {
    @Published var isFrontCameraAvailable = false
    @Published var isRearCameraAvailable = false
    @Published var isFlashAvailable = false
    @Published var isTorchAvailable = false
    @Published var torchLevel: Float = 0
    @Published var maxZoomFactor: CGFloat = 1
    @Published var cameraAccessGranted = false
    @Published var microphoneAccessGranted = false

    @Published var audioSessionCategory: String = ""
    @Published var audioSampleRate: Double = 0
    @Published var audioInputChannels: Int = 0
    @Published var isAudioInputAvailable = false

    /// Stream of sensor samples for the logging pipeline.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    func startUpdates() {
        print("[Camera] ── Starting Camera Sensors ──")

        isFrontCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
        isRearCameraAvailable = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil

        print("[Camera] Front camera: \(isFrontCameraAvailable)")
        print("[Camera] Rear camera: \(isRearCameraAvailable)")

        if let backCamera = AVCaptureDevice.default(for: .video) {
            isFlashAvailable = backCamera.hasFlash
            isTorchAvailable = backCamera.hasTorch
            torchLevel = backCamera.torchLevel
            maxZoomFactor = backCamera.activeFormat.videoMaxZoomFactor
            print("[Camera] Flash: \(isFlashAvailable), Torch: \(isTorchAvailable)")
            print("[Camera] Max zoom: \(maxZoomFactor)x")
        } else {
            print("[Camera] ⚠ No back camera device found")
        }

        checkCameraAccess()
        checkMicrophoneAccess()
        updateAudioInfo()

        let hasUltraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil
        let hasTelephoto = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil
        let hasLiDAR = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
        samplePublisher.send(SensorSample(
            sensorID: .camera,
            payload: .cameraSnapshot(CameraPayload(
                hasFront: isFrontCameraAvailable,
                hasBack: isRearCameraAvailable,
                hasUltraWide: hasUltraWide,
                hasTelephoto: hasTelephoto,
                hasLiDAR: hasLiDAR,
                zoom: Double(maxZoomFactor)))))

        print("[Camera] ✅ Camera sensors initialization complete")
    }

    func stopUpdates() {
        print("[Camera] ■ Stopping camera sensors")
    }

    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAccessGranted = true
            print("[Camera] ✓ Camera access: Authorized")
        case .notDetermined:
            print("[Camera] ? Camera access: Not Determined - requesting...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.cameraAccessGranted = granted
                    print("[Camera] \(granted ? "✓" : "❌") Camera access: \(granted ? "Granted" : "Denied")")
                }
            }
        case .denied:
            cameraAccessGranted = false
            print("[Camera] ❌ Camera access: Denied")
        case .restricted:
            cameraAccessGranted = false
            print("[Camera] ⚠ Camera access: Restricted")
        @unknown default:
            cameraAccessGranted = false
            print("[Camera] ⚠ Camera access: Unknown status")
        }
    }

    func checkMicrophoneAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneAccessGranted = true
            print("[Camera] ✓ Microphone access: Authorized")
        case .notDetermined:
            print("[Camera] ? Microphone access: Not Determined - requesting...")
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    self?.microphoneAccessGranted = granted
                    print("[Camera] \(granted ? "✓" : "❌") Microphone access: \(granted ? "Granted" : "Denied")")
                }
            }
        case .denied:
            microphoneAccessGranted = false
            print("[Camera] ❌ Microphone access: Denied")
        case .restricted:
            microphoneAccessGranted = false
            print("[Camera] ⚠ Microphone access: Restricted")
        @unknown default:
            microphoneAccessGranted = false
        }
    }

    private func updateAudioInfo() {
        let session = AVAudioSession.sharedInstance()
        audioSessionCategory = session.category.rawValue
        isAudioInputAvailable = session.isInputAvailable
        audioSampleRate = session.sampleRate
        audioInputChannels = session.inputNumberOfChannels
        print("[Camera] Audio category: \(audioSessionCategory)")
        print("[Camera] Sample rate: \(audioSampleRate) Hz")
        print("[Camera] Input channels: \(audioInputChannels)")
    }

    func setTorch(level: Float) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("[Camera] ❌ Cannot set torch")
            return
        }
        try? device.lockForConfiguration()
        if level > 0 {
            try? device.setTorchModeOn(level: level)
        } else {
            device.torchMode = .off
        }
        device.unlockForConfiguration()
        torchLevel = level
        print("[Camera] 🔦 Torch: \(level)")
    }
}
