import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var diagnosticManager: DiagnosticManager
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @AppStorage("hasCompletedPermissionFlow") private var hasCompletedPermissionFlow = false
    @State private var showPermissionFlow = false

    var body: some View {
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
