import SwiftUI
import CoreLocation
import HealthKit
import AVFoundation

enum PermissionType {
    case location
    case health
    case camera
    case microphone
    case motion
    case bluetooth
}

struct PermissionGate<Content: View>: View {
    let permission: PermissionType
    let content: () -> Content
    @State private var isAuthorized = false
    @State private var isChecking = true
    @State private var showDenied = false

    var body: some View {
        Group {
            if isChecking {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Checking permissions...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isAuthorized {
                content()
            } else {
                PermissionDeniedView(
                    permission: permission,
                    onRetry: { checkPermission() },
                    onOpenSettings: { openSettings() }
                )
            }
        }
        .onAppear {
            checkPermission()
        }
    }

    private func checkPermission() {
        isChecking = true
        Task {
            switch permission {
            case .location:
                let status = CLLocationManager().authorizationStatus
                isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
                if !isAuthorized && status == .notDetermined {
                    isChecking = false
                    return
                }
            case .health:
                isAuthorized = HKHealthStore.isHealthDataAvailable()
                if isAuthorized {
                    let status = HKHealthStore().authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
                    isAuthorized = status == .sharingAuthorized
                }
            case .camera:
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                isAuthorized = status == .authorized
                if status == .notDetermined {
                    isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
                }
            case .microphone:
                let status = AVCaptureDevice.authorizationStatus(for: .audio)
                isAuthorized = status == .authorized
                if status == .notDetermined {
                    isAuthorized = await AVCaptureDevice.requestAccess(for: .audio)
                }
            case .motion:
                isAuthorized = true
            case .bluetooth:
                isAuthorized = true
            }
            isChecking = false
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PermissionDeniedView: View {
    let permission: PermissionType
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onRetry) {
                    Label("Check Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var icon: String {
        switch permission {
        case .location: return "location.slash"
        case .health: return "heart.slash"
        case .camera: return "camera.slash"
        case .microphone: return "mic.slash"
        case .motion: return "gyroscope"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        }
    }

    private var title: String {
        switch permission {
        case .location: return "Location Access Required"
        case .health: return "Health Access Required"
        case .camera: return "Camera Access Required"
        case .microphone: return "Microphone Access Required"
        case .motion: return "Motion Access Required"
        case .bluetooth: return "Bluetooth Access Required"
        }
    }

    private var message: String {
        switch permission {
        case .location:
            return "This app needs location access to display GPS coordinates, altitude, and compass heading. Please enable Location access in Settings."
        case .health:
            return "This app needs Health access to display heart rate, steps, and other health metrics. Please enable Health access in Settings."
        case .camera:
            return "This app needs camera access to display camera capabilities. Please enable Camera access in Settings."
        case .microphone:
            return "This app needs microphone access to display audio information. Please enable Microphone access in Settings."
        case .motion:
            return "This app needs motion access to display accelerometer and gyroscope data."
        case .bluetooth:
            return "This app needs Bluetooth access to discover nearby devices."
        }
    }

    private var color: Color {
        switch permission {
        case .location: return .green
        case .health: return .red
        case .camera: return .yellow
        case .microphone: return .orange
        case .motion: return .blue
        case .bluetooth: return .blue
        }
    }
}
