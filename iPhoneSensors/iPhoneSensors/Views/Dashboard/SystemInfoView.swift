import SwiftUI

struct SystemInfoView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var sensorManager: SensorManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let sys = sensorManager.systemManager
        return NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        Text(sys.deviceName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        Text("\(sys.systemName) \(sys.systemVersion)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(locManager.t("section.deviceInfo"))
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        DataRow(label: locManager.t("label.deviceName"), value: sys.deviceName, icon: "iphone")
                        DataRow(label: locManager.t("label.model"), value: sys.deviceModel, icon: "cube")
                        DataRow(label: locManager.t("label.system"), value: "\(sys.systemName) \(sys.systemVersion)", icon: "gear")
                        DataRow(label: locManager.t("label.identifier"), value: sys.deviceIdentifierForVendor, icon: "number")
                        Divider().opacity(0.3)
                        DataRow(label: locManager.t("label.screenSize"), value: "\(Int(sys.screenBounds.width))×\(Int(sys.screenBounds.height))", icon: "rectangle")
                        DataRow(label: locManager.t("label.screenScale"), value: String(format: "%.0fx", sys.screenScale), icon: "arrow.up.left.and.arrow.down.right")
                        DataRow(label: locManager.t("label.brightness"), value: String(format: "%.0f%%", sys.screenBrightness * 100), icon: "sun.max.fill")
                        Divider().opacity(0.3)
                        DataRow(label: locManager.t("label.orientation"), value: locManager.t(sys.orientationKey), icon: "rotate.right")
                        DataRow(label: locManager.t("label.multitasking"), value: sys.isMultitaskingSupported ? locManager.t("value.supported") : locManager.t("value.notSupported"), icon: "square.split.2x2")
                    }
                    .padding()
                    .glassCard()

                    NavigationLink {
                        BatteryDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "battery.100")
                                .foregroundStyle(.green)
                            Text(locManager.t("label.batteryDetails"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(String(format: "%.0f%%", sys.batteryLevel * 100))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        ProcessorDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundStyle(.purple)
                            Text(locManager.t("label.processorDetails"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text("\(sys.activeProcessorCount) cores")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        MemoryDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundStyle(.indigo)
                            Text(locManager.t("label.memoryDetails"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: Int64(sys.physicalMemory), countStyle: .memory))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        DiskDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(.teal)
                            Text(locManager.t("label.storageDetails"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: sys.freeDiskSpace, countStyle: .memory) + locManager.t("unit.free"))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }

                    NavigationLink {
                        ThermalDetailView()
                    } label: {
                        HStack {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(.orange)
                            Text(locManager.t("label.thermalState"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text(locManager.t(sys.thermalStateKey))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .dashboardRow()
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(locManager.t("sensor.systemInfo"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
        }
    }
}

struct DiagnosticView: View {
    @EnvironmentObject var diagnosticManager: DiagnosticManager
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var location: LocationSensorManager
    @EnvironmentObject var environment: EnvironmentSensorManager
    @EnvironmentObject var system: SystemSensorManager
    @EnvironmentObject var connectivity: ConnectivitySensorManager
    @EnvironmentObject var camera: CameraSensorManager
    @EnvironmentObject var locManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showShareSheet = false
    @State private var reportText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Overall Score Card
                    scoreCard
                    
                    // Run All Button
                    runAllButton
                    
                    // Individual Tests
                    VStack(spacing: 8) {
                        ForEach(diagnosticManager.tests.indices, id: \.self) { index in
                            DiagnosticTestRow(
                                test: diagnosticManager.tests[index],
                                onRun: {
                                    Task {
                                        await diagnosticManager.runSingleTest(
                                            index: index,
                                            motion: motion,
                                            location: location,
                                            environment: environment,
                                            system: system,
                                            connectivity: connectivity,
                                            camera: camera
                                        )
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .glassCard()
                    
                    // Share Report Button
                    if diagnosticManager.overallScore > 0 {
                        Button(action: {
                            reportText = diagnosticManager.generateReport()
                            showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text(locManager.t("diagnostic.shareReport"))
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(locManager.t("diagnostic.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [reportText])
            }
        }
    }
    
    private var scoreCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: diagnosticManager.overallScore / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: diagnosticManager.overallScore)
                
                VStack {
                    Text("\(Int(diagnosticManager.overallScore))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    Text(locManager.t("diagnostic.score"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                StatItem(count: diagnosticManager.tests.filter { $0.status == .active }.count, label: locManager.t("diagnostic.active"), color: .green)
                StatItem(count: diagnosticManager.tests.filter { $0.status == .unavailable }.count, label: locManager.t("diagnostic.unavailable"), color: .gray)
                StatItem(count: diagnosticManager.tests.filter { $0.status == .permissionDenied }.count, label: locManager.t("diagnostic.permissionDenied"), color: .yellow)
            }
        }
        .padding()
        .glassCard()
    }
    
    private var scoreColor: Color {
        if diagnosticManager.overallScore >= 80 { return .green }
        if diagnosticManager.overallScore >= 50 { return .yellow }
        return .red
    }
    
    private var runAllButton: some View {
        Button(action: {
            Task {
                await diagnosticManager.runAllTests(
                    motion: motion,
                    location: location,
                    environment: environment,
                    system: system,
                    connectivity: connectivity,
                    camera: camera
                )
            }
        }) {
            HStack {
                Image(systemName: diagnosticManager.isRunning ? "stop.fill" : "play.fill")
                Text(diagnosticManager.isRunning ? "Running Tests..." : "Run All Tests")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(diagnosticManager.isRunning ? Color.orange : Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(diagnosticManager.isRunning)
        .padding(.horizontal)
    }
}

struct DiagnosticTestRow: View {
    let test: DiagnosticTest
    let onRun: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            statusIcon
            
            // Test Info
            VStack(alignment: .leading, spacing: 2) {
                Text(test.id.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                
                statusText
            }
            
            Spacer()
            
            // Run Button / Settings Button
            if case .notStarted = test.status {
                Button(action: onRun) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(test.color)
                }
            } else if case .permissionDenied = test.status {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "lock.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusIcon: some View {
        let icon: String
        let color: Color
        
        switch test.status {
        case .active:
            icon = "checkmark.circle.fill"
            color = .green
        case .unavailable:
            icon = "gearshape.fill"
            color = .gray
        case .permissionDenied:
            icon = "lock.fill"
            color = .yellow
        case .inProgress:
            icon = "arrow.triangle.2.circlepath"
            color = .blue
        case .skipped:
            icon = "minus.circle.fill"
            color = .orange
        case .notStarted:
            icon = "circle"
            color = .gray
        }
        
        return Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
    }
    
    private var statusText: some View {
        let text: String
        let color: Color
        
        switch test.status {
        case .active:
            text = locManager.t("diagnostic.active")
            color = .green
        case .unavailable:
            text = locManager.t("diagnostic.unavailable")
            color = .gray
        case .permissionDenied:
            text = locManager.t("diagnostic.permissionRequired")
            color = .yellow
        case .inProgress:
            text = locManager.t("diagnostic.testing")
            color = .blue
        case .skipped:
            text = locManager.t("diagnostic.skipped")
            color = .orange
        case .notStarted:
            text = locManager.t("diagnostic.notStarted")
            color = .secondary
        }
        
        return Text(text)
            .font(.caption)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
