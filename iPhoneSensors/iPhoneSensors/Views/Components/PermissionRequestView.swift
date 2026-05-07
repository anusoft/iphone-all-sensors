import SwiftUI
import CoreLocation
import AVFoundation
import CoreMotion
import CoreBluetooth

struct PermissionRequestView: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    @State private var currentStep = 0
    @State private var isProcessing = false

    @AppStorage("consentGivenAt") private var consentGivenAt: Double = 0
    @AppStorage("consentAccepted") private var consentAccepted = false

    private var steps: [PermissionStep] {
        [
            PermissionStep(
                title: locManager.t("consent.title"),
                subtitle: "Privacy",
                icon: "hand.raised.fill",
                color: .blue,
                description: locManager.t("consent.description"),
                buttonTitle: locManager.t("consent.acceptAll")
            ),
            PermissionStep(
                title: locManager.t("permission.welcome"),
                subtitle: "All Sensors",
                icon: "sensor.tag.radiowaves.forward",
                color: .blue,
                description: locManager.t("permission.welcome.desc"),
                buttonTitle: locManager.t("permission.getStarted")
            ),
            PermissionStep(
                title: locManager.t("permission.location"),
                subtitle: "GPS · Compass · Altitude",
                icon: "location.fill",
                color: .green,
                description: locManager.t("permission.location.desc"),
                buttonTitle: locManager.t("permission.allowLocation")
            ),
            PermissionStep(
                title: locManager.t("permission.motion"),
                subtitle: "Accelerometer · Gyroscope · Steps",
                icon: "figure.walk",
                color: .blue,
                description: locManager.t("permission.motion.desc"),
                buttonTitle: locManager.t("permission.allowMotion")
            ),
            PermissionStep(
                title: locManager.t("permission.camera"),
                subtitle: "Camera Info · Torch",
                icon: "camera.fill",
                color: .yellow,
                description: locManager.t("permission.camera.desc"),
                buttonTitle: locManager.t("permission.allowCamera")
            ),
            PermissionStep(
                title: locManager.t("permission.microphone"),
                subtitle: "Audio Input",
                icon: "mic.fill",
                color: .orange,
                description: locManager.t("permission.microphone.desc"),
                buttonTitle: locManager.t("permission.allowMicrophone")
            ),
            PermissionStep(
                title: locManager.t("permission.bluetooth"),
                subtitle: "Nearby Devices",
                icon: "antenna.radiowaves.left.and.right",
                color: .cyan,
                description: locManager.t("permission.bluetooth.desc"),
                buttonTitle: locManager.t("permission.allowBluetooth")
            ),
            PermissionStep(
                title: locManager.t("tab.health"),
                subtitle: "HealthKit",
                icon: "heart.text.square",
                color: .red,
                description: locManager.t("health.disclaimer.text"),
                buttonTitle: locManager.t("health.disclaimer.agree")
            ),
            PermissionStep(
                title: locManager.t("permission.allSet"),
                subtitle: "",
                icon: "checkmark.circle.fill",
                color: .green,
                description: locManager.t("permission.allSet.desc"),
                buttonTitle: locManager.t("permission.startUsing")
            )
        ]
    }

    var body: some View {
        ZStack {
            // Midnight gradient background (dark) or warm off-white (light)
            Group {
                if colorScheme == .dark {
                    GeometryReader { geo in
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(red: 0.114, green: 0.227, blue: 0.369), location: 0.0),
                                .init(color: Color(red: 0.039, green: 0.039, blue: 0.094), location: 0.55),
                                .init(color: .black, location: 1.0)
                            ]),
                            center: .init(x: 0.3, y: 0.2),
                            startRadius: 0,
                            endRadius: geo.size.width * 1.2
                        )
                        .ignoresSafeArea()
                    }
                } else {
                    Color(red: 0.941, green: 0.933, blue: 0.914)
                        .ignoresSafeArea()
                }
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Glow icon
                    GlowIcon(
                        icon: steps[currentStep].icon,
                        color: steps[currentStep].color,
                        size: 80
                    )
                    .padding(.bottom, 8)

                    VStack(spacing: 8) {
                        Text(steps[currentStep].title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)

                        if !steps[currentStep].subtitle.isEmpty {
                            Text(steps[currentStep].subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Text(steps[currentStep].description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .lineSpacing(4)
                }

                Spacer()
                Spacer()

                VStack(spacing: 16) {
                    Button(action: handleMainButton) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(steps[currentStep].buttonTitle)
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle(color: steps[currentStep].color))

                    if currentStep > 0 && currentStep < steps.count - 1 {
                        Button(action: skipStep) {
                            Text(locManager.t("permission.notNow"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep 
                                  ? steps[currentStep].color 
                                  : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStep ? 1.0 : 0.85)
                            .animation(.easeInOut(duration: 0.2), value: currentStep)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func handleMainButton() {
        switch currentStep {
        case 0:
            consentAccepted = true
            consentGivenAt = Date().timeIntervalSince1970
            nextStep()
        case 1: nextStep()
        case 2: requestLocation()
        case 3: requestMotion()
        case 4: requestCamera()
        case 5: requestMicrophone()
        case 6: requestBluetooth()
        case 7: requestHealth()
        case 8:
            isPresented = false
            onComplete()
        default: break
        }
    }

    private func skipStep() {
        if currentStep == 0 {
            consentAccepted = false
            consentGivenAt = Date().timeIntervalSince1970
        }
        nextStep()
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < steps.count - 1 { currentStep += 1 }
        }
    }

    private func requestLocation() {
        isProcessing = true
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            nextStep()
        }
    }

    private func requestMotion() {
        isProcessing = true
        // Trigger the iOS motion permission dialog by briefly starting activity updates
        let activityManager = CMMotionActivityManager()
        activityManager.startActivityUpdates(to: .main) { _ in
            // Permission dialog triggered — stop immediately
            activityManager.stopActivityUpdates()
            DispatchQueue.main.async {
                isProcessing = false
                nextStep()
            }
        }
        // Fallback: if no dialog appears (already decided), timeout after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            activityManager.stopActivityUpdates()
            if isProcessing {
                isProcessing = false
                nextStep()
            }
        }
    }

    private func requestCamera() {
        isProcessing = true
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                isProcessing = false
                nextStep()
            }
        }
    }

    private func requestMicrophone() {
        isProcessing = true
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            DispatchQueue.main.async {
                isProcessing = false
                nextStep()
            }
        }
    }

    private func requestBluetooth() {
        isProcessing = true
        // Trigger Bluetooth permission by creating a CBCentralManager
        _ = CBCentralManager(delegate: nil, queue: nil)
        // The permission dialog appears on initialization if status is notDetermined
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            nextStep()
        }
    }

    private func requestHealth() {
        isProcessing = true
        // HealthKit permission is requested in the HealthSensorManager
        // Just proceed to next step after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            nextStep()
        }
    }
}

struct PermissionStep {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let description: String
    let buttonTitle: String
}
