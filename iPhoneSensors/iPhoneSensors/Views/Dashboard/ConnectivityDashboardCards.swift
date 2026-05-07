import SwiftUI

struct ConnectivityDashboardCards: View {
    @EnvironmentObject var conn: ConnectivitySensorManager
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                BluetoothDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.bluetooth"),
                    icon: "antenna.radiowaves.left.and.right",
                    value: locManager.t(conn.bluetoothStateText),
                    unit: "",
                    color: .blue,
                    isAvailable: conn.bluetoothState == .poweredOn
                )
            }
            NavigationLink {
                NetworkDetailView()
            } label: {
                SensorCard(
                    title: locManager.t("sensor.network"),
                    icon: "network",
                    value: locManager.t("network." + conn.networkType.lowercased().replacingOccurrences(of: "-", with: "")),
                    unit: conn.isConnectedToNetwork ? locManager.t("status.connected") : locManager.t("status.disconnected"),
                    color: conn.isConnectedToNetwork ? .green : .red,
                    isAvailable: true
                )
            }
        }
    }
}
