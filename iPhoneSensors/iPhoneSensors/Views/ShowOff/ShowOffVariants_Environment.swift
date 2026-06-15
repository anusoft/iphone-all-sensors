import SwiftUI

// ════════════════════════════════════════════════════════════
// Sensor 05 — MAGNETOMETER
// ════════════════════════════════════════════════════════════

struct SOMag: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: MagStrength(motion: motion)
        case 1: MagFieldAR(motion: motion)
        case 2: MagMetalDetector(motion: motion)
        default: MagVector(motion: motion)
        }
    }
}

private struct MagStrength: View {
    @ObservedObject var motion: MotionSensorManager
    @EnvironmentObject private var locManager: LocalizationManager
    private var mag: Double {
        let x = motion.magX, y = motion.magY, z = motion.magZ
        return sqrt(x*x + y*y + z*z)
    }
    var body: some View {
        SOVariant(sensor: "MAG", accent: SO.magAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Field Strength · μT")
                Spacer().frame(height: 16)
                SORadialGauge(value: min(1, mag / 100),
                              label: "magnitude",
                              valueText: String(format: "%.1f", mag),
                              accent: SO.magAccent, ticks: 16, size: 260)
                Spacer().frame(height: 12)
                SOTextLabel("CALIBRATED")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(SO.magAccent)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(SO.magAccent.opacity(0.15)))
                Spacer()
                SOTickerBar(accent: SO.magAccent, items: [
                    .init(label: "X", value: String(format: "%+.1f", motion.magX)),
                    .init(label: "Y", value: String(format: "%+.1f", motion.magY)),
                    .init(label: "Z", value: String(format: "%+.1f", motion.magZ), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct MagFieldAR: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MAG", accent: SO.magAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.05, green: 0.02, blue: 0.10),
                                    Color(red: 0.02, green: 0.0, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Magnetic Ghosts · AR")
                Spacer().frame(height: 20)
                fieldGhosts.frame(width: 320, height: 360)
                Spacer().frame(height: 16)
                SOLabel(text: "FIELD VIZ", size: 9)
                SOTextLabel("Hold and rotate to scan")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
                Spacer().frame(height: 110)
            }
        }
    }
    private var fieldGhosts: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    let phase = Double(i) * 0.6 + t * 0.5
                    Circle()
                        .strokeBorder(SO.magAccent.opacity(0.18 + 0.05 * sin(phase)),
                                      lineWidth: 1.5)
                        .frame(width: CGFloat(60 + i * 28),
                               height: CGFloat(60 + i * 28))
                        .blur(radius: 0.5)
                }
                ForEach(0..<8, id: \.self) { i in
                    let a = Double(i) * 45 + t * 30
                    let r = 130.0 + sin(t + Double(i)) * 15
                    Circle()
                        .fill(SO.magAccent)
                        .frame(width: 6, height: 6)
                        .shadow(color: SO.magAccent, radius: 8)
                        .offset(x: CGFloat(r * cos(a * .pi / 180)),
                                y: CGFloat(r * sin(a * .pi / 180)))
                }
            }
        }
    }
}

private struct MagMetalDetector: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        let mag = sqrt(motion.magX*motion.magX + motion.magY*motion.magY + motion.magZ*motion.magZ)
        let delta = max(0, mag - 50)
        SOVariant(sensor: "MAG", accent: SO.magAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Metal Detector · ΔμT")
                SOHero(text: String(format: "%.0f", delta), size: 140, color: .white)
                    .padding(.top, 8)
                Spacer().frame(height: 18)
                detectorBars(level: min(1, delta / 30))
                Spacer().frame(height: 14)
                tone(delta: delta)
                Spacer()
                SOTickerBar(accent: SO.magAccent, items: [
                    .init(label: "BASE",  value: "50.0"),
                    .init(label: "DELTA", value: String(format: "%+.1f", delta), accent: delta > 5),
                    .init(label: "TONE",  value: "\(220 + Int(delta * 40)) Hz"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private func detectorBars(level: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<24, id: \.self) { i in
                let active = Double(i) / 24 < level
                Capsule()
                    .fill(active ? SO.magAccent : Color.white.opacity(0.08))
                    .frame(width: 12, height: 26 + CGFloat(i) * 1.5)
                    .shadow(color: active ? SO.magAccent : .clear, radius: 6)
            }
        }
        .padding(.horizontal, 18)
    }
    private func tone(delta: Double) -> some View {
        SOSpark(accent: SO.magAccent, amp: 0.5 + delta / 30, freq: 0.5 + delta / 10)
            .frame(height: 60)
            .padding(.horizontal, 18)
    }
}

private struct MagVector: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MAG", accent: SO.magAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "3-Axis Vector Decomposition")
                Spacer().frame(height: 20)
                vectorView.frame(width: 280, height: 280)
                Spacer().frame(height: 16)
                Group {
                    axisRow("X", motion.magX, color: .red)
                    axisRow("Y", motion.magY, color: .green)
                    axisRow("Z", motion.magZ, color: SO.magAccent)
                }
                .padding(.horizontal, 30)
                Spacer().frame(height: 110)
            }
        }
    }
    private var vectorView: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(.white.opacity(0.06))
                    .frame(width: 200, height: 1)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            // 3D-ish projected axes
            arrow(angle: -45, length: motion.magX * 2, color: .red)
            arrow(angle: 90, length: motion.magY * 2, color: .green)
            arrow(angle: 180, length: motion.magZ * 2, color: SO.magAccent)
        }
    }
    private func arrow(angle: Double, length: Double, color: Color) -> some View {
        let len = min(120, max(20, abs(length)))
        return Rectangle().fill(color)
            .frame(width: 3, height: CGFloat(len))
            .shadow(color: color, radius: 6)
            .offset(y: -CGFloat(len) / 2)
            .rotationEffect(.degrees(angle))
    }
    private func axisRow(_ l: String, _ v: Double, color: Color) -> some View {
        HStack {
            Text(l).font(.system(size: 11, weight: .heavy)).foregroundStyle(color).frame(width: 18)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: max(2, CGFloat(min(1, abs(v) / 100)) * geo.size.width))
                }
            }
            .frame(height: 8)
            Text(String(format: "%+.1f μT", v))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white).frame(width: 96, alignment: .trailing)
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 06 — DEVICE MOTION
// ════════════════════════════════════════════════════════════

struct SODeviceMotion: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: MotionFlight(motion: motion)
        case 1: Motion3DPhone(motion: motion)
        case 2: MotionGravity(motion: motion)
        default: MotionQuat(motion: motion)
        }
    }
}

private struct MotionFlight: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MOTION", accent: SO.motionAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Flight Horizon")
                Spacer().frame(height: 16)
                horizon.frame(width: 320, height: 280).clipShape(Circle())
                Spacer().frame(height: 18)
                HStack {
                    metric("PITCH", motion.pitch * 180 / .pi)
                    Spacer()
                    metric("ROLL",  motion.roll  * 180 / .pi)
                    Spacer()
                    metric("YAW",   motion.yaw   * 180 / .pi)
                }
                .padding(.horizontal, 28)
                Spacer().frame(height: 110)
            }
        }
    }
    private var horizon: some View {
        ZStack {
            Rectangle().fill(LinearGradient(colors: [
                Color(red: 0.30, green: 0.55, blue: 0.78),
                Color(red: 0.30, green: 0.55, blue: 0.78),
                Color(red: 0.55, green: 0.40, blue: 0.20),
                Color(red: 0.55, green: 0.40, blue: 0.20)
            ], startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(motion.roll * 180 / .pi))
                .offset(y: CGFloat(motion.pitch) * 80)
            Rectangle().fill(.white.opacity(0.6)).frame(width: 320, height: 2)
            Triangle().fill(SO.motionAccent).frame(width: 16, height: 14).offset(y: -130)
            Rectangle().fill(.white).frame(width: 80, height: 3)
            Circle().fill(.white).frame(width: 8, height: 8)
        }
    }
    private func metric(_ l: String, _ v: Double) -> some View {
        VStack(spacing: 2) {
            SOLabel(text: l, size: 9)
            Text(String(format: "%+.0f°", v))
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundStyle(SO.motionAccent)
        }
    }
}

private struct Motion3DPhone: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MOTION", accent: SO.motionAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Live 3D · Rim Light")
                Spacer().frame(height: 30)
                phone.frame(width: 220, height: 320)
                Spacer().frame(height: 30)
                SOTickerBar(accent: SO.motionAccent, items: [
                    .init(label: "ROLL",  value: String(format: "%.1f°", motion.roll * 180 / .pi)),
                    .init(label: "PITCH", value: String(format: "%.1f°", motion.pitch * 180 / .pi)),
                    .init(label: "YAW",   value: String(format: "%.1f°", motion.yaw * 180 / .pi), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var phone: some View {
        let r = max(-45, min(45, motion.roll * 180 / .pi))
        let p = max(-45, min(45, motion.pitch * 180 / .pi))
        let y = motion.yaw * 180 / .pi
        return RoundedRectangle(cornerRadius: 28)
            .fill(LinearGradient(colors: [
                Color(white: 0.18), Color(white: 0.06)
            ], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(SO.motionAccent.opacity(0.6), lineWidth: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    .padding(8)
            )
            .shadow(color: SO.motionAccent.opacity(0.6), radius: 24)
            .rotation3DEffect(.degrees(p), axis: (1, 0, 0))
            .rotation3DEffect(.degrees(y), axis: (0, 1, 0))
            .rotation3DEffect(.degrees(r), axis: (0, 0, 1))
    }
}

private struct MotionGravity: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MOTION", accent: SO.motionAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Gravity Well")
                Spacer().frame(height: 24)
                ZStack {
                    Circle().strokeBorder(.white.opacity(0.06), lineWidth: 1)
                        .frame(width: 280, height: 280)
                    Circle().strokeBorder(.white.opacity(0.04), lineWidth: 1)
                        .frame(width: 200, height: 200)
                    let gx = max(-1, min(1, motion.gravX)) * 100
                    let gy = max(-1, min(1, motion.gravY)) * 100
                    Circle()
                        .fill(RadialGradient(colors: [SO.motionAccent.opacity(0.7),
                                                      SO.motionAccent.opacity(0)],
                                              center: .center, startRadius: 0, endRadius: 80))
                        .frame(width: 160, height: 160)
                        .offset(x: -CGFloat(gx), y: -CGFloat(gy))
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: SO.motionAccent, radius: 18)
                        .offset(x: -CGFloat(gx), y: -CGFloat(gy))
                }
                .frame(width: 320, height: 320)
                Spacer()
                SOTickerBar(accent: SO.motionAccent, items: [
                    .init(label: "Gx", value: String(format: "%+.2f", motion.gravX)),
                    .init(label: "Gy", value: String(format: "%+.2f", motion.gravY)),
                    .init(label: "Gz", value: String(format: "%+.2f", motion.gravZ), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct MotionQuat: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "MOTION", accent: SO.motionAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Quaternion · Trail")
                Spacer().frame(height: 16)
                quat.frame(width: 320, height: 280)
                Spacer().frame(height: 14)
                quaternionRow
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private var quat: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<32, id: \.self) { i in
                    let off = Double(i) * 0.18
                    let r = 90.0 + sin(t * 0.5 + off) * 30
                    let a = (t * 0.6 + off) * 50
                    let opacity = (32 - Double(i)) / 32
                    Circle()
                        .fill(SO.motionAccent.opacity(opacity * 0.8))
                        .frame(width: 8, height: 8)
                        .blur(radius: Double(i) * 0.1)
                        .offset(x: CGFloat(r * cos(a * .pi / 180)),
                                y: CGFloat(r * sin(a * .pi / 180)))
                }
            }
        }
    }
    private var quaternionRow: some View {
        HStack(spacing: 10) {
            qBlock("W", motion.quatW)
            qBlock("X", motion.quatX)
            qBlock("Y", motion.quatY)
            qBlock("Z", motion.quatZ)
        }
        .padding(.horizontal, 18)
    }
    private func qBlock(_ l: String, _ v: Double) -> some View {
        VStack(spacing: 2) {
            SOLabel(text: l, size: 8)
            Text(String(format: "%+.3f", v))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 07 — ALTIMETER
// ════════════════════════════════════════════════════════════

struct SOAlt: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    @EnvironmentObject var env: EnvironmentSensorManager
    @EnvironmentObject var loc: LocationSensorManager
    var body: some View {
        switch variant {
        case 0: AltTape(motion: motion)
        case 1: AltElevator(motion: motion)
        case 2: AltPressure(env: env)
        case 3: AltStairs(motion: motion)
        default: AltGeoAlt(loc: loc, motion: motion, env: env)
        }
    }
}

private struct AltTape: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ALT", accent: SO.altAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Relative Altitude · m")
                SOHero(text: String(format: "%+.1f", motion.relativeAltitude), size: 130, color: .white)
                    .padding(.top, 6)
                Spacer().frame(height: 16)
                altTape.frame(height: 240)
                Spacer()
                SOTickerBar(accent: SO.altAccent, items: [
                    .init(label: "RATE", value: "+0.4 m/s", accent: true),
                    .init(label: "MIN",  value: "-3.2 m"),
                    .init(label: "MAX",  value: "+12.1 m"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var altTape: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 8) {
                ForEach(-10...10, id: \.self) { tick in
                    HStack {
                        Text("\(tick * 5)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(tick % 2 == 0 ? 0.6 : 0.2))
                            .frame(width: 30, alignment: .trailing)
                        Rectangle().fill(.white.opacity(tick % 2 == 0 ? 0.3 : 0.1))
                            .frame(width: tick % 2 == 0 ? 60 : 40, height: 1)
                        Spacer()
                    }
                }
            }
            .offset(y: CGFloat(motion.relativeAltitude) * 4)
            .frame(maxWidth: .infinity)
            // Center marker
            HStack(spacing: 0) {
                Spacer()
                Triangle().fill(SO.altAccent).frame(width: 14, height: 12)
                    .rotationEffect(.degrees(-90))
                    .offset(x: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .clipped()
    }
}

private struct AltElevator: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ALT", accent: SO.altAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Elevator · Floors")
                Spacer().frame(height: 14)
                let floor = max(0, Int(motion.relativeAltitude / 3.0))
                HStack(alignment: .top, spacing: 4) {
                    ForEach(0..<3, id: \.self) { d in
                        digitTile("\(floor / Int(pow(10.0, Double(2-d))) % 10)")
                    }
                }
                .padding(.top, 4)
                SOTextLabel("FLOOR")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 12)
                Spacer().frame(height: 26)
                SOLabel(text: "ASCENT · m", size: 9)
                ProgressView(value: min(1.0, motion.relativeAltitude / 100))
                    .progressViewStyle(.linear)
                    .tint(SO.altAccent)
                    .frame(maxWidth: 280)
                    .padding(.top, 6)
                Spacer()
                SOTickerBar(accent: SO.altAccent, items: [
                    .init(label: "ALT", value: String(format: "%+.1f m", motion.relativeAltitude)),
                    .init(label: "FLR", value: "\(floor)", accent: true),
                    .init(label: "VEL", value: "+0.4"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private func digitTile(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 110, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(SO.altAccent)
            .frame(width: 72, height: 130)
            .background(.black.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(SO.altAccent.opacity(0.3), lineWidth: 1))
            .cornerRadius(8)
            .shadow(color: SO.altAccent.opacity(0.4), radius: 16)
    }
}

private struct AltPressure: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "ALT", accent: SO.altAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Pressure · kPa")
                Spacer().frame(height: 16)
                SORadialGauge(value: min(1, env.pressure / 110),
                              label: "kPa",
                              valueText: String(format: "%.1f", env.pressure),
                              accent: SO.altAccent, ticks: 18, size: 260)
                Spacer().frame(height: 14)
                SOLabel(text: "30 min trace", size: 9)
                SOSpark(accent: SO.altAccent, amp: 0.3, freq: 0.4)
                    .frame(height: 60).padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct AltStairs: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ALT", accent: SO.altAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Flights Climbed · today")
                SOHero(text: "\(motion.floorsAscended)", size: 160, color: SO.altAccent,
                       glow: SO.altAccent)
                    .padding(.top, 8)
                SOTextLabel("FLIGHTS UP")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 24)
                stairs.frame(width: 280, height: 200)
                Spacer()
                SOTickerBar(accent: SO.altAccent, items: [
                    .init(label: "UP",   value: "\(motion.floorsAscended)", accent: true),
                    .init(label: "DOWN", value: "\(motion.floorsDescended)"),
                    .init(label: "NET",  value: "\(motion.floorsAscended - motion.floorsDescended)"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var stairs: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<14, id: \.self) { i in
                Rectangle()
                    .fill(SO.altAccent.opacity(0.85 - Double(13 - i) * 0.04))
                    .frame(width: 16, height: CGFloat(20 + i * 12))
            }
        }
    }
}

private struct AltGeoAlt: View {
    @ObservedObject var loc: LocationSensorManager
    @ObservedObject var motion: MotionSensorManager
    @ObservedObject var env: EnvironmentSensorManager

    var body: some View {
        SOVariant(sensor: "ALT", accent: SO.altAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                SOHero(text: String(format: "%+.1f", loc.altitude), size: 96, color: SO.altAccent,
                       glow: SO.altAccent)
                SOTextLabel("METERS GPS")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)

                Spacer().frame(height: 28)

                HStack(spacing: 24) {
                    altColumn("GPS ALT", value: String(format: "%+.1f m", loc.altitude),
                              accent: true)
                    Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: 60)
                    altColumn("BARO ALT", value: String(format: "%+.1f m", motion.relativeAltitude),
                              accent: false)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                VStack(spacing: 12) {
                    SOLabel(text: "ACCURACY", size: 9)
                    HStack(spacing: 24) {
                        accColumn("HORIZONTAL", value: max(0, loc.horizontalAccuracy))
                        Rectangle().fill(.white.opacity(0.08)).frame(width: 1, height: 44)
                        accColumn("VERTICAL", value: max(0, loc.verticalAccuracy))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 24)

                VStack(spacing: 8) {
                    SOLabel(text: "LOCATION", size: 9)
                    HStack(spacing: 16) {
                        coordText(String(format: "%.6f° N", abs(loc.latitude)))
                        coordText(String(format: "%.6f° E", abs(loc.longitude)))
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                SOTickerBar(accent: SO.altAccent, items: [
                    .init(label: "PRESSURE", value: String(format: "%.1f kPa", motion.pressure)),
                    .init(label: "H.ACC",   value: accLabel(max(0, loc.horizontalAccuracy)),
                          accent: max(0, loc.horizontalAccuracy) < 10),
                    .init(label: "TREND",   value: trendLabel),
                ])
                .padding(.horizontal, 18)

                Spacer().frame(height: 110)
            }
        }
    }

    private func altColumn(_ label: String, value: String, accent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: label, size: 8, opacity: 0.6)
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(accent ? SO.altAccent : .white)
        }
    }

    private func accColumn(_ label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: label, size: 8, opacity: 0.6)
            HStack(spacing: 6) {
                Circle()
                    .fill(accColor(value))
                    .frame(width: 8, height: 8)
                    .shadow(color: accColor(value), radius: 4)
                Text(String(format: "%.1f m", value))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(accColor(value))
            }
        }
    }

    private func coordText(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 17, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.8))
    }

    private func accColor(_ v: Double) -> Color {
        if v < 5 { return .green }
        if v < 15 { return .yellow }
        return .red
    }

    private func accLabel(_ v: Double) -> String {
        if v < 5 { return "FINE" }
        if v < 15 { return "FAIR" }
        return "POOR"
    }

    private var trendLabel: String {
        if motion.relativeAltitude > 0.5 { return "↑" }
        if motion.relativeAltitude < -0.5 { return "↓" }
        return "—"
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 08 — BAROMETER
// ════════════════════════════════════════════════════════════

struct SOBaro: View {
    let variant: Int
    @EnvironmentObject var env: EnvironmentSensorManager
    var body: some View {
        switch variant {
        case 0: BaroStation(env: env)
        case 1: BaroStormGlass(env: env)
        default: BaroElev(env: env)
        }
    }
}

private struct BaroStation: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "BARO", accent: SO.baroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Weather Station · kPa")
                SOHero(text: String(format: "%.1f", env.pressure), size: 130, color: .white)
                    .padding(.top, 6)
                Spacer().frame(height: 14)
                rollingBand
                Spacer()
                HStack(spacing: 16) {
                    statBlock("HIGH", "102.4 kPa", color: SO.baroAccent)
                    statBlock("LOW",  "100.1 kPa", color: .white)
                    statBlock("Δ24H", "+0.6 kPa",  color: SO.baroAccent)
                }
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var rollingBand: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05))
                .frame(height: 100)
            SOSpark(accent: SO.baroAccent, amp: 0.4, freq: 0.6).padding(8)
            SOTextLabel("RISING").font(.system(size: 10, weight: .heavy)).tracking(1.5)
                .foregroundStyle(SO.baroAccent)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 18)
    }
    private func statBlock(_ l: String, _ v: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SOLabel(text: l, size: 9)
            Text(v).font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BaroStormGlass: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "BARO", accent: SO.baroAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.18),
                                    Color(red: 0.02, green: 0.04, blue: 0.08)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Storm Glass")
                Spacer().frame(height: 18)
                stormGlass.frame(width: 240, height: 360)
                Spacer().frame(height: 14)
                SOTextLabel("CLEAR · falling")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SO.baroAccent)
                Text(String(format: "%.1f kPa", env.pressure))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
                Spacer().frame(height: 110)
            }
        }
    }
    private var stormGlass: some View {
        SOTick { t in
            ZStack {
                RoundedRectangle(cornerRadius: 36).fill(
                    LinearGradient(colors: [Color(red: 0.20, green: 0.30, blue: 0.50).opacity(0.4),
                                            Color(red: 0.05, green: 0.10, blue: 0.25).opacity(0.7)],
                                   startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 36).strokeBorder(.white.opacity(0.2), lineWidth: 2))
                ForEach(0..<40, id: \.self) { i in
                    let phase = Double(i) * 0.28 + t * 0.5
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(x: CGFloat(sin(phase) * 80 + Double(i % 5 - 2) * 20),
                                y: CGFloat(((cos(phase * 0.6) + 1) * 140) - 140))
                        .blur(radius: 0.8)
                }
            }
        }
    }
}

private struct BaroElev: View {
    @ObservedObject var env: EnvironmentSensorManager
    var body: some View {
        SOVariant(sensor: "BARO", accent: SO.baroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Elevation Δ · barometric")
                SOHero(text: String(format: "%+.0f", env.relativeAltitude), size: 130, color: SO.baroAccent,
                       glow: SO.baroAccent)
                SOTextLabel("METERS")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 24)
                SOLabel(text: "PRESSURE · 30 min", size: 9).padding(.horizontal, 18)
                SOSpark(accent: SO.baroAccent, amp: 0.3, freq: 0.5)
                    .frame(height: 80).padding(.horizontal, 18).padding(.top, 6)
                Spacer()
                SOTickerBar(accent: SO.baroAccent, items: [
                    .init(label: "P (kPa)", value: String(format: "%.2f", env.pressure)),
                    .init(label: "ALT Δm",  value: String(format: "%+.1f", env.relativeAltitude), accent: true),
                    .init(label: "T0",      value: "0:00"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 09 — PEDOMETER
// ════════════════════════════════════════════════════════════

struct SOPed: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: PedBig(motion: motion)
        case 1: PedPace(motion: motion)
        case 2: PedStreak(motion: motion)
        default: PedStairmaster(motion: motion)
        }
    }
}

private struct PedBig: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "STEPS", accent: SO.pedAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Steps · today")
                Spacer().frame(height: 6)
                SOHero(text: "\(motion.steps)", size: 160, color: .white,
                       glow: SO.pedAccent.opacity(0.6))
                SOTextLabel("OF 10,000 GOAL")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 24)
                progressArc
                    .frame(width: 280, height: 280)
                Spacer().frame(height: 110)
            }
        }
    }
    private var progressArc: some View {
        let progress = min(1.0, Double(motion.steps) / 10000)
        return ZStack {
            Circle().strokeBorder(.white.opacity(0.06), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(SO.pedAccent, style: .init(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: SO.pedAccent, radius: 12)
            VStack(spacing: 4) {
                SOLabel(text: "DISTANCE", size: 9)
                Text(String(format: "%.2f km", motion.distance / 1000))
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
    }
}

private struct PedPace: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "STEPS", accent: SO.pedAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Pace · steps/min")
                Spacer().frame(height: 12)
                SORadialGauge(value: min(1, motion.cadence / 200),
                              label: "cadence",
                              valueText: String(format: "%.0f", motion.cadence * 60),
                              accent: SO.pedAccent, ticks: 16, size: 240)
                Spacer().frame(height: 14)
                Text(motion.isWalking ? "WALKING" : "STILL")
                    .font(.system(size: 14, weight: .heavy)).tracking(2)
                    .foregroundStyle(motion.isWalking ? SO.pedAccent : .white.opacity(0.4))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill((motion.isWalking ? SO.pedAccent : Color.white).opacity(0.15)))
                Spacer()
                SOTickerBar(accent: SO.pedAccent, items: [
                    .init(label: "STEPS", value: "\(motion.steps)"),
                    .init(label: "DIST",  value: String(format: "%.2f km", motion.distance / 1000), accent: true),
                    .init(label: "PACE",  value: String(format: "%.1f m/s", motion.pace)),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

private struct PedStreak: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "STEPS", accent: SO.pedAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "7-Day Streak")
                SOHero(text: "5", size: 160, color: SO.pedAccent, glow: SO.pedAccent)
                SOTextLabel("DAYS HIT GOAL")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 18)
                weekChart.frame(height: 140).padding(.horizontal, 18)
                Spacer()
                Spacer().frame(height: 110)
            }
        }
    }
    private var weekChart: some View {
        let vals: [Double] = [7800, 11200, 9500, 12100, 8400, 13800, Double(motion.steps)]
        let goal = 10000.0
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(vals.enumerated()), id: \.offset) { i, v in
                VStack(spacing: 4) {
                    Spacer()
                    let h = min(120, v / 13800 * 120)
                    Capsule()
                        .fill(v >= goal ? SO.pedAccent : Color.white.opacity(0.18))
                        .frame(height: max(4, h))
                    Text(["M","T","W","T","F","S","S"][i])
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }
}

private struct PedStairmaster: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "STEPS", accent: SO.pedAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Stairs · ascended")
                SOHero(text: "\(motion.floorsAscended)", size: 160, color: .white)
                SOTextLabel("FLIGHTS")
                    .font(.system(size: 12, weight: .heavy)).tracking(3)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 30)
                stairs.frame(width: 280, height: 220)
                Spacer().frame(height: 110)
            }
        }
    }
    private var stairs: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .fill(SO.pedAccent.opacity(0.85 - Double(9 - i) * 0.05))
                    .frame(width: 22, height: CGFloat(40 + i * 18))
                    .shadow(color: SO.pedAccent.opacity(0.4), radius: 8)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 10 — ACTIVITY
// ════════════════════════════════════════════════════════════

struct SOActivity: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: ActBadge(motion: motion)
        case 1: ActLifeLog(motion: motion)
        default: ActConfidence(motion: motion)
        }
    }
}

private struct ActBadge: View {
    @ObservedObject var motion: MotionSensorManager
    @EnvironmentObject private var locManager: LocalizationManager
    var body: some View {
        SOVariant(sensor: "ACTIVITY", accent: SO.activityAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Current Activity")
                Spacer().frame(height: 14)
                Image(systemName: iconFor(motion.activityState))
                    .font(.system(size: 200, weight: .light))
                    .foregroundStyle(SO.activityAccent)
                    .shadow(color: SO.activityAccent, radius: 24)
                Text(localizedActivityState.uppercased())
                    .font(.system(size: 36, weight: .heavy)).tracking(4)
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                SOTextLabel("HIGH CONFIDENCE")
                    .font(.system(size: 11, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.activityAccent)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(SO.activityAccent.opacity(0.15)))
                    .padding(.top, 6)
                Spacer().frame(height: 110)
            }
        }
    }
    private var localizedActivityState: String {
        motion.activityState
            .split(separator: ", ")
            .map { Translations.get(String($0), language: locManager.currentLanguage) }
            .joined(separator: ", ")
    }

    private func iconFor(_ s: String) -> String {
        switch s.lowercased() {
        case let v where v.contains("walk"):     return "figure.walk"
        case let v where v.contains("run"):      return "figure.run"
        case let v where v.contains("auto"):     return "car.fill"
        case let v where v.contains("cycl"):     return "bicycle"
        case let v where v.contains("station"):  return "figure.stand"
        default: return "questionmark.circle"
        }
    }
}

private struct ActLifeLog: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ACTIVITY", accent: SO.activityAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Life Log · today")
                Spacer().frame(height: 18)
                timeline
                    .frame(height: 320)
                    .padding(.horizontal, 18)
                Spacer()
                HStack(spacing: 14) {
                    legend("STAT", .gray)
                    legend("WALK", SO.activityAccent)
                    legend("RUN",  .orange)
                    legend("AUTO", .blue)
                }
                Spacer().frame(height: 110)
            }
        }
    }
    private var timeline: some View {
        let segments: [(start: Double, end: Double, color: Color, label: String)] = [
            (0,    6,  .gray,             "STAT"),
            (6,    8,  SO.activityAccent, "WALK"),
            (8,   10,  .blue,             "AUTO"),
            (10,  12,  .orange,           "RUN"),
            (12,  14,  SO.activityAccent, "WALK"),
            (14,  18,  .gray,             "STAT"),
            (18,  20,  SO.activityAccent, "WALK"),
            (20,  24,  .gray,             "STAT"),
        ]
        return VStack(spacing: 4) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                HStack(spacing: 10) {
                    Text(String(format: "%02.0f:00", seg.start))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 36, alignment: .trailing)
                    GeometryReader { geo in
                        Capsule().fill(seg.color)
                            .frame(width: geo.size.width * (seg.end - seg.start) / 4)
                            .shadow(color: seg.color.opacity(0.5), radius: 4)
                    }
                    .frame(height: 8)
                    Text(seg.label)
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(seg.color)
                        .frame(width: 36, alignment: .leading)
                }
            }
        }
    }
    private func legend(_ l: String, _ c: Color) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(c).frame(width: 12, height: 4)
            Text(l).font(.system(size: 9, weight: .heavy)).foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct ActConfidence: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ACTIVITY", accent: SO.activityAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Confidence Breakdown")
                Spacer().frame(height: 24)
                VStack(spacing: 18) {
                    confBar("STATIONARY",  0.18, color: .gray)
                    confBar("WALKING",     0.62, color: SO.activityAccent, accent: true)
                    confBar("RUNNING",     0.08, color: .orange)
                    confBar("AUTOMOTIVE",  0.12, color: .blue)
                }
                .padding(.horizontal, 18)
                Spacer()
                SOTextLabel("WINNER: WALKING")
                    .font(.system(size: 13, weight: .heavy)).tracking(3)
                    .foregroundStyle(SO.activityAccent)
                Spacer().frame(height: 110)
            }
        }
    }
    private func confBar(_ l: String, _ v: Double, color: Color, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(l).font(.system(size: 11, weight: .heavy)).tracking(1)
                    .foregroundStyle(color)
                Spacer()
                Text("\(Int(v * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * v)
                        .shadow(color: accent ? color : .clear, radius: 8)
                }
            }
            .frame(height: 14)
        }
    }
}
