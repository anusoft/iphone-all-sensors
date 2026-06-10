import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var diagnosticManager: DiagnosticManager
    @EnvironmentObject var screenshotRouter: ScreenshotRouter
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedTab = 0
    @AppStorage("hasCompletedPermissionFlow") private var hasCompletedPermissionFlow = false
    @State private var showPermissionFlow = false

    /// Regular-width iPad surfaces get the tuned accessibility-size bump, while
    /// compact-width iPhone rendering preserves the user's current Dynamic Type size.
    private var adaptiveDynamicTypeSize: DynamicTypeSize {
        horizontalSizeClass == .regular ? max(dynamicTypeSize, .accessibility1) : dynamicTypeSize
    }

    // Screenshot shortcut: launch with `--showoff <sensorID> <variantIdx>`
    // to skip straight into Show-Off Mode at a specific variant.
    private var screenshotShowOff: (String, Int)? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--showoff"),
              idx + 2 < args.count,
              let variant = Int(args[idx + 2]) else { return nil }
        return (args[idx + 1], variant)
    }

    // Deterministic App Store capture: launch with `--screenshot <page-name>`
    // to render ScreenshotHeroView directly. This is collision-proof (unlike the
    // `app://` URL scheme, which LaunchServices may disambiguate when more than one
    // installed app claims it) and drives the exact same routing target as the
    // `.onOpenURL` deep link. Used by screenshot/capture.sh.
    private var screenshotPageArg: ScreenshotPage? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--screenshot"), idx + 1 < args.count else { return nil }
        return ScreenshotPage(pageName: args[idx + 1])
    }

    var body: some View {
        if let page = screenshotRouter.activePage ?? screenshotPageArg {
            // Deep-linked App Store capture surface. Pure mock data — no
            // sensors or permission flow — so the screenshot is deterministic.
            ScreenshotHeroView(page: page)
                .transition(.opacity)
        } else if let (sid, variant) = screenshotShowOff {
            ShowOffMode(initialSensorID: sid, initialVariant: variant, showsTutorial: false)
                .onAppear { sensorManager.startAllSensors() }
        } else {
            mainBody
        }
    }

    private var mainBody: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(locManager.t("tab.sensors"), systemImage: "sensor.tag.radiowaves.forward")
                    }
                    .tag(0)

                SystemInfoView()
                    .tabItem {
                        Label(locManager.t("tab.system"), systemImage: "iphone.gen3")
                    }
                    .tag(1)

                EnvironmentView()
                    .tabItem {
                        Label(locManager.t("tab.environment"), systemImage: "leaf")
                    }
                    .tag(2)

                DiagnosticView()
                    .tabItem {
                        Label(locManager.t("diagnostic.title"), systemImage: "stethoscope")
                    }
                    .tag(3)

                HealthView()
                    .tabItem {
                        Label(locManager.t("tab.health"), systemImage: "heart.text.square")
                    }
                    .tag(4)

                LoggerOverviewView()
                    .tabItem {
                        Label(locManager.t("tab.logger"), systemImage: "record.circle")
                    }
                    .tag(5)
            }
            .tint(.blue)
            // iPad scale-up: enlarge all (semantic-font) text on regular width so the
            // app uses the larger screen. max(...) respects users on even bigger
            // accessibility sizes; iPhone (compact) is left untouched.
            .environment(\.dynamicTypeSize, adaptiveDynamicTypeSize)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(colorScheme == .dark 
                               ? Color.black.opacity(0.3)
                               : Color.white.opacity(0.3),
                               for: .tabBar)
            .onAppear {
                if hasCompletedPermissionFlow {
                    sensorManager.startAllSensors()
                } else {
                    showPermissionFlow = true
                }
            }

            if showPermissionFlow {
                PermissionRequestView(isPresented: $showPermissionFlow, onComplete: {
                    hasCompletedPermissionFlow = true
                    sensorManager.startAllSensors()
                })
                .environmentObject(locManager)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}
