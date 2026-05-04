import SwiftUI
import CoreBluetooth

struct BluetoothDetailView: View {
    @EnvironmentObject var conn: ConnectivitySensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 50))
                        .foregroundStyle(conn.bluetoothState == .poweredOn ? .blue : .gray)
                    Text(conn.bluetoothStateText)
                        .font(.title)
                        .fontWeight(.bold)
                    StatusBadge(text: conn.bluetoothStateText, color: conn.bluetoothState == .poweredOn ? .green : .red)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Bluetooth Info")
                        .font(.headline)
                    DataRow(label: "State", value: conn.bluetoothStateText, icon: "antenna.radiowaves.left.and.right")
                    DataRow(label: "Scanning", value: conn.isScanning ? "Yes" : "No", icon: "magnifyingglass")
                    DataRow(label: "Discovered Devices", value: "\(conn.discoveredPeripherals.count)", icon: "list.bullet")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if conn.bluetoothState == .poweredOn {
                    Button(action: {
                        if conn.isScanning { conn.stopScanning() } else { conn.startScanning() }
                    }) {
                        Label(conn.isScanning ? "Stop Scanning" : "Start Scanning", systemImage: conn.isScanning ? "stop.circle" : "magnifyingglass")
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
                        Text("Discovered Devices")
                            .font(.headline)
                        ForEach(conn.discoveredPeripherals, id: \.identifier) { peripheral in
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(peripheral.name ?? "Unknown Device").fontWeight(.medium)
                                    Text(peripheral.identifier.uuidString).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
    }
}
