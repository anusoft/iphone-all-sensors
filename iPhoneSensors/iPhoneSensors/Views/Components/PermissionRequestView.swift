import SwiftUI
import CoreLocation
import AVFoundation

struct PermissionRequestView: View {
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    @EnvironmentObject var locManager: LocalizationManager

    @State private var currentStep = 0
    @State private var isProcessing = false

    private var steps: [PermissionStep] {
        [
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
                subtitle: "GPS • Compass • Altitude",
                icon: "location.fill",
                color: .green,
                description: locManager.t("permission.location.desc"),
                buttonTitle: locManager.t("permission.allowLocation")
            ),
            PermissionStep(
                title: locManager.t("permission.motion"),
                subtitle: "Accelerometer • Gyroscope • Steps",
                icon: "figure.walk",
                color: .blue,
                description: locManager.t("permission.motion.desc"),
                buttonTitle: locManager.t("permission.allowMotion")
            ),
            PermissionStep(
                title: locManager.t("permission.camera"),
                subtitle: "Camera Info • Torch",
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
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 80))
                        .foregroundStyle(steps[currentStep].color)
                        .padding(.bottom, 10)

                    Text(steps[currentStep].title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if !steps[currentStep].subtitle.isEmpty {
                        Text(steps[currentStep].subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text(steps[currentStep].description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: handleMainButton) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(steps[currentStep].buttonTitle)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(steps[currentStep].color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isProcessing)

                    if currentStep > 0 && currentStep < steps.count - 1 {
                        Button(action: skipStep) {
                            Text(locManager.t("permission.notNow"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 30)

                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? steps[currentStep].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func handleMainButton() {
        switch currentStep {
        case 0: nextStep()
        case 1: requestLocation()
        case 2: requestMotion()
        case 3: requestCamera()
        case 4: requestMicrophone()
        case 5:
            isPresented = false
            onComplete()
        default: break
        }
    }

    private func skipStep() { nextStep() }

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            nextStep()
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
}

struct PermissionStep {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let description: String
    let buttonTitle: String
}
