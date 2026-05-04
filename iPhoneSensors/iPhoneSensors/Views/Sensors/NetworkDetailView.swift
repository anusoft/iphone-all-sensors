import SwiftUI

struct NetworkDetailView: View {
    @EnvironmentObject var conn: ConnectivitySensorManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: conn.isConnectedToNetwork ? "network" : "network.slash")
                        .font(.system(size: 50))
                        .foregroundStyle(conn.isConnectedToNetwork ? .green : .red)
                    Text(conn.networkType)
                        .font(.title)
                        .fontWeight(.bold)
                    StatusBadge(text: conn.isConnectedToNetwork ? "Connected" : "Disconnected", color: conn.isConnectedToNetwork ? .green : .red)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Network Info")
                        .font(.headline)
                    DataRow(label: "Connection Type", value: conn.networkType, icon: "network")
                    DataRow(label: "Status", value: conn.isConnectedToNetwork ? "Connected" : "Disconnected", icon: "wifi")
                    DataRow(label: "Carrier", value: conn.cellularCarrier, icon: "antenna.radiowaves.left.and.right")
                    DataRow(label: "Radio Technology", value: conn.cellularRadioTechnology, icon: "cellularbars")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Network")
        .navigationBarTitleDisplayMode(.inline)
    }
}
