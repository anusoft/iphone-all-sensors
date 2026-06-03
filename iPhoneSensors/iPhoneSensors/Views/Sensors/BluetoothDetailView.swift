import SwiftUI
import CoreBluetooth

struct BluetoothDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var conn: ConnectivitySensorManager

    var body: some View {
        ScrollView {
            AdaptiveCardGrid(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundStyle(conn.bluetoothState == .poweredOn ? .blue : .gray)
                    Text(locManager.t(conn.bluetoothStateText))
                        .font(.title)
                        .fontWeight(.bold)
                    StatusBadge(text: locManager.t(conn.bluetoothStateText), color: conn.bluetoothState == .poweredOn ? .green : .red)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.state"), value: locManager.t(conn.bluetoothStateText), icon: "antenna.radiowaves.left.and.right")
                    DataRow(label: locManager.t("label.scanning"), value: conn.isScanning ? locManager.t("value.yes") : locManager.t("value.no"), icon: "magnifyingglass")
                    DataRow(label: locManager.t("bluetooth.discoveredDevices"), value: "\(conn.discoveredPeripherals.count)", icon: "list.bullet")
                }
                .glassCard()

                if conn.bluetoothState == .poweredOn {
                    Button(action: {
                        if conn.isScanning { conn.stopScanning() } else { conn.startScanning() }
                    }) {
                        Label(conn.isScanning ? locManager.t("label.scanning") : locManager.t("label.scanning"), systemImage: conn.isScanning ? "stop.circle" : "magnifyingglass")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(conn.isScanning ? Color.red : Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }

                if !conn.discoveredPeripherals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(locManager.t("bluetooth.discoveredDevices"))
                            .font(.headline)
                        ForEach(conn.discoveredPeripherals, id: \.identifier) { peripheral in
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(peripheral.name ?? locManager.t("compass.unknown")).fontWeight(.medium)
                                    Text(peripheral.identifier.uuidString).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .glassCard()
                }
            }
            .padding()
        }
        .appBackground()
        .loggerInlineCard(.bluetoothState)
        .showOffEntry(sensorID: "16", accent: SO.btAccent)
        .navigationTitle(locManager.t("sensor.bluetooth"))
        .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton()
                }
            }
    }
}
