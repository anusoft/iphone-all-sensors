import SwiftUI
import CoreBluetooth

// ════════════════════════════════════════════════════════════
// Sensor 16 — BLUETOOTH
// ════════════════════════════════════════════════════════════

struct SOBluetooth: View {
    let variant: Int
    @EnvironmentObject var conn: ConnectivitySensorManager
    var body: some View {
        switch variant {
        case 0: BtRadar(conn: conn)
        case 1: BtList(conn: conn)
        default: BtBeacon(conn: conn)
        }
    }
}

private struct BtRadar: View {
    @ObservedObject var conn: ConnectivitySensorManager
    var body: some View {
        SOVariant(sensor: "BT", accent: SO.btAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Bluetooth Radar")
                Spacer().frame(height: 18)
                radar.frame(width: 320, height: 320)
                Spacer().frame(height: 14)
                SOFormattedTextLabel(format: "%d devices", value: conn.discoveredPeripherals.count)
                    .font(.system(size: 18, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.btAccent)
                Spacer()
                SOTickerBar(accent: SO.btAccent, items: [
                    .init(label: "STATE", value: stateText, accent: true),
                    .init(label: "FOUND", value: "\(conn.discoveredPeripherals.count)"),
                    .init(label: "CONN",  value: "\(conn.connectedPeripherals.count)"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var stateText: String {
        switch conn.bluetoothState {
        case .poweredOn:  return "ON"
        case .poweredOff: return "OFF"
        case .unauthorized: return "DENIED"
        default: return "—"
        }
    }
    private var radar: some View {
        SOTick { t in
            ZStack {
                ForEach([260, 200, 140, 80], id: \.self) { d in
                    Circle().strokeBorder(SO.btAccent.opacity(0.3), lineWidth: 1)
                        .frame(width: CGFloat(d), height: CGFloat(d))
                }
                Path { p in
                    p.move(to: .init(x: 130, y: 130))
                    p.addArc(center: .init(x: 130, y: 130), radius: 130,
                             startAngle: .degrees(-90), endAngle: .degrees(-30),
                             clockwise: false)
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [SO.btAccent.opacity(0.55), SO.btAccent.opacity(0)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(t * 90))
                ForEach(0..<5, id: \.self) { i in
                    let pings = [(50.0, 30.0),(-60.0, 40.0),(80.0, -50.0),(-40.0, -80.0),(20.0, 100.0)]
                    Circle()
                        .fill(SO.btAccent)
                        .frame(width: 8, height: 8)
                        .shadow(color: SO.btAccent, radius: 8)
                        .offset(x: pings[i].0, y: pings[i].1)
                }
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(SO.btAccent)
            }
        }
    }
}

private struct BtList: View {
    @ObservedObject var conn: ConnectivitySensorManager
    var body: some View {
        SOVariant(sensor: "BT", accent: SO.btAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Discovered · RSSI sorted")
                Spacer().frame(height: 14)
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { i in
                            row(name: "Device \(i + 1)", rssi: -40 - i * 8)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .frame(maxHeight: 380)
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private func row(name: String, rssi: Int) -> some View {
        let strength = max(0, min(1, Double(rssi + 100) / 60))
        return HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SO.btAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text("AB:CD:EF:01:23")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(rssi)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SO.btAccent)
                HStack(spacing: 1) {
                    ForEach(0..<5, id: \.self) { i in
                        let active = Double(i) / 5 < strength
                        Rectangle()
                            .fill(active ? SO.btAccent : .white.opacity(0.1))
                            .frame(width: 3, height: CGFloat(4 + i * 2))
                    }
                }
            }
        }
        .padding(10)
        .background(.white.opacity(0.04))
        .cornerRadius(10)
    }
}

private struct BtBeacon: View {
    @ObservedObject var conn: ConnectivitySensorManager
    var body: some View {
        SOVariant(sensor: "BT", accent: SO.btAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Beacon · emit only")
                Spacer().frame(height: 18)
                beacon.frame(width: 320, height: 320)
                Spacer().frame(height: 14)
                SOTextLabel("BROADCASTING")
                    .font(.system(size: 16, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.btAccent)
                Spacer()
                SOTickerBar(accent: SO.btAccent, items: [
                    .init(label: "UUID",  value: "0x1A2B…F"),
                    .init(label: "MAJ",   value: "1"),
                    .init(label: "MIN",   value: "1", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var beacon: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    let phase = (t * 0.6 + Double(i) * 0.4).truncatingRemainder(dividingBy: 2.5)
                    Circle()
                        .strokeBorder(SO.btAccent.opacity(max(0, 1 - phase / 2.5)), lineWidth: 2)
                        .frame(width: CGFloat(60 + phase * 100),
                               height: CGFloat(60 + phase * 100))
                }
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 64, weight: .black))
                    .foregroundStyle(SO.btAccent)
                    .shadow(color: SO.btAccent, radius: 18)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 17 — NETWORK
// ════════════════════════════════════════════════════════════

struct SONetwork: View {
    let variant: Int
    @EnvironmentObject var conn: ConnectivitySensorManager
    var body: some View {
        switch variant {
        case 0: NetSignalCity(conn: conn)
        case 1: NetThroughput(conn: conn)
        default: NetTree(conn: conn)
        }
    }
}

private struct NetSignalCity: View {
    @ObservedObject var conn: ConnectivitySensorManager
    @EnvironmentObject private var locManager: LocalizationManager

    private var localizedNetworkType: String {
        locManager.t("network." + conn.networkType.lowercased().replacingOccurrences(of: "-", with: ""))
    }

    private func displayNetworkValue(_ value: String) -> String {
        if value == "N/A" || value == "Unknown" || value.isEmpty {
            return locManager.t("compass.unknown")
        }
        return value
    }

    var body: some View {
        SOVariant(sensor: "NET", accent: SO.netAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.0, green: 0.10, blue: 0.18),
                                    Color(red: 0.0, green: 0.04, blue: 0.10)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Signal City")
                Text(localizedNetworkType.uppercased())
                    .font(.system(size: 32, weight: .heavy)).tracking(2)
                    .foregroundStyle(SO.netAccent)
                    .shadow(color: SO.netAccent, radius: 12)
                    .padding(.top, 4)
                Spacer().frame(height: 18)
                skyline.frame(width: 320, height: 280)
                Spacer().frame(height: 14)
                Text(displayNetworkValue(conn.wifiSSID))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                SOTickerBar(accent: SO.netAccent, items: [
                    .init(label: "TYPE",     value: localizedNetworkType),
                    .init(label: "ONLINE",   value: conn.isConnectedToNetwork ? "YES" : "NO", accent: true),
                    .init(label: "CARRIER",  value: displayNetworkValue(conn.cellularCarrier)),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var skyline: some View {
        SOTick { t in
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(SO.netAccent.opacity(0.2 + sin(t + Double(i)) * 0.05 + 0.1))
                            .frame(width: 26, height: CGFloat(80 + i * 12))
                            .overlay(
                                VStack(spacing: 4) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        HStack(spacing: 2) {
                                            ForEach(0..<2, id: \.self) { _ in
                                                Rectangle().fill(.white.opacity(0.1))
                                                    .frame(width: 5, height: 4)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            )
                    }
                }
                // Active tower with antennas
                VStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(SO.netAccent)
                        .shadow(color: SO.netAccent, radius: 12)
                    Rectangle().fill(SO.netAccent).frame(width: 2, height: 30)
                }
                .offset(y: -180)
            }
        }
    }
}

private struct NetThroughput: View {
    @ObservedObject var conn: ConnectivitySensorManager
    var body: some View {
        SOVariant(sensor: "NET", accent: SO.netAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Throughput · Mbps")
                Spacer().frame(height: 14)
                HStack(alignment: .top, spacing: 24) {
                    speedBlock(title: "DOWN", value: "142", icon: "arrow.down")
                    speedBlock(title: "UP",   value: "38",  icon: "arrow.up")
                }
                .padding(.horizontal, 18)
                Spacer().frame(height: 14)
                SOTextLabel("EST")
                    .font(.system(size: 11, weight: .heavy)).tracking(2)
                    .foregroundStyle(SO.netAccent)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(SO.netAccent.opacity(0.15)))
                Spacer().frame(height: 16)
                SOLabel(text: "TRACE · 30 s", size: 9).padding(.horizontal, 18)
                SOSpark(accent: SO.netAccent, amp: 0.5, freq: 1.2)
                    .frame(height: 80).padding(.horizontal, 18).padding(.top, 6)
                Spacer()
                SOTickerBar(accent: SO.netAccent, items: [
                    .init(label: "PING",   value: "12 ms"),
                    .init(label: "JITTER", value: "2 ms"),
                    .init(label: "LOSS",   value: "0%", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private func speedBlock(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(SO.netAccent)
                SOLabel(text: title, size: 9)
            }
            Text(value)
                .font(.system(size: 80, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            + Text(" Mbps")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NetTree: View {
    @ObservedObject var conn: ConnectivitySensorManager
    @EnvironmentObject private var locManager: LocalizationManager

    private func displayNetworkValue(_ value: String) -> String {
        if value == "N/A" || value == "Unknown" || value.isEmpty {
            return locManager.t("compass.unknown")
        }
        return value
    }

    var body: some View {
        SOVariant(sensor: "NET", accent: SO.netAccent) {
            VStack(spacing: 18) {
                Spacer().frame(height: 80)
                SOLabel(text: "Network Path · iPhone → World")
                node(icon: "iphone", text: "iPhone", subtext: displayNetworkValue(conn.wifiSSID))
                connector
                node(icon: "wifi.router", text: "Router", subtext: "192.168.1.1")
                connector
                node(icon: "globe", text: "ISP",  subtext: displayNetworkValue(conn.cellularCarrier))
                connector
                node(icon: "network", text: "WORLD", subtext: "1.1.1.1 · OK", accent: true)
                Spacer().frame(height: 110)
            }
        }
    }
    private var connector: some View {
        Rectangle()
            .fill(LinearGradient(colors: [SO.netAccent.opacity(0.2), SO.netAccent.opacity(0.6)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 2, height: 32)
    }
    private func node(icon: String, text: String, subtext: String, accent: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent ? SO.netAccent : .white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(accent ? SO.netAccent.opacity(0.2) : Color.white.opacity(0.06)))
                .shadow(color: accent ? SO.netAccent : .clear, radius: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(.system(size: 16, weight: .heavy)).foregroundStyle(.white)
                Text(subtext)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 18 — CAMERA
// ════════════════════════════════════════════════════════════

struct SOCamera: View {
    let variant: Int
    @EnvironmentObject var cam: CameraSensorManager
    var body: some View {
        switch variant {
        case 0: CamLensBoard(cam: cam)
        case 1: CamViewfinder(cam: cam)
        default: CamAudio(cam: cam)
        }
    }
}

private struct CamLensBoard: View {
    @ObservedObject var cam: CameraSensorManager
    var body: some View {
        SOVariant(sensor: "CAM", accent: SO.camAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Lens Board · capabilities")
                Spacer().frame(height: 30)
                lenses.frame(width: 320, height: 200)
                Spacer().frame(height: 24)
                VStack(spacing: 8) {
                    capRow("Front Camera", on: cam.isFrontCameraAvailable)
                    capRow("Rear Camera",  on: cam.isRearCameraAvailable)
                    capRow("Flash",        on: cam.isFlashAvailable)
                    capRow("Torch",        on: cam.isTorchAvailable)
                    capRow("Auth Granted", on: cam.cameraAccessGranted)
                }
                .padding(.horizontal, 30)
                Spacer().frame(height: 110)
            }
        }
    }
    private var lenses: some View {
        HStack(spacing: 18) {
            ForEach(["1x", "2x", "5x"], id: \.self) { l in
                ZStack {
                    Circle().fill(.black)
                    Circle().strokeBorder(SO.camAccent.opacity(0.6), lineWidth: 2)
                    Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1).padding(8)
                    Circle().fill(.white.opacity(0.05)).frame(width: 60, height: 60)
                    Text(l).font(.system(size: 14, weight: .heavy)).foregroundStyle(.white)
                }
                .frame(width: 90, height: 90)
            }
        }
    }
    private func capRow(_ name: String, on: Bool) -> some View {
        HStack {
            Circle().fill(on ? .green : .red).frame(width: 8, height: 8)
                .shadow(color: on ? .green : .red, radius: 6)
            Text(name).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
            Spacer()
            Text(on ? "AVAIL" : "—")
                .font(.system(size: 9, weight: .heavy)).tracking(2)
                .foregroundStyle(on ? .green : .red.opacity(0.6))
        }
    }
}

private struct CamViewfinder: View {
    @ObservedObject var cam: CameraSensorManager
    var body: some View {
        SOVariant(sensor: "CAM", accent: SO.camAccent, bg: .custom(
            LinearGradient(colors: [Color.black, Color(white: 0.05)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 70)
                viewfinder.frame(maxWidth: .infinity)
                Spacer().frame(height: 14)
                zoomLadder
                Spacer().frame(height: 110)
            }
        }
    }
    private var viewfinder: some View {
        ZStack {
            Rectangle().fill(.black)
            // Frame markers
            VStack {
                HStack {
                    cornerBracket(corners: [.topLeft])
                    Spacer()
                    cornerBracket(corners: [.topRight])
                }
                Spacer()
                HStack {
                    cornerBracket(corners: [.bottomLeft])
                    Spacer()
                    cornerBracket(corners: [.bottomRight])
                }
            }
            .padding(20)
            // Center reticle
            ZStack {
                Rectangle().fill(.white.opacity(0.4)).frame(width: 60, height: 1)
                Rectangle().fill(.white.opacity(0.4)).frame(width: 1, height: 60)
                Circle().strokeBorder(SO.camAccent, lineWidth: 1).frame(width: 80, height: 80)
            }
            // Rule of thirds
            VStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
                Spacer()
                Rectangle().fill(.white.opacity(0.15)).frame(height: 0.5)
            }
            HStack(spacing: 0) {
                Rectangle().fill(.white.opacity(0.15)).frame(width: 0.5)
                Spacer()
                Rectangle().fill(.white.opacity(0.15)).frame(width: 0.5)
            }
        }
        .frame(height: 360)
    }
    private func cornerBracket(corners: [UIRectCorner]) -> some View {
        Path { p in
            p.move(to: .init(x: 0, y: 14))
            p.addLine(to: .init(x: 0, y: 0))
            p.addLine(to: .init(x: 14, y: 0))
        }
        .stroke(SO.camAccent, lineWidth: 2)
        .frame(width: 14, height: 14)
        .scaleEffect(x: corners.contains(.topRight) || corners.contains(.bottomRight) ? -1 : 1,
                     y: corners.contains(.bottomLeft) || corners.contains(.bottomRight) ? -1 : 1)
    }
    private var zoomLadder: some View {
        HStack(spacing: 8) {
            ForEach(["0.5x","1x","2x","3x","5x"], id: \.self) { z in
                Text(z)
                    .font(.system(size: 11, weight: .heavy))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(z == "1x" ? SO.camAccent : Color.white.opacity(0.06)))
                    .foregroundStyle(z == "1x" ? .black : .white.opacity(0.7))
            }
        }
    }
}

private struct CamAudio: View {
    @ObservedObject var cam: CameraSensorManager
    var body: some View {
        SOVariant(sensor: "CAM", accent: SO.camAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Audio · Stereo VU")
                Spacer().frame(height: 18)
                vu.frame(width: 240, height: 320)
                Spacer().frame(height: 18)
                SOTickerBar(accent: SO.camAccent, items: [
                    .init(label: "SR",  value: "\(Int(cam.audioSampleRate)) Hz"),
                    .init(label: "CH",  value: "\(cam.audioInputChannels)"),
                    .init(label: "AVAIL", value: cam.isAudioInputAvailable ? "YES" : "NO", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var vu: some View {
        SOTick { t in
            HStack(alignment: .bottom, spacing: 30) {
                vuMeter(amp: 0.6 + sin(t * 1.2) * 0.2, channel: "L")
                vuMeter(amp: 0.5 + sin(t * 1.4 + 1) * 0.25, channel: "R")
            }
        }
    }
    private func vuMeter(amp: Double, channel: String) -> some View {
        VStack(spacing: 8) {
            Text(channel).font(.system(size: 14, weight: .heavy)).foregroundStyle(SO.camAccent)
            ZStack(alignment: .bottom) {
                Rectangle().fill(.white.opacity(0.06)).frame(width: 60, height: 280)
                Rectangle()
                    .fill(LinearGradient(colors: [.red, .yellow, .green],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 60, height: max(8, 280 * amp))
                    .shadow(color: SO.camAccent, radius: 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 19 — LIGHT
// ════════════════════════════════════════════════════════════

struct SOLight: View {
    let variant: Int
    @EnvironmentObject var env: EnvironmentSensorManager
    var body: some View {
        switch variant {
        case 0: LightLuxMeter(env: env)
        case 1: LightLamp(env: env)
        default: LightCamLux(env: env)
        }
    }
}

private struct LightLuxMeter: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        let val = env.screenBrightness
        SOVariant(sensor: "LIGHT", accent: SO.lightAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Lux Meter · estimated")
                Spacer().frame(height: 16)
                SORadialGauge(value: val,
                              label: "lux est",
                              valueText: String(format: "%.0f", val * 1000),
                              accent: SO.lightAccent, ticks: 14, size: 260)
                Spacer().frame(height: 8)
                SOTextLabel("EST · brightness proxy")
                    .font(.system(size: 11, weight: .heavy)).tracking(2)
                    .foregroundStyle(SO.lightAccent)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(SO.lightAccent.opacity(0.15)))
                Spacer()
                SOTickerBar(accent: SO.lightAccent, items: [
                    .init(label: "BRIGHT",  value: String(format: "%.0f%%", val * 100)),
                    .init(label: "EST LUX", value: String(format: "%.0f", val * 1000), accent: true),
                    .init(label: "MODE",    value: "EST"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct LightLamp: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        let val = env.screenBrightness
        SOVariant(sensor: "LIGHT", accent: SO.lightAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.18, green: 0.14, blue: 0.05),
                                    Color(red: 0.05, green: 0.04, blue: 0.0)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Lamp Metaphor")
                Spacer().frame(height: 30)
                lamp(level: val).frame(width: 280, height: 280)
                Spacer().frame(height: 18)
                Text(String(format: "%.0f%%", val * 100))
                    .font(.system(size: 80, weight: .semibold, design: .rounded))
                    .foregroundStyle(SO.lightAccent)
                    .shadow(color: SO.lightAccent, radius: 24)
                Spacer().frame(height: 110)
            }
        }
    }
    private func lamp(level: Double) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [SO.lightAccent.opacity(0.8 * level),
                                              SO.lightAccent.opacity(0)],
                                     center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 360, height: 360)
            Circle()
                .fill(SO.lightAccent.opacity(level))
                .frame(width: 140, height: 140)
                .shadow(color: SO.lightAccent, radius: 32)
            Circle()
                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                .frame(width: 140, height: 140)
        }
    }
}

private struct LightCamLux: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "LIGHT", accent: SO.lightAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Camera Luminance")
                Spacer().frame(height: 14)
                SOHero(text: "0xA8", size: 130, color: SO.lightAccent, glow: SO.lightAccent)
                SOTextLabel("FRONT-CAM AVG LUMA")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 26)
                SOLabel(text: "TRACE · 30 s · 5 Hz", size: 9).padding(.horizontal, 18)
                SOSpark(accent: SO.lightAccent, amp: 0.4, freq: 0.8)
                    .frame(height: 100).padding(.horizontal, 18).padding(.top, 6)
                Spacer()
                SOTickerBar(accent: SO.lightAccent, items: [
                    .init(label: "MIN",  value: "0x42"),
                    .init(label: "AVG",  value: "0xA8", accent: true),
                    .init(label: "MAX",  value: "0xF1"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 20 — PROXIMITY
// ════════════════════════════════════════════════════════════

struct SOProx: View {
    let variant: Int
    @EnvironmentObject var env: EnvironmentSensorManager
    var body: some View {
        switch variant {
        case 0: ProxRipple(env: env)
        case 1: ProxToggle(env: env)
        default: ProxEarpiece(env: env)
        }
    }
}

private struct ProxRipple: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "PROX", accent: SO.proxAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Proximity · ripple")
                Spacer().frame(height: 14)
                Text(env.proximityState ? "NEAR" : "FAR")
                    .font(.system(size: 80, weight: .heavy)).tracking(6)
                    .foregroundStyle(env.proximityState ? SO.proxAccent : .white.opacity(0.5))
                    .shadow(color: env.proximityState ? SO.proxAccent : .clear, radius: 24)
                Spacer().frame(height: 18)
                ripple.frame(width: 320, height: 280)
                Spacer()
                SOTickerBar(accent: SO.proxAccent, items: [
                    .init(label: "STATE",   value: env.proximityState ? "NEAR" : "FAR", accent: env.proximityState),
                    .init(label: "ENABLED", value: env.isProximityMonitoringEnabled ? "YES" : "NO"),
                    .init(label: "AVAIL",   value: "iPhone"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var ripple: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    let phase = (t * 0.5 + Double(i) * 0.4).truncatingRemainder(dividingBy: 2.5)
                    Circle()
                        .strokeBorder(SO.proxAccent.opacity(max(0, 1 - phase / 2.5)), lineWidth: 2)
                        .frame(width: CGFloat(80 + phase * 90),
                               height: CGFloat(80 + phase * 90))
                }
                Circle().fill(SO.proxAccent.opacity(0.3)).frame(width: 80, height: 80)
                Image(systemName: "ear.fill").font(.system(size: 48))
                    .foregroundStyle(SO.proxAccent)
            }
        }
    }
}

private struct ProxToggle: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "PROX", accent: SO.proxAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "NEAR / FAR · scoreboard")
                Spacer().frame(height: 18)
                HStack(spacing: 0) {
                    panel("NEAR", count: 12, active: env.proximityState)
                    panel("FAR",  count: 31, active: !env.proximityState)
                }
                .padding(.horizontal, 18)
                Spacer().frame(height: 18)
                SOLabel(text: "TRANSITION · last 5 min", size: 9).padding(.horizontal, 18)
                transitionBar.frame(height: 36).padding(.horizontal, 18).padding(.top, 8)
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private func panel(_ l: String, count: Int, active: Bool) -> some View {
        VStack(spacing: 8) {
            SOLabel(text: l, size: 12, opacity: active ? 1 : 0.4)
            Text("\(count)")
                .font(.system(size: 96, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(active ? SO.proxAccent : .white.opacity(0.3))
                .shadow(color: active ? SO.proxAccent : .clear, radius: 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.white.opacity(active ? 0.06 : 0.02))
        .cornerRadius(14)
    }
    private var transitionBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<60, id: \.self) { i in
                Rectangle()
                    .fill(i % 8 < 3 ? SO.proxAccent : Color.white.opacity(0.1))
                    .frame(width: 4)
            }
        }
    }
}

private struct ProxEarpiece: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "PROX", accent: SO.proxAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Time near earpiece")
                Spacer().frame(height: 14)
                Text("00:14:32")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("HH:MM:SS").font(.system(size: 11, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer().frame(height: 24)
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 140, weight: .light))
                    .foregroundStyle(SO.proxAccent)
                    .shadow(color: SO.proxAccent, radius: 18)
                Spacer()
                SOTickerBar(accent: SO.proxAccent, items: [
                    .init(label: "EVENTS", value: "12"),
                    .init(label: "AVG",    value: "01:12"),
                    .init(label: "TOTAL",  value: "00:14:32", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 21 — TORCH
// ════════════════════════════════════════════════════════════

struct SOTorch: View {
    let variant: Int
    @EnvironmentObject var cam: CameraSensorManager
    var body: some View {
        switch variant {
        case 0: TorchSwitch(cam: cam)
        case 1: TorchLighthouse(cam: cam)
        default: TorchColorTemp(cam: cam)
        }
    }
}

private struct TorchSwitch: View {
    @ObservedObject var cam: CameraSensorManager
    var body: some View {
        SOVariant(sensor: "TORCH", accent: SO.torchAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Torch Level")
                Spacer().frame(height: 14)
                Text(String(format: "%.0f%%", cam.torchLevel * 100))
                    .font(.system(size: 110, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer().frame(height: 18)
                slider(level: Double(cam.torchLevel)).frame(width: 80, height: 280)
                Spacer().frame(height: 18)
                Text(cam.torchLevel > 0 ? "ON" : "OFF")
                    .font(.system(size: 18, weight: .heavy)).tracking(3)
                    .foregroundStyle(cam.torchLevel > 0 ? SO.torchAccent : .white.opacity(0.4))
                Spacer().frame(height: 110)
            }
        }
    }
    private func slider(level: Double) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.04)))
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [SO.torchAccent, SO.torchAccent.opacity(0.6)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: max(20, 280 * level))
                .padding(8)
                .shadow(color: SO.torchAccent, radius: 18)
            // ticks
            VStack(spacing: 0) {
                ForEach(0..<11, id: \.self) { _ in
                    Rectangle().fill(.white.opacity(0.4)).frame(height: 1).frame(maxWidth: 16, alignment: .trailing)
                    if true { Spacer() }
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: 80, alignment: .trailing)
            .offset(x: 38)
        }
    }
}

private struct TorchLighthouse: View {
    @ObservedObject var cam: CameraSensorManager
    var body: some View {
        SOVariant(sensor: "TORCH", accent: SO.torchAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.05, green: 0.04, blue: 0.0),
                                    Color(red: 0.0, green: 0.0, blue: 0.0)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Lighthouse · pattern")
                Spacer().frame(height: 18)
                lighthouse.frame(width: 280, height: 320)
                Spacer().frame(height: 14)
                SOTextLabel("SOS · MORSE")
                    .font(.system(size: 16, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.torchAccent)
                HStack(spacing: 6) {
                    ForEach(["S","O","S"], id: \.self) { c in
                        Text(c)
                            .font(.system(size: 12, weight: .heavy))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(SO.torchAccent.opacity(0.2)))
                            .foregroundStyle(SO.torchAccent)
                    }
                }
                .padding(.top, 8)
                Spacer().frame(height: 110)
            }
        }
    }
    private var lighthouse: some View {
        SOTick { t in
            ZStack {
                // Beam cone
                Path { p in
                    p.move(to: .init(x: 140, y: 160))
                    p.addArc(center: .init(x: 140, y: 160), radius: 200,
                             startAngle: .degrees(-105), endAngle: .degrees(-75),
                             clockwise: false)
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [SO.torchAccent.opacity(0.6), SO.torchAccent.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(t * 60))
                Image(systemName: "flashlight.on.fill")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(SO.torchAccent)
                    .shadow(color: SO.torchAccent, radius: 18)
            }
        }
    }
}

private struct TorchColorTemp: View {
    @ObservedObject var cam: CameraSensorManager
    @State private var temp: Double = 5500
    var body: some View {
        SOVariant(sensor: "TORCH", accent: SO.torchAccent, bg: .custom(
            LinearGradient(colors: [colorForTemp(temp).opacity(0.4),
                                    .black],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Color Temperature · screen fill")
                Spacer().frame(height: 14)
                Text("\(Int(temp))K")
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer().frame(height: 18)
                Rectangle()
                    .fill(colorForTemp(temp))
                    .frame(width: 280, height: 280)
                    .cornerRadius(20)
                    .shadow(color: colorForTemp(temp), radius: 32)
                Spacer().frame(height: 18)
                tempSlider
                Spacer().frame(height: 110)
            }
        }
    }
    private var tempSlider: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(stride(from: 2000, through: 8000, by: 500).map { Double($0) }, id: \.self) { k in
                    Rectangle().fill(colorForTemp(k))
                        .frame(width: 22, height: 16)
                        .overlay(Rectangle().strokeBorder(k == temp ? .white : .clear, lineWidth: 2))
                        .onTapGesture { temp = k }
                }
            }
            SOTextLabel("warmer · cooler")
                .font(.system(size: 9, weight: .heavy)).tracking(2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
    private func colorForTemp(_ k: Double) -> Color {
        let n = (k - 2000) / 6000
        return Color(red: 1.0 - n * 0.2,
                     green: 0.7 + n * 0.3,
                     blue: 0.4 + n * 0.6)
    }
}
