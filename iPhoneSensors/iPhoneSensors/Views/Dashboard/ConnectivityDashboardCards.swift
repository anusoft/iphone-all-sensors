import SwiftUI

struct ConnectivityDashboardCards: View {
    @EnvironmentObject var conn: ConnectivitySensorManager

    var body: some View {
        VStack(spacing: 10) {
            NavigationLink {
                BluetoothDetailView()
            } label: {
                SensorCard(
                    title: "Bluetooth",
                    icon: "antenna.radiowaves.left.and.right",
                    value: conn.bluetoothStateText,
                    unit: "",
                    color: .blue,
                    isAvailable: conn.bluetoothState == .poweredOn
                )
            }
            NavigationLink {
                NetworkDetailView()
            } label: {
                SensorCard(
                    title: "Network",
                    icon: "network",
                    value: conn.networkType,
                    unit: conn.isConnectedToNetwork ? "Connected" : "Disconnected",
                    color: conn.isConnectedToNetwork ? .green : .red,
                    isAvailable: true
                )
            }
        }
    }
}
