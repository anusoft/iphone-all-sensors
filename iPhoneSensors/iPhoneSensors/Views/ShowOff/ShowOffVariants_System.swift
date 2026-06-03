import SwiftUI

// ════════════════════════════════════════════════════════════
// Sensor 11 — BATTERY
// ════════════════════════════════════════════════════════════

struct SOBattery: View {
    let variant: Int
    @EnvironmentObject var sys: SystemSensorManager
    var body: some View {
        switch variant {
        case 0: BatLiquid(sys: sys)
        case 1: BatRuntime(sys: sys)
        default: BatCharging(sys: sys)
        }
    }
}

private struct BatLiquid: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        let level = max(0, min(1, Double(sys.batteryLevel)))
        SOVariant(sensor: "BATTERY", accent: SO.battAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Charge · Liquid")
                Spacer().frame(height: 14)
                liquid(level: level).frame(width: 180, height: 360)
                Spacer().frame(height: 18)
                Text("\(Int(level * 100))")
                    .font(.system(size: 80, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                + Text("%")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 110)
            }
        }
    }
    private func liquid(level: Double) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 36)
                .strokeBorder(.white.opacity(0.2), lineWidth: 2)
            RoundedRectangle(cornerRadius: 36)
                .fill(.white.opacity(0.04))
            // Cap
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.15))
                .frame(width: 80, height: 16)
                .offset(y: -178)
            // Liquid
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(colors: [SO.battAccent, SO.battAccent.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(height: 340 * level)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .padding(.horizontal, 8)
                    .shadow(color: SO.battAccent.opacity(0.5), radius: 18)
                // Slosh waves
                SOTick(speed: 0.5) { t in
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .fill(SO.battAccent.opacity(0.3))
                                .frame(width: 18, height: 18)
                                .offset(y: sin(t + Double(i) * 0.7) * 4)
                        }
                    }
                    .offset(y: -340 * level + 6)
                }
            }
        }
    }
}

private struct BatRuntime: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        let level = max(0, min(1, Double(sys.batteryLevel)))
        SOVariant(sensor: "BATTERY", accent: SO.battAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Estimated Runtime")
                let hours = level * 12
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    SOHero(text: String(format: "%dh", Int(hours)), size: 130, color: .white)
                    Text(String(format: "%dm", Int((hours - Double(Int(hours))) * 60)))
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Text("REMAINING")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
                Spacer().frame(height: 28)
                SOLabel(text: "DISCHARGE · 60 min", size: 9).padding(.horizontal, 18)
                runtimeChart.frame(height: 100).padding(.horizontal, 18).padding(.top, 8)
                Spacer()
                SOTickerBar(accent: SO.battAccent, items: [
                    .init(label: "LEVEL", value: "\(Int(level * 100))%"),
                    .init(label: "RATE",  value: "-3%/h", accent: true),
                    .init(label: "STATE", value: stateText),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var runtimeChart: some View {
        SOSpark(accent: SO.battAccent, amp: 0.25, freq: 0.4)
    }
    private var stateText: String {
        switch sys.batteryState {
        case .charging:    return "CHARGING"
        case .full:        return "FULL"
        case .unplugged:   return "UNPLUG"
        default:           return "—"
        }
    }
}

private struct BatCharging: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "BATTERY", accent: SO.battAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.02, green: 0.10, blue: 0.04),
                                    Color(red: 0.0, green: 0.04, blue: 0.02)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Power Flow · Circuit")
                Spacer().frame(height: 30)
                circuit.frame(width: 320, height: 320)
                Spacer().frame(height: 14)
                Text("⚡ CHARGING")
                    .font(.system(size: 22, weight: .heavy)).tracking(2)
                    .foregroundStyle(SO.battAccent)
                    .shadow(color: SO.battAccent, radius: 12)
                Spacer()
                SOTickerBar(accent: SO.battAccent, items: [
                    .init(label: "LEVEL",   value: "\(Int(sys.batteryLevel * 100))%"),
                    .init(label: "TO FULL", value: "1h 24m"),
                    .init(label: "INPUT",   value: "20W USB-C", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var circuit: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let r = 60.0 + Double(i) * 25
                    Circle()
                        .strokeBorder(SO.battAccent.opacity(0.3), style: .init(lineWidth: 1, dash: [3, 6]))
                        .frame(width: r * 2, height: r * 2)
                        .rotationEffect(.degrees(t * (10 + Double(i) * 5)))
                }
                ForEach(0..<10, id: \.self) { i in
                    let phase = Double(i) * 0.6 + t * 1.2
                    let r = 100.0
                    Circle()
                        .fill(SO.battAccent)
                        .frame(width: 6, height: 6)
                        .shadow(color: SO.battAccent, radius: 8)
                        .offset(x: CGFloat(r * cos(phase)), y: CGFloat(r * sin(phase)))
                }
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(SO.battAccent)
                    .shadow(color: SO.battAccent, radius: 18)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 12 — THERMAL
// ════════════════════════════════════════════════════════════

struct SOThermal: View {
    let variant: Int
    @EnvironmentObject var sys: SystemSensorManager
    var body: some View {
        switch variant {
        case 0: ThermThermometer(sys: sys)
        case 1: ThermRadiator(sys: sys)
        default: ThermCooling(sys: sys)
        }
    }
}

private struct ThermThermometer: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        let level = thermalLevel(sys.thermalState)
        SOVariant(sensor: "THERMAL", accent: SO.thermAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Thermal · State")
                Spacer().frame(height: 18)
                thermometer(level: level).frame(width: 100, height: 360)
                Spacer().frame(height: 14)
                Text(stateText(sys.thermalState))
                    .font(.system(size: 36, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.thermAccent)
                    .shadow(color: SO.thermAccent, radius: 12)
                Text("ILLUSTRATIVE · iOS does not expose absolute °C")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
                Spacer().frame(height: 110)
            }
        }
    }
    private func thermometer(level: Double) -> some View {
        ZStack(alignment: .bottom) {
            // Glass tube
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 36, height: 280)
                Circle()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .offset(y: -8)
            }
            // Mercury
            VStack(spacing: 0) {
                Spacer()
                Capsule()
                    .fill(LinearGradient(colors: [SO.thermAccent.opacity(0.6),
                                                  SO.thermAccent],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 28, height: max(20, 270 * level))
                    .shadow(color: SO.thermAccent, radius: 10)
                Circle()
                    .fill(SO.thermAccent)
                    .frame(width: 50, height: 50)
                    .shadow(color: SO.thermAccent, radius: 16)
            }
            // Tick marks
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<11, id: \.self) { i in
                        Rectangle().fill(.white.opacity(0.4))
                            .frame(width: 12, height: 1)
                        if i < 10 { Spacer() }
                    }
                }
                .frame(height: 280)
                .offset(x: 30)
            }
        }
    }
    private func thermalLevel(_ s: ProcessInfo.ThermalState) -> Double {
        switch s {
        case .nominal:  return 0.20
        case .fair:     return 0.45
        case .serious:  return 0.70
        case .critical: return 0.92
        @unknown default: return 0.20
        }
    }
    private func stateText(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal:  return "NOMINAL"
        case .fair:     return "FAIR"
        case .serious:  return "SERIOUS"
        case .critical: return "CRITICAL"
        @unknown default: return "—"
        }
    }
}

private struct ThermRadiator: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "THERMAL", accent: SO.thermAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Heat Radiator · 8×8 grid")
                Spacer().frame(height: 18)
                radiator.frame(width: 320, height: 360)
                Spacer().frame(height: 14)
                let st = sys.thermalState
                Text(st == .nominal ? "STABLE" : st == .fair ? "WARM" : st == .serious ? "HOT" : "OVER")
                    .font(.system(size: 14, weight: .heavy)).tracking(2)
                    .foregroundStyle(SO.thermAccent)
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private var radiator: some View {
        SOTick { t in
            VStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<8, id: \.self) { col in
                            let phase = Double(row + col) * 0.5 + t * 0.7
                            let intensity = (sin(phase) + 1) / 2
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SO.thermAccent.opacity(0.2 + intensity * 0.7))
                                .frame(width: 36, height: 36)
                                .shadow(color: SO.thermAccent.opacity(intensity * 0.6),
                                        radius: 6)
                        }
                    }
                }
            }
        }
    }
}

private struct ThermCooling: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "THERMAL", accent: SO.thermAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Cooling Curve · 5 min")
                Spacer().frame(height: 14)
                Text(stateText(sys.thermalState))
                    .font(.system(size: 64, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.thermAccent)
                Spacer().frame(height: 14)
                stepTrace.frame(height: 200).padding(.horizontal, 18)
                Spacer()
                SOTickerBar(accent: SO.thermAccent, items: [
                    .init(label: "STATE",  value: stateText(sys.thermalState)),
                    .init(label: "POWER",  value: sys.isLowPowerModeEnabled ? "LOW" : "NORMAL"),
                    .init(label: "TREND",  value: "↘ COOLING", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var stepTrace: some View {
        Canvas { ctx, size in
            let steps: [Double] = [3, 3, 2, 2, 2, 1, 1, 1, 1, 0]
            let w = size.width / CGFloat(steps.count)
            var path = Path()
            for (i, s) in steps.enumerated() {
                let x = CGFloat(i) * w
                let y = size.height - CGFloat(s) / 3 * size.height
                if i == 0 { path.move(to: .init(x: x, y: y)) }
                path.addLine(to: .init(x: x + w, y: y))
                if i < steps.count - 1 {
                    let nextY = size.height - CGFloat(steps[i + 1]) / 3 * size.height
                    path.addLine(to: .init(x: x + w, y: nextY))
                }
            }
            ctx.stroke(path, with: .color(SO.thermAccent), lineWidth: 3)
        }
    }
    private func stateText(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal:  return "NOMINAL"
        case .fair:     return "FAIR"
        case .serious:  return "SERIOUS"
        case .critical: return "CRITICAL"
        @unknown default: return "—"
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 13 — DISK
// ════════════════════════════════════════════════════════════

struct SODisk: View {
    let variant: Int
    @EnvironmentObject var sys: SystemSensorManager
    var body: some View {
        switch variant {
        case 0: DiskWheel(sys: sys)
        case 1: DiskTicker(sys: sys)
        default: DiskBlueprint(sys: sys)
        }
    }
}

private struct DiskWheel: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "DISK", accent: SO.diskAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Storage · 4-segment")
                Spacer().frame(height: 14)
                let used = max(0.0001, Double(sys.usedDiskSpace))
                let total = max(used, Double(max(sys.totalDiskSpace, 1)))
                pieWheel(usedRatio: used / total).frame(width: 280, height: 280)
                Spacer().frame(height: 14)
                Text(sizeStr(sys.usedDiskSpace) + " / " + sizeStr(sys.totalDiskSpace))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 8) {
                    legendDot("System",   color: SO.diskAccent)
                    legendDot("Apps",     color: SO.diskAccent.opacity(0.7))
                    legendDot("Media",    color: SO.diskAccent.opacity(0.5))
                    legendDot("Free",     color: .white.opacity(0.2))
                }
                Spacer().frame(height: 110)
            }
        }
    }
    private func pieWheel(usedRatio: Double) -> some View {
        ZStack {
            // Background ring
            Circle().strokeBorder(.white.opacity(0.04), lineWidth: 60)
            // Used split into 3 segments
            let s1 = usedRatio * 0.45
            let s2 = s1 + usedRatio * 0.30
            let s3 = s2 + usedRatio * 0.25
            Circle().trim(from: 0, to: s1)
                .stroke(SO.diskAccent, lineWidth: 60)
                .rotationEffect(.degrees(-90))
            Circle().trim(from: s1, to: s2)
                .stroke(SO.diskAccent.opacity(0.7), lineWidth: 60)
                .rotationEffect(.degrees(-90))
            Circle().trim(from: s2, to: s3)
                .stroke(SO.diskAccent.opacity(0.5), lineWidth: 60)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(usedRatio * 100))%")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                SOLabel(text: "USED", size: 9)
            }
        }
    }
    private func legendDot(_ s: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(s).font(.system(size: 9, weight: .heavy)).foregroundStyle(.white.opacity(0.7))
        }
    }
    private func sizeStr(_ b: Int64) -> String {
        ByteCountFormatter().string(fromByteCount: b)
    }
}

private struct DiskTicker: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "DISK", accent: SO.diskAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Free Bytes · live")
                Spacer().frame(height: 14)
                Text("\(sys.freeDiskSpace)")
                    .font(.system(size: 56, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 14)
                Text(ByteCountFormatter().string(fromByteCount: sys.freeDiskSpace))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(SO.diskAccent)
                    .padding(.top, 4)
                Spacer().frame(height: 30)
                SOLabel(text: "FLICKER · 1 Hz", size: 9)
                Spacer()
                SOTickerBar(accent: SO.diskAccent, items: [
                    .init(label: "TOTAL", value: ByteCountFormatter().string(fromByteCount: sys.totalDiskSpace)),
                    .init(label: "USED",  value: ByteCountFormatter().string(fromByteCount: sys.usedDiskSpace)),
                    .init(label: "FREE",  value: ByteCountFormatter().string(fromByteCount: sys.freeDiskSpace), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct DiskBlueprint: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "DISK", accent: SO.diskAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.06, green: 0.10, blue: 0.18),
                                    Color(red: 0.02, green: 0.04, blue: 0.10)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Storage · Blueprint")
                Spacer().frame(height: 18)
                blueprint.frame(width: 320, height: 360)
                Spacer().frame(height: 14)
                Text(ByteCountFormatter().string(fromByteCount: sys.totalDiskSpace))
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SO.diskAccent)
                Spacer().frame(height: 110)
            }
        }
    }
    private var blueprint: some View {
        ZStack {
            // Grid lines
            Canvas { ctx, size in
                let step: CGFloat = 20
                ctx.opacity = 0.15
                var p = Path()
                var x: CGFloat = 0
                while x <= size.width { p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height)); x += step }
                var y: CGFloat = 0
                while y <= size.height { p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y)); y += step }
                ctx.stroke(p, with: .color(SO.diskAccent), lineWidth: 0.5)
            }
            // Boxes with dimensions
            VStack(spacing: 8) {
                bpBox("SYSTEM",   "98.2 GB", height: 80)
                bpBox("APPS",     "44.8 GB", height: 60)
                bpBox("MEDIA",    "32.4 GB", height: 50)
                bpBox("FREE",     "78.1 GB", height: 100, dashed: true)
            }
            .padding(20)
        }
    }
    private func bpBox(_ name: String, _ size: String, height: CGFloat, dashed: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(SO.diskAccent, style: .init(lineWidth: 1.5, dash: dashed ? [4, 3] : []))
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 11, weight: .heavy)).foregroundStyle(SO.diskAccent)
                    Text(size).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
        }
        .frame(height: height)
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 14 — MEMORY
// ════════════════════════════════════════════════════════════

struct SOMem: View {
    let variant: Int
    @EnvironmentObject var sys: SystemSensorManager
    var body: some View {
        switch variant {
        case 0: MemBars(sys: sys)
        case 1: MemMap(sys: sys)
        default: MemPressure(sys: sys)
        }
    }
}

private struct MemBars: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        let total = max(1, Double(sys.physicalMemory))
        let level = 0.42  // illustrative pressure
        SOVariant(sensor: "MEM", accent: SO.memAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Memory · Fuel Gauge")
                Spacer().frame(height: 18)
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        let on = Double(i) / 5 < level
                        RoundedRectangle(cornerRadius: 6)
                            .fill(on ? SO.memAccent : Color.white.opacity(0.06))
                            .frame(width: 50, height: 220)
                            .shadow(color: on ? SO.memAccent.opacity(0.6) : .clear, radius: 12)
                    }
                }
                Spacer().frame(height: 18)
                Text(ByteCountFormatter().string(fromByteCount: Int64(total * level)))
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("USED OF " + ByteCountFormatter().string(fromByteCount: Int64(total)))
                    .font(.system(size: 11, weight: .heavy)).tracking(2)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
                Spacer()
                SOTickerBar(accent: SO.memAccent, items: [
                    .init(label: "FREE",  value: ByteCountFormatter().string(fromByteCount: Int64(total * (1 - level))), accent: true),
                    .init(label: "USED",  value: ByteCountFormatter().string(fromByteCount: Int64(total * level))),
                    .init(label: "WIRED", value: "1.8 GB"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct MemMap: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "MEM", accent: SO.memAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Allocation Map · 32×32")
                Spacer().frame(height: 18)
                memMap.frame(width: 320, height: 320)
                Spacer().frame(height: 14)
                HStack(spacing: 8) {
                    legend("Active",  SO.memAccent)
                    legend("Wired",   .red)
                    legend("Free",    .white.opacity(0.2))
                }
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private var memMap: some View {
        VStack(spacing: 1) {
            ForEach(0..<32, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<32, id: \.self) { col in
                        let seed = (row * 32 + col) % 7
                        let color: Color = seed == 0 ? .red : seed < 3 ? SO.memAccent : seed < 5 ? SO.memAccent.opacity(0.4) : .white.opacity(0.04)
                        Rectangle().fill(color).frame(width: 9, height: 9)
                    }
                }
            }
        }
    }
    private func legend(_ s: String, _ c: Color) -> some View {
        HStack(spacing: 4) {
            Rectangle().fill(c).frame(width: 8, height: 8)
            Text(s).font(.system(size: 9, weight: .heavy)).foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct MemPressure: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "MEM", accent: SO.memAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Memory Pressure · ECG")
                Spacer().frame(height: 14)
                Text("NORMAL")
                    .font(.system(size: 36, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.memAccent)
                Spacer().frame(height: 14)
                ecg.frame(height: 200).padding(.horizontal, 18)
                Spacer()
                SOTickerBar(accent: SO.memAccent, items: [
                    .init(label: "WARN", value: "0"),
                    .init(label: "CRIT", value: "0"),
                    .init(label: "PEAK", value: "62%", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var ecg: some View {
        SOTick { t in
            Canvas { ctx, size in
                var p = Path()
                let n = 80
                for i in 0...n {
                    let x = CGFloat(i) / CGFloat(n) * size.width
                    let phase = Double(i) * 0.4 + t * 2
                    let pulse = abs(sin(phase)) > 0.97 ? 30.0 : 0.0
                    let y = size.height / 2 - CGFloat(pulse) + CGFloat(sin(phase * 0.3) * 8)
                    if i == 0 { p.move(to: .init(x: x, y: y)) }
                    else      { p.addLine(to: .init(x: x, y: y)) }
                }
                ctx.stroke(p, with: .color(SO.memAccent), lineWidth: 2)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 15 — PROCESSOR
// ════════════════════════════════════════════════════════════

struct SOCPU: View {
    let variant: Int
    @EnvironmentObject var sys: SystemSensorManager
    var body: some View {
        switch variant {
        case 0: CpuCoreGrid(sys: sys)
        case 1: CpuSpike(sys: sys)
        default: CpuThreadDance(sys: sys)
        }
    }
}

private struct CpuCoreGrid: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "CPU", accent: SO.cpuAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "\(sys.activeProcessorCount) Cores · per-core load")
                Spacer().frame(height: 18)
                grid.frame(width: 320, height: 320)
                Spacer().frame(height: 14)
                Text("4 EFFICIENCY · 4 PERFORMANCE")
                    .font(.system(size: 11, weight: .heavy)).tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                SOTickerBar(accent: SO.cpuAccent, items: [
                    .init(label: "ACTIVE", value: "\(sys.activeProcessorCount)"),
                    .init(label: "TOTAL",  value: "\(sys.processorCount)"),
                    .init(label: "AVG",    value: "42%", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var grid: some View {
        SOTick { t in
            VStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { col in
                            let i = row * 4 + col
                            let load = (sin(t + Double(i) * 0.7) + 1) / 2
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("C\(i)")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(.white.opacity(0.5))
                                    Spacer()
                                    Text("\(Int(load * 100))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(SO.cpuAccent)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.06))
                                        RoundedRectangle(cornerRadius: 3).fill(SO.cpuAccent)
                                            .frame(width: geo.size.width * load)
                                            .shadow(color: SO.cpuAccent, radius: 6)
                                    }
                                }
                                .frame(height: 10)
                            }
                            .padding(10)
                            .background(.white.opacity(0.04))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

private struct CpuSpike: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "CPU", accent: SO.cpuAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "CPU Load · 60 s trace")
                Spacer().frame(height: 8)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    SOHero(text: "42", size: 130, color: SO.cpuAccent, glow: SO.cpuAccent)
                    Text("%")
                        .font(.system(size: 50, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer().frame(height: 14)
                trace.frame(height: 200).padding(.horizontal, 18)
                Spacer()
                SOTickerBar(accent: SO.cpuAccent, items: [
                    .init(label: "AVG",  value: "42%"),
                    .init(label: "PEAK", value: "78%", accent: true),
                    .init(label: "THR",  value: "80%"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var trace: some View {
        ZStack {
            // Threshold line
            Path { p in
                p.move(to: .init(x: 0, y: 40))
                p.addLine(to: .init(x: 1000, y: 40))
            }
            .stroke(.red.opacity(0.4), style: .init(lineWidth: 1, dash: [3, 3]))
            SOSpark(accent: SO.cpuAccent, amp: 0.6, freq: 1.2)
        }
    }
}

private struct CpuThreadDance: View {
    @ObservedObject var sys: SystemSensorManager
    var body: some View {
        SOVariant(sensor: "CPU", accent: SO.cpuAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Thread Dance · orbital")
                Spacer().frame(height: 18)
                threads.frame(width: 320, height: 320)
                Spacer().frame(height: 18)
                Text("8 THREADS")
                    .font(.system(size: 14, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.cpuAccent)
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private var threads: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    let r = 60.0 + Double(i % 4) * 30
                    let phase = Double(i) * (2 * .pi / 8) + t * 1.2
                    Circle()
                        .strokeBorder(SO.cpuAccent.opacity(0.15), lineWidth: 1)
                        .frame(width: r * 2, height: r * 2)
                    Circle()
                        .fill(SO.cpuAccent)
                        .frame(width: 10, height: 10)
                        .shadow(color: SO.cpuAccent, radius: 8)
                        .offset(x: CGFloat(r * cos(phase)),
                                y: CGFloat(r * sin(phase)))
                    // trail
                    ForEach(0..<6, id: \.self) { k in
                        let p2 = phase - Double(k) * 0.05
                        Circle()
                            .fill(SO.cpuAccent.opacity(Double(6 - k) / 6 * 0.4))
                            .frame(width: 6, height: 6)
                            .offset(x: CGFloat(r * cos(p2)),
                                    y: CGFloat(r * sin(p2)))
                    }
                }
                Circle().fill(.white).frame(width: 10, height: 10)
                    .shadow(color: SO.cpuAccent, radius: 8)
            }
        }
    }
}
