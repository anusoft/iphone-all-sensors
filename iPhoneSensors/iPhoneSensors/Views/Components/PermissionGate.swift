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
    @EnvironmentObject var locManager: LocalizationManager
    @State private var isAuthorized = false
    @State private var isChecking = true
    @State private var showDenied = false

    var body: some View {
        Group {
            if isChecking {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(locManager.t("permission.checking"))
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
    @EnvironmentObject var locManager: LocalizationManager

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
                    Label(locManager.t("permission.denied.openSettings"), systemImage: "gear")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onRetry) {
                    Label(locManager.t("permission.denied.checkAgain"), systemImage: "arrow.clockwise")
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
        case .location: return locManager.t("permission.denied.location.title")
        case .health: return locManager.t("permission.denied.health.title")
        case .camera: return locManager.t("permission.denied.camera.title")
        case .microphone: return locManager.t("permission.denied.microphone.title")
        case .motion: return locManager.t("permission.denied.motion.title")
        case .bluetooth: return locManager.t("permission.denied.bluetooth.title")
        }
    }

    private var message: String {
        switch permission {
        case .location:
            return locManager.t("permission.denied.location.message")
        case .health:
            return locManager.t("permission.denied.health.message")
        case .camera:
            return locManager.t("permission.denied.camera.message")
        case .microphone:
            return locManager.t("permission.denied.microphone.message")
        case .motion:
            return locManager.t("permission.denied.motion.message")
        case .bluetooth:
            return locManager.t("permission.denied.bluetooth.message")
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
