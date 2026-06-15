import SwiftUI

// MARK: - Visual primitives shared by every Show-Off variant.
// Mirrors the design's `show-off-styles.css` and `show-off-primitives.jsx`.

enum SO {
    // Per-sensor accents from the design canvas.
    static let gpsAccent      = Color(red: 0xef/255.0, green: 0x44/255.0, blue: 0x44/255.0)
    static let headingAccent  = Color(red: 0xec/255.0, green: 0x48/255.0, blue: 0x99/255.0)
    static let accelAccent    = Color(red: 0x3b/255.0, green: 0x82/255.0, blue: 0xf6/255.0)
    static let gyroAccent     = Color(red: 0x63/255.0, green: 0x66/255.0, blue: 0xf1/255.0)
    static let magAccent      = Color(red: 0xa8/255.0, green: 0x55/255.0, blue: 0xf7/255.0)
    static let motionAccent   = Color(red: 0x08/255.0, green: 0x91/255.0, blue: 0xb2/255.0)
    static let altAccent      = Color(red: 0x14/255.0, green: 0xb8/255.0, blue: 0xa6/255.0)
    static let baroAccent     = Color(red: 0x0e/255.0, green: 0xa5/255.0, blue: 0xe9/255.0)
    static let pedAccent      = Color(red: 0xf5/255.0, green: 0x9e/255.0, blue: 0x0b/255.0)
    static let activityAccent = Color(red: 0x84/255.0, green: 0xcc/255.0, blue: 0x16/255.0)
    static let battAccent     = Color(red: 0x22/255.0, green: 0xc5/255.0, blue: 0x5e/255.0)
    static let thermAccent    = Color(red: 0xef/255.0, green: 0x44/255.0, blue: 0x44/255.0)
    static let diskAccent     = Color(red: 0xa1/255.0, green: 0x6d/255.0, blue: 0x4a/255.0)
    static let memAccent      = Color(red: 0xa8/255.0, green: 0x55/255.0, blue: 0xf7/255.0)
    static let cpuAccent      = Color(red: 0x3b/255.0, green: 0x82/255.0, blue: 0xf6/255.0)
    static let btAccent       = Color(red: 0x3b/255.0, green: 0x82/255.0, blue: 0xf6/255.0)
    static let netAccent      = Color(red: 0x06/255.0, green: 0xb6/255.0, blue: 0xd4/255.0)
    static let camAccent      = Color(red: 0x9c/255.0, green: 0xa3/255.0, blue: 0xaf/255.0)
    static let lightAccent    = Color(red: 0xfa/255.0, green: 0xcc/255.0, blue: 0x15/255.0)
    static let proxAccent     = Color(red: 0xd4/255.0, green: 0xd4/255.0, blue: 0xd8/255.0)
    static let torchAccent    = Color(red: 0xf9/255.0, green: 0x73/255.0, blue: 0x16/255.0)

    static let display = Font.system(size: 60, weight: .semibold, design: .rounded)
    static let mono    = Font.system(.body, design: .monospaced).weight(.semibold)
}

enum SOText {
    static func localized(_ text: String, language: AppLanguage) -> String {
        let key = Translations.showOffVariantKey(for: text)
        let localized = Translations.get(key, language: language)
        return localized == key ? text : localized
    }

    static func localizedFormat(_ format: String, language: AppLanguage, _ values: CVarArg...) -> String {
        localizedFormat(format, language: language, arguments: values)
    }

    static func localizedFormat(_ format: String, language: AppLanguage, arguments: [CVarArg]) -> String {
        let localized = localized(format, language: language)
        return String(format: localized, locale: Locale(identifier: language.rawValue), arguments: arguments)
    }
}

struct SOTextLabel: View {
    let text: String
    @EnvironmentObject private var locManager: LocalizationManager

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(SOText.localized(text, language: locManager.currentLanguage))
    }
}

struct SOFormattedTextLabel: View {
    let format: String
    let value: CVarArg
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        Text(SOText.localizedFormat(format, language: locManager.currentLanguage, arguments: [value]))
    }
}

struct SOFormattedText: View {
    let format: String
    let arguments: [CVarArg]
    @EnvironmentObject private var locManager: LocalizationManager

    init(_ format: String, _ arguments: CVarArg...) {
        self.format = format
        self.arguments = arguments
    }

    var body: some View {
        Text(SOText.localizedFormat(format, language: locManager.currentLanguage, arguments: arguments))
    }
}

// MARK: - Hero label (uppercase compact tracking)

struct SOLabel: View {
    let text: String
    var size: CGFloat = 10
    var opacity: Double = 0.55
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        Text(SOText.localized(text, language: locManager.currentLanguage).uppercased())
            .font(.system(size: size, weight: .semibold).width(.condensed))
            .tracking(size * 0.18)
            .foregroundStyle(.white.opacity(opacity))
    }
}

struct SOFormattedLabel: View {
    let format: String
    let value: CVarArg
    var size: CGFloat = 10
    var opacity: Double = 0.55
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        Text(SOText.localizedFormat(format, language: locManager.currentLanguage, arguments: [value]).uppercased())
            .font(.system(size: size, weight: .semibold).width(.condensed))
            .tracking(size * 0.18)
            .foregroundStyle(.white.opacity(opacity))
    }
}

// MARK: - Hero number — big rounded tabular display digit

struct SOHero: View {
    let text: String
    var size: CGFloat = 140
    var color: Color = .white
    var glow: Color? = nil
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .kerning(-size * 0.04)
            .foregroundStyle(color)
            .shadow(color: glow ?? .clear, radius: glow != nil ? 24 : 0)
    }
}

// MARK: - Mono value (tabular)

struct SOMono: View {
    let text: String
    var size: CGFloat = 13
    var color: Color = .white
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

// MARK: - Background gradient w/ accent tint + grid + noise

struct SOBackground: View {
    let accent: Color
    var style: Style = .gradient
    enum Style { case gradient, none, custom(LinearGradient) }

    var body: some View {
        ZStack {
            switch style {
            case .gradient:
                RadialGradient(
                    colors: [accent.opacity(0.22), Color(white: 0.02)],
                    center: .init(x: 0.5, y: 0.30),
                    startRadius: 0,
                    endRadius: 600
                )
                .ignoresSafeArea()
                .background(Color(white: 0.02).ignoresSafeArea())
                grid
            case .none:
                Color.black.ignoresSafeArea()
            case .custom(let g):
                g.ignoresSafeArea()
                grid
            }
            // subtle noise
            Rectangle()
                .fill(.white.opacity(0.02))
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
    }

    private var grid: some View {
        Canvas { ctx, size in
            let step: CGFloat = 24
            ctx.opacity = 0.04
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += step }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += step }
            ctx.stroke(path, with: .color(.white), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Floating chrome (top: close + sensor name + menu, bottom: variant pills)

struct SOChrome<Top: View, Bottom: View>: View {
    let onClose: () -> Void
    let onIndex: () -> Void
    let sensorName: String
    let bottom: Bottom
    let top: Top

    init(
        sensorName: String,
        onClose: @escaping () -> Void,
        onIndex: @escaping () -> Void,
        @ViewBuilder bottom: () -> Bottom = { EmptyView() },
        @ViewBuilder top: () -> Top = { EmptyView() }
    ) {
        self.sensorName = sensorName
        self.onClose = onClose
        self.onIndex = onIndex
        self.bottom = bottom()
        self.top = top()
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    chip(icon: "xmark")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(sensorName.uppercased())
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Button(action: onIndex) {
                    chip(icon: "square.grid.3x3.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            top

            Spacer()

            bottom
                .padding(.bottom, 10)
        }
    }

    private func chip(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 32, height: 32)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
    }
}

// MARK: - Variant pill stack — bottom of every screen

struct SOPills: View {
    let variants: [String]
    let active: Int
    let accent: Color
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(variants.enumerated()), id: \.offset) { i, v in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelect(i)
                } label: {
                    Text(v.uppercased())
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .tracking(1.0)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minHeight: 36)
                        .background(
                            Capsule().fill(i == active ? accent : Color.clear)
                        )
                        .foregroundStyle(i == active ? .white : .white.opacity(0.55))
                        .shadow(color: i == active ? accent.opacity(0.6) : .clear, radius: 12)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.black.opacity(0.35))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - Live ticker bar — fixed-width mono columns at bottom

struct SOTickerBar: View {
    struct Item { let label: String; let value: String; var accent: Bool = false }
    let accent: Color
    let items: [Item]
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 4) {
                    SOLabel(text: item.label, size: 8.5)
                    Text(item.value)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(item.accent ? accent : .white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.4))
            }
        }
        .background(.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - HUD bracket overlay

struct SOHUDFrame<Content: View>: View {
    let accent: Color
    @ViewBuilder let content: Content
    var body: some View {
        ZStack {
            content
            BracketOverlay(accent: accent)
        }
    }
    struct BracketOverlay: View {
        let accent: Color
        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    bracket(at: .init(x: 0, y: 0), corner: .tl)
                    bracket(at: .init(x: w - 18, y: 0), corner: .tr)
                    bracket(at: .init(x: 0, y: h - 18), corner: .bl)
                    bracket(at: .init(x: w - 18, y: h - 18), corner: .br)
                }
            }
            .allowsHitTesting(false)
        }
        enum Corner { case tl, tr, bl, br }
        @ViewBuilder
        private func bracket(at p: CGPoint, corner: Corner) -> some View {
            Path { path in
                switch corner {
                case .tl:
                    path.move(to: .init(x: 0, y: 18)); path.addLine(to: .init(x: 0, y: 0)); path.addLine(to: .init(x: 18, y: 0))
                case .tr:
                    path.move(to: .init(x: 0, y: 0)); path.addLine(to: .init(x: 18, y: 0)); path.addLine(to: .init(x: 18, y: 18))
                case .bl:
                    path.move(to: .init(x: 0, y: 0)); path.addLine(to: .init(x: 0, y: 18)); path.addLine(to: .init(x: 18, y: 18))
                case .br:
                    path.move(to: .init(x: 0, y: 18)); path.addLine(to: .init(x: 18, y: 18)); path.addLine(to: .init(x: 18, y: 0))
                }
            }
            .stroke(accent.opacity(0.7), lineWidth: 1.5)
            .frame(width: 18, height: 18)
            .position(x: p.x + 9, y: p.y + 9)
        }
    }
}

// MARK: - Live spark line (sin-wave fake liveness)

struct SOSpark: View {
    let accent: Color
    var amp: Double = 0.5
    var freq: Double = 1
    var phase: Double = 0

    private func makePath(in size: CGSize) -> Path {
        var path = Path()
        let n = 64
        let halfH = size.height / 2
        let span = halfH - 4
        for i in 0...n {
            let x = CGFloat(i) / CGFloat(n) * size.width
            let s1 = sin(Double(i) * 0.4 * freq + phase) * span * amp
            let s2 = sin(Double(i) * 0.13 * freq) * span * amp * 0.4
            let y = halfH + s1 + s2
            let pt = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        return path
    }

    var body: some View {
        Canvas { ctx, size in
            let path = makePath(in: size)
            var fill = path
            fill.addLine(to: .init(x: size.width, y: size.height))
            fill.addLine(to: .init(x: 0, y: size.height))
            fill.closeSubpath()
            let gradient = Gradient(colors: [accent.opacity(0.4), accent.opacity(0)])
            ctx.fill(fill, with: .linearGradient(gradient,
                                                 startPoint: .zero,
                                                 endPoint: .init(x: 0, y: size.height)))
            ctx.stroke(path, with: .color(accent), lineWidth: 1.5)
        }
    }
}

// MARK: - Radial gauge (270° arc)

struct SORadialGauge: View {
    let value: Double               // 0…1
    let label: String?
    let valueText: String?
    let accent: Color
    var ticks: Int = 12
    var size: CGFloat = 180
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        ZStack {
            Canvas { ctx, sz in
                let r = (sz.width - 16) / 2
                let center = CGPoint(x: sz.width/2, y: sz.height/2)
                let startA = -210.0
                let endA   = 30.0
                let sweepEnd = startA + (endA - startA) * value
                func arc(_ a1: Double, _ a2: Double) -> Path {
                    var p = Path()
                    p.addArc(center: center, radius: r,
                             startAngle: .degrees(a1),
                             endAngle: .degrees(a2),
                             clockwise: false)
                    return p
                }
                ctx.stroke(arc(startA, endA), with: .color(.white.opacity(0.08)), lineWidth: 2)
                ctx.stroke(arc(startA, sweepEnd), with: .color(accent),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
                for i in 0..<ticks {
                    let a = startA + (endA - startA) * Double(i) / Double(ticks - 1)
                    let rad = a * .pi / 180
                    let p1 = CGPoint(x: center.x + r * cos(rad), y: center.y + r * sin(rad))
                    let p2 = CGPoint(x: center.x + (r-8) * cos(rad), y: center.y + (r-8) * sin(rad))
                    var line = Path(); line.move(to: p1); line.addLine(to: p2)
                    ctx.stroke(line, with: .color(.white.opacity(0.3)), lineWidth: 1)
                }
            }
            .frame(width: size, height: size)
            VStack(spacing: 4) {
                if let valueText {
                    Text(valueText)
                        .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                if let label {
                    SOLabel(text: label, size: 9, opacity: 0.5)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Compass rose (rotating tick ring + cardinal labels)

struct SOCompassRose: View {
    let heading: Double
    let accent: Color
    var size: CGFloat = 220

    private struct TickCanvas: View {
        var body: some View {
            Canvas { ctx, sz in
                let cx = sz.width / 2
                let cy = sz.height / 2
                let r = sz.width / 2 - 4
                var outer = Path()
                outer.addEllipse(in: .init(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
                ctx.stroke(outer, with: .color(.white.opacity(0.08)), lineWidth: 1)
                var inner = Path()
                inner.addEllipse(in: .init(x: cx - (r - 12), y: cy - (r - 12), width: 2 * (r - 12), height: 2 * (r - 12)))
                ctx.stroke(inner, with: .color(.white.opacity(0.05)), lineWidth: 1)
                for i in 0..<72 {
                    let a = Double(i * 5) * .pi / 180.0
                    let innerR: CGFloat
                    if i % 6 == 0 { innerR = r - 14 }
                    else if i % 2 == 0 { innerR = r - 8 }
                    else { innerR = r - 5 }
                    let p1 = CGPoint(x: cx + (r - 1) * sin(a), y: cy - (r - 1) * cos(a))
                    let p2 = CGPoint(x: cx + innerR * sin(a), y: cy - innerR * cos(a))
                    var line = Path()
                    line.move(to: p1)
                    line.addLine(to: p2)
                    let major = i % 6 == 0
                    ctx.stroke(line,
                               with: .color(major ? .white.opacity(0.7) : .white.opacity(0.25)),
                               lineWidth: major ? 1.2 : 0.7)
                }
            }
        }
    }

    private struct Cardinal: View {
        let letter: String
        let deg: Double
        let size: CGFloat
        let heading: Double
        let accent: Color
        var body: some View {
            let a = deg * .pi / 180.0
            let r = size / 2 - 26
            let x = size / 2 + r * sin(a)
            let y = size / 2 - r * cos(a)
            Text(letter)
                .font(.system(size: 16, weight: .heavy).width(.condensed))
                .foregroundStyle(letter == "N" ? accent : .white)
                .position(x: x, y: y)
                .rotationEffect(.degrees(heading), anchor: .center)
        }
    }

    var body: some View {
        ZStack {
            ZStack {
                TickCanvas()
                Cardinal(letter: "N", deg: 0,   size: size, heading: heading, accent: accent)
                Cardinal(letter: "E", deg: 90,  size: size, heading: heading, accent: accent)
                Cardinal(letter: "S", deg: 180, size: size, heading: heading, accent: accent)
                Cardinal(letter: "W", deg: 270, size: size, heading: heading, accent: accent)
            }
            .rotationEffect(.degrees(-heading))
            .frame(width: size, height: size)
            Triangle()
                .fill(accent)
                .frame(width: 12, height: 12)
                .position(x: size / 2, y: 12)
        }
        .frame(width: size, height: size)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .init(x: rect.midX, y: rect.minY))
        p.addLine(to: .init(x: rect.minX, y: rect.maxY))
        p.addLine(to: .init(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Continuous tick driver. ~30fps tween to drive idle motion.

struct SOTick<Content: View>: View {
    @State private var t: Double = 0
    var speed: Double = 1.0
    @ViewBuilder var content: (Double) -> Content
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: false)) { tl in
            let now = tl.date.timeIntervalSinceReferenceDate * speed
            content(now)
        }
    }
}

// MARK: - Annotation sticky (yellow pill)

struct SOAnno: View {
    let text: String
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        Text(SOText.localized(text, language: locManager.currentLanguage))
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color(red: 1, green: 0.96, blue: 0.41))
            .foregroundStyle(Color(red: 0x2a/255.0, green: 0x24/255.0, blue: 0x10/255.0))
            .cornerRadius(3)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Variant scaffold — every show-off variant returns one of these.

struct SOVariant<Content: View>: View {
    let sensor: String
    let accent: Color
    var bg: SOBackground.Style = .gradient
    @ViewBuilder let content: Content
    var body: some View {
        ZStack {
            SOBackground(accent: accent, style: bg)
            content
        }
        .clipped()
    }
}
