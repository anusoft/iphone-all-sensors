import SwiftUI

struct SignalMapPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let networkType: String
        let signalQuality: String
    }

struct NetworkDetailView: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var conn: ConnectivitySensorManager

    @EnvironmentObject var loc: LocationSensorManager
    @State private var isRecordingSignal = false
    @State private var signalPoints: [SignalMapPoint] = []
    @State private var signalRecordTimer: Timer?
    @State private var showSignalShareSheet = false
    @State private var signalExportURL: URL?

    private var ssidRow: some View {
        Group {
            if loc.isAuthorized {
                DataRow(label: locManager.t("network.ssid"), value: conn.wifiSSID, icon: "wifi")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.yellow)
                        Text(locManager.t("network.ssidUnavailable"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    Text(locManager.t("network.ssidRequiresLocation"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text(locManager.t("network.openSettings"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func toggleSignalRecording() {
        if isRecordingSignal {
            isRecordingSignal = false
            signalRecordTimer?.invalidate()
            signalRecordTimer = nil
        } else {
            isRecordingSignal = true
            signalPoints = []
            signalRecordTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                guard loc.isAuthorized else { return }
                let quality = conn.isConnectedToNetwork ? (conn.networkType == "Wi-Fi" ? "Excellent" : "Good") : "No Signal"
                let point = SignalMapPoint(
                    timestamp: Date(),
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    networkType: conn.networkType,
                    signalQuality: quality
                )
                signalPoints.append(point)
            }
            // Record first point immediately
            if loc.isAuthorized {
                let quality = conn.isConnectedToNetwork ? (conn.networkType == "Wi-Fi" ? "Excellent" : "Good") : "No Signal"
                signalPoints.append(SignalMapPoint(
                    timestamp: Date(),
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    networkType: conn.networkType,
                    signalQuality: quality
                ))
            }
        }
    }

    private func exportSignalCSV() {
        var csv = "Timestamp,Latitude,Longitude,NetworkType,SignalQuality\n"
        let formatter = ISO8601DateFormatter()
        for point in signalPoints {
            csv += "\(formatter.string(from: point.timestamp)),\(point.latitude),\(point.longitude),\(point.networkType),\(point.signalQuality)\n"
        }
        if let url = saveToFile(content: csv, filename: "signal_map_\(Int(Date().timeIntervalSince1970)).csv") {
            signalExportURL = url
            showSignalShareSheet = true
        }
    }

    private func exportSignalKML() {
        var kml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        kml += "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n"
        kml += "<Document>\n<name>Signal Map</name>\n"
        for point in signalPoints {
            let color = point.signalQuality == "Excellent" ? "ff00ff00" : (point.signalQuality == "Good" ? "ff00ffff" : "ff0000ff")
            kml += "<Placemark>\n"
            kml += "<Point><coordinates>\(point.longitude),\(point.latitude),0</coordinates></Point>\n"
            kml += "<Style><IconStyle><color>\(color)</color><scale>1.0</scale></IconStyle></Style>\n"
            kml += "</Placemark>\n"
        }
        kml += "</Document>\n</kml>"
        if let url = saveToFile(content: kml, filename: "signal_map_\(Int(Date().timeIntervalSince1970)).kml") {
            signalExportURL = url
            showSignalShareSheet = true
        }
    }

    private func saveToFile(content: String, filename: String) -> URL? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename) else { return nil }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("[Export] Failed to save: \(error)")
            return nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: conn.isConnectedToNetwork ? "network" : "network.slash")
                        .font(.system(size: 50))
                        .foregroundStyle(conn.isConnectedToNetwork ? .green : .red)
                    Text(locManager.t("network." + conn.networkType.lowercased().replacingOccurrences(of: "-", with: "")))
                        .font(.title)
                        .fontWeight(.bold)
                    StatusBadge(text: conn.isConnectedToNetwork ? locManager.t("status.connected") : locManager.t("status.disconnected"), color: conn.isConnectedToNetwork ? .green : .red)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text(locManager.t("section.info"))
                        .font(.headline)
                    DataRow(label: locManager.t("label.connectionType"), value: locManager.t("network." + conn.networkType.lowercased().replacingOccurrences(of: "-", with: "")), icon: "network")
                    DataRow(label: locManager.t("label.status"), value: conn.isConnectedToNetwork ? locManager.t("status.connected") : locManager.t("status.disconnected"), icon: "wifi")
                    ssidRow
                    DataRow(label: locManager.t("label.carrier"), value: conn.cellularCarrier == "Unknown" ? locManager.t("compass.unknown") : conn.cellularCarrier, icon: "antenna.radiowaves.left.and.right")
                    DataRow(label: locManager.t("label.radioTechnology"), value: conn.cellularRadioTechnology == "N/A" ? locManager.t("compass.unknown") : conn.cellularRadioTechnology, icon: "cellularbars")
                }
                .glassCard()

                // Signal Map Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(locManager.t("signalMap.title"))
                            .font(.headline)
                        Spacer()
                        Button(action: toggleSignalRecording) {
                            Text(isRecordingSignal ? locManager.t("signalMap.stopRecording") : locManager.t("signalMap.startRecording"))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRecordingSignal ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                                .foregroundStyle(isRecordingSignal ? .red : .blue)
                                .clipShape(Capsule())
                        }
                    }

                    if isRecordingSignal {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Recording...")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if !signalPoints.isEmpty {
                        Text("\(signalPoints.count) points recorded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(signalPoints.suffix(5).reversed()) { point in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(String(format: "%.4f", point.latitude)), \(String(format: "%.4f", point.longitude))")
                                        .font(.caption)
                                        .monospacedDigit()
                                    Text(point.networkType)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(point.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        HStack(spacing: 12) {
                            Button(action: exportSignalCSV) {
                                Label(locManager.t("signalMap.exportCSV"), systemImage: "doc.text")
                                    .font(.caption)
                            }
                            if signalPoints.count >= 3 {
                                Button(action: exportSignalKML) {
                                    Label(locManager.t("signalMap.exportKML"), systemImage: "map")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        Text(locManager.t("signalMap.noData"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .glassCard()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(locManager.t("sensor.network"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SettingsToolbarButton()
            }
        }
        .sheet(isPresented: $showSignalShareSheet) {
            if let url = signalExportURL {
                ShareSheet(items: [url])
            }
        }
    }
}
