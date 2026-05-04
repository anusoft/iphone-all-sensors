import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sensorManager: SensorManager
    @EnvironmentObject var locManager: LocalizationManager
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

                HealthView()
                    .tabItem {
                        Label(locManager.t("tab.health"), systemImage: "heart.text.square")
                    }
                    .tag(3)
            }
            .tint(.blue)
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
