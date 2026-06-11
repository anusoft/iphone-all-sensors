//
//  ScreenshotHeroView.swift
//  iPhoneSensors
//
//  High-fidelity, deterministic marketing surfaces used to generate App Store
//  screenshots. Every page is driven by *static mock data* (no live sensors,
//  no permissions, no network) so captures are pixel-reproducible across runs
//  and machines.
//
//  Deep link entry point (registered scheme `allsensors` — see Info.plist):
//
//      allsensors://1moby.allsensors/screenshots/<page-name>
//
//  e.g.  allsensors://1moby.allsensors/screenshots/dashboard
//        allsensors://1moby.allsensors/screenshots/motion
//        allsensors://1moby.allsensors/screenshots/health
//        allsensors://1moby.allsensors/screenshots/environment
//        allsensors://1moby.allsensors/screenshots/logger
//
//  Routing is handled by `ScreenshotRouter` (injected at the app root) and the
//  `.onOpenURL` modifier in iPhoneSensorsApp. When a page is active, ContentView
//  renders this view full-screen instead of the normal tab UI.
//

import SwiftUI
import Charts

// MARK: - Deep Link Routing

/// The set of marketing pages that can be deep-linked for screenshot capture.
/// The raw value is the `<page-name>` path component in the deep link URL.
enum ScreenshotPage: String, CaseIterable, Identifiable {
    case dashboard
    case motion
    case health
    case environment
    case logger

    var id: String { rawValue }

    /// Tolerant initializer for the URL path component (case-insensitive,
    /// trims whitespace). Returns nil for unknown pages so the router can
    /// safely ignore malformed links.
    init?(pageName: String) {
        let key = pageName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.init(rawValue: key)
    }
}

/// Observable navigation target for screenshot deep links.
///
/// Inject one instance at the app root and call `handle(_:)` from `.onOpenURL`.
/// `activePage` is observed by `ContentView`; when non-nil the hero surface is
/// presented full-screen.
@MainActor
final class ScreenshotRouter: ObservableObject {
    /// The page currently requested for capture, or nil for normal app UI.
    @Published var activePage: ScreenshotPage?

    /// Canonical host: `<namespace>.<app>` derived from the bundle id
    /// `com.1moby.allsensors`. Matching is *advisory* — any host is accepted
    /// so the pipeline keeps working if the bundle id changes.
    static let canonicalHost = "1moby.allsensors"

    /// Parse and route a deep link of the form
    /// `allsensors://<namespace>.<app>/screenshots/<page-name>`.
    /// Silently ignores anything that does not conform.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "allsensors" else { return false }

        // pathComponents includes a leading "/" element — drop it and any empties.
        let parts = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        guard parts.first?.lowercased() == "screenshots",
              parts.count >= 2,
              let page = ScreenshotPage(pageName: parts[1]) else {
            return false
        }

        activePage = page
        return true
    }

    func dismiss() { activePage = nil }
}

// MARK: - Palette

/// Screenshot-local accent palette. Mirrors the app's accent usage but kept
/// self-contained so this file has no fragile coupling to shared constants.
private enum Hero {
    static let blue = Color.blue
    static let cyan = Color.cyan
    static let green = Color.green
    static let mint = Color.mint
    static let orange = Color.orange
    static let pink = Color.pink
    static let purple = Color.purple
    static let red = Color.red
    static let teal = Color.teal
    static let yellow = Color.yellow
    static let indigo = Color.indigo
}

// MARK: - Hero layout (iPad enlargement)

/// Root layout metrics for screenshot pages. Compact width keeps the original
/// iPhone capture exactly: scale 1 and no distributed gaps. Regular width uses
/// the tuned iPad scale and spreads shorter pages vertically.
private struct HeroLayout {
    static let compactWidth = HeroLayout(scale: 1, fillsAvailableHeight: false)
    static let regularWidth = HeroLayout(scale: 1.65, fillsAvailableHeight: true)

    static let pageSpacing: CGFloat = 18
    static let pageHorizontalPadding: CGFloat = 22
    static let pageTopPadding: CGFloat = 8
    static let pageBottomPadding: CGFloat = 28
    static let distributedGapMinLength: CGFloat = 16

    let scale: CGFloat
    let fillsAvailableHeight: Bool

    init(horizontalSizeClass: UserInterfaceSizeClass?) {
        self = horizontalSizeClass == .regular ? Self.regularWidth : Self.compactWidth
    }

    private init(scale: CGFloat, fillsAvailableHeight: Bool) {
        self.scale = scale
        self.fillsAvailableHeight = fillsAvailableHeight
    }

    func scaled(_ value: CGFloat) -> CGFloat { value * scale }
}

/// Multiplier every hero element applies to its fonts / panels / charts / paddings.
/// Cards keep `maxWidth: .infinity`, so only their content grows — panels still span
/// the full width.
private struct HeroScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
private struct HeroFillsAvailableHeightKey: EnvironmentKey { static let defaultValue = false }

extension EnvironmentValues {
    var heroScale: CGFloat {
        get { self[HeroScaleKey.self] }
        set { self[HeroScaleKey.self] = newValue }
    }

    var heroFillsAvailableHeight: Bool {
        get { self[HeroFillsAvailableHeightKey.self] }
        set { self[HeroFillsAvailableHeightKey.self] = newValue }
    }
}

// MARK: - Root

struct ScreenshotHeroView: View {
    let page: ScreenshotPage
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        let layout = HeroLayout(horizontalSizeClass: horizontalSizeClass)
        return ZStack {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: layout.scaled(HeroLayout.pageSpacing)) {
                        switch page {
                        case .dashboard:   HeroDashboardPage()
                        case .motion:      HeroMotionPage()
                        case .health:      HeroHealthPage()
                        case .environment: HeroEnvironmentPage()
                        case .logger:      HeroLoggerPage()
                        }
                    }
                    .padding(.horizontal, layout.scaled(HeroLayout.pageHorizontalPadding))
                    .padding(.top, layout.scaled(HeroLayout.pageTopPadding))
                    .padding(.bottom, layout.scaled(HeroLayout.pageBottomPadding))
                    .frame(minHeight: layout.fillsAvailableHeight ? geo.size.height : nil, alignment: .top)
                }
            }
        }
        .appBackground()
        .environment(\.heroScale, layout.scale)
        .environment(\.heroFillsAvailableHeight, layout.fillsAvailableHeight)
    }
}

// MARK: - Shared Building Blocks

private struct HeroHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 6 * scale) {
            HStack(spacing: 10 * scale) {
                Image(systemName: systemImage)
                    .font(.system(size: 15 * scale, weight: .bold))
                    .foregroundStyle(accent)
                Text(eyebrow.uppercased())
                    .font(.system(size: 13 * scale, weight: .bold))
                    .tracking(1.4 * scale)
                    .foregroundStyle(accent)
            }
            Text(title)
                .font(.system(size: 34 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(scheme == .dark ? .white : .black)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: 16 * scale, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6 * scale)
    }
}

private struct HeroStatTile: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let accent: Color
    var trend: String? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        .fill(accent.opacity(scheme == .dark ? 0.20 : 0.14))
                        .frame(width: 38 * scale, height: 38 * scale)
                    Image(systemName: icon)
                        .font(.system(size: 17 * scale, weight: .semibold))
                        .foregroundStyle(accent)
                }
                Spacer()
                if let trend {
                    HStack(spacing: 2 * scale) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9 * scale, weight: .bold))
                        Text(trend)
                            .font(.system(size: 11 * scale, weight: .bold))
                    }
                    .foregroundStyle(Hero.green)
                    .padding(.horizontal, 7 * scale)
                    .padding(.vertical, 3 * scale)
                    .background(Capsule().fill(Hero.green.opacity(0.15)))
                }
            }
            Text(title)
                .font(.system(size: 13 * scale, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3 * scale) {
                Text(value)
                    .font(.system(size: 26 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(scheme == .dark ? .white : .black)
                Text(unit)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }
}

private struct HeroPoint: Identifiable {
    let id = UUID()
    let t: Double
    let v: Double
}

private struct HeroSeries: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let points: [HeroPoint]

    /// Deterministic waveform: closed-form so captures never vary between runs.
    static func wave(name: String, color: Color, count: Int = 60,
                     amplitude: Double, frequency: Double, phase: Double,
                     baseline: Double = 0) -> HeroSeries {
        let pts = (0..<count).map { i -> HeroPoint in
            let x = Double(i)
            let v = baseline
                + amplitude * sin(frequency * x + phase)
                + amplitude * 0.32 * sin(frequency * 2.7 * x + phase * 0.5)
            return HeroPoint(t: x, v: v)
        }
        return HeroSeries(name: name, color: color, points: pts)
    }
}

private struct HeroPageGap: View {
    @Environment(\.heroFillsAvailableHeight) private var fillsAvailableHeight

    var body: some View {
        if fillsAvailableHeight {
            Spacer(minLength: HeroLayout.distributedGapMinLength)
        }
    }
}

private struct HeroPageGrid<Content: View>: View {
    let minimum: CGFloat
    var spacing: CGFloat = 12
    @ViewBuilder var content: () -> Content
    @Environment(\.heroScale) private var scale

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minimum * scale), spacing: spacing * scale)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing * scale) {
            content()
        }
    }
}

private struct HeroLineChart: View {
    let series: [HeroSeries]
    var height: CGFloat = 190
    var filled: Bool = true
    @Environment(\.heroScale) private var scale

    private var fillSeries: HeroSeries? { filled ? series.first : nil }
    private var chartMin: Double { series.flatMap { $0.points.map(\.v) }.min() ?? 0 }

    var body: some View {
        Chart {
            areaContent
            lineContent
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.gray.opacity(0.15))
                AxisValueLabel().font(.system(size: 10 * scale))
            }
        }
        .frame(height: height * scale)
        .glassCard(cornerRadius: 18)
    }

    @ChartContentBuilder
    private var lineContent: some ChartContent {
        ForEach(series) { s in
            ForEach(s.points) { p in
                LineMark(
                    x: .value("t", p.t),
                    y: .value("v", p.v),
                    series: .value("series", s.name)
                )
                .foregroundStyle(s.color)
                .lineStyle(StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
        }
    }

    @ChartContentBuilder
    private var areaContent: some ChartContent {
        if let s = fillSeries {
            ForEach(s.points) { p in
                AreaMark(
                    x: .value("t", p.t),
                    yStart: .value("min", chartMin),
                    yEnd: .value("v", p.v)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [s.color.opacity(0.28), s.color.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
    }
}

private struct HeroLegend: View {
    let items: [(String, Color)]
    @Environment(\.heroScale) private var scale
    var body: some View {
        HStack(spacing: 16 * scale) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 6 * scale) {
                    Circle().fill(item.1).frame(width: 9 * scale, height: 9 * scale)
                    Text(item.0)
                        .font(.system(size: 12 * scale, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct HeroRing: View {
    let progress: Double          // 0...1
    let accent: Color
    var lineWidth: CGFloat = 12
    var size: CGFloat = 116
    let centerTop: String
    let centerBottom: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.18), lineWidth: lineWidth * scale)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [accent.opacity(0.7), accent],
                                    center: .center),
                    style: StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(centerTop)
                    .font(.system(size: 24 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(scheme == .dark ? .white : .black)
                Text(centerBottom)
                    .font(.system(size: 11 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size * scale, height: size * scale)
    }
}

private struct HeroAxisBar: View {
    let label: String
    let value: Double          // -1...1 normalized
    let color: Color
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale

    var body: some View {
        HStack(spacing: 12 * scale) {
            Text(label)
                .font(.system(size: 14 * scale, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 18 * scale, alignment: .leading)
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.14)).frame(height: 10 * scale)
                    Capsule()
                        .fill(color)
                        .frame(width: max(8, w * CGFloat(abs(value))), height: 10 * scale)
                }
                .frame(height: 10 * scale)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18 * scale)
            Text(String(format: "%+.2f", value))
                .font(.system(size: 13 * scale, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(scheme == .dark ? .white : .black)
                .frame(width: 58 * scale, alignment: .trailing)
        }
    }
}

private struct HeroSectionTitle: View {
    let text: String
    let systemImage: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale
    var body: some View {
        HStack(spacing: 8 * scale) {
            Image(systemName: systemImage)
                .font(.system(size: 13 * scale, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 15 * scale, weight: .semibold))
                .foregroundStyle(scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.8))
            Spacer()
        }
        .padding(.top, 2 * scale)
    }
}

// MARK: - Page: Dashboard

private struct HeroDashboardPage: View {
    var body: some View {
        HeroHeader(
            eyebrow: "All Sensors",
            title: "Every sensor.\nOne dashboard.",
            subtitle: "Live readings from 21 sensors — motion, location, environment, health and system, all in real time.",
            systemImage: "sensor.tag.radiowaves.forward",
            accent: Hero.blue
        )
        HeroPageGap()

        HeroLineChart(series: [
            .wave(name: "X", color: Hero.red, amplitude: 0.7, frequency: 0.42, phase: 0.0, baseline: 0.1),
            .wave(name: "Y", color: Hero.green, amplitude: 0.5, frequency: 0.36, phase: 1.6, baseline: 0.0),
            .wave(name: "Z", color: Hero.blue, amplitude: 0.4, frequency: 0.5, phase: 3.0, baseline: 0.98)
        ], height: 170)
        HeroLegend(items: [("Accel X", Hero.red), ("Accel Y", Hero.green), ("Accel Z", Hero.blue)])
        HeroPageGap()

        HeroPageGrid(minimum: 165) {
            HeroStatTile(icon: "gauge.with.dots.needle.67percent", title: "Accelerometer",
                         value: "0.98", unit: "G", accent: Hero.red)
            HeroStatTile(icon: "gyroscope", title: "Gyroscope",
                         value: "0.05", unit: "rad/s", accent: Hero.orange)
            HeroStatTile(icon: "location.fill", title: "GPS Fix",
                         value: "±4", unit: "m", accent: Hero.green, trend: "live")
            HeroStatTile(icon: "barometer", title: "Pressure",
                         value: "101.3", unit: "kPa", accent: Hero.cyan)
            HeroStatTile(icon: "heart.fill", title: "Heart Rate",
                         value: "72", unit: "BPM", accent: Hero.pink)
            HeroStatTile(icon: "battery.75", title: "Battery",
                         value: "85", unit: "%", accent: Hero.green)
        }
    }
}

// MARK: - Page: Motion

private struct HeroMotionPage: View {
    @Environment(\.heroScale) private var scale

    var body: some View {
        HeroHeader(
            eyebrow: "Motion",
            title: "Feel every\nmovement.",
            subtitle: "Accelerometer, gyroscope, and device-motion fused into smooth, high-rate visualizations.",
            systemImage: "move.3d",
            accent: Hero.orange
        )
        HeroPageGap()

        HeroLineChart(series: [
            .wave(name: "X", color: Hero.red, amplitude: 0.8, frequency: 0.5, phase: 0.0),
            .wave(name: "Y", color: Hero.green, amplitude: 0.6, frequency: 0.62, phase: 1.2),
            .wave(name: "Z", color: Hero.blue, amplitude: 0.55, frequency: 0.44, phase: 2.4)
        ], height: 200, filled: false)
        HeroLegend(items: [("X", Hero.red), ("Y", Hero.green), ("Z", Hero.blue)])
        HeroPageGap()

        HStack(spacing: 12 * scale) {
            HeroRing(progress: 0.62, accent: Hero.orange,
                     centerTop: "31°", centerBottom: "Roll")
            HeroRing(progress: 0.28, accent: Hero.purple,
                     centerTop: "14°", centerBottom: "Pitch")
            HeroRing(progress: 0.81, accent: Hero.teal,
                     centerTop: "146°", centerBottom: "Yaw")
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 18)
        HeroPageGap()

        VStack(spacing: 14 * scale) {
            HeroSectionTitle(text: "Accelerometer (G)", systemImage: "gauge.with.dots.needle.67percent")
            HeroAxisBar(label: "X", value: 0.62, color: Hero.red)
            HeroAxisBar(label: "Y", value: -0.18, color: Hero.green)
            HeroAxisBar(label: "Z", value: 0.97, color: Hero.blue)
        }
        .glassCard(cornerRadius: 18)
    }
}

// MARK: - Page: Health

private struct HeroHealthPage: View {
    @Environment(\.heroScale) private var scale

    var body: some View {
        HeroHeader(
            eyebrow: "Health",
            title: "Your vitals,\nvisualized.",
            subtitle: "Heart rate, HRV, blood oxygen and respiratory rate — straight from HealthKit, beautifully presented.",
            systemImage: "heart.text.square.fill",
            accent: Hero.pink
        )
        HeroPageGap()

        HStack(alignment: .center, spacing: 16 * scale) {
            HeroRing(progress: 0.72, accent: Hero.pink, lineWidth: 14, size: 132,
                     centerTop: "72", centerBottom: "BPM")
            VStack(alignment: .leading, spacing: 6 * scale) {
                Text("Heart Rate")
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Resting · Normal")
                    .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(Hero.pink)
                HStack(spacing: 4 * scale) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 11 * scale, weight: .bold))
                    Text("4 BPM below average")
                        .font(.system(size: 12 * scale, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .glassCard(cornerRadius: 18)
        HeroPageGap()

        HeroLineChart(series: [
            .wave(name: "HR", color: Hero.pink, amplitude: 8, frequency: 0.5, phase: 0.4, baseline: 72)
        ], height: 150)
        HeroPageGap()

        HeroPageGrid(minimum: 105) {
            HeroStatTile(icon: "waveform.path.ecg", title: "HRV", value: "58", unit: "ms", accent: Hero.purple)
            HeroStatTile(icon: "lungs.fill", title: "SpO₂", value: "98", unit: "%", accent: Hero.cyan)
            HeroStatTile(icon: "wind", title: "Resp.", value: "15", unit: "br/m", accent: Hero.teal)
        }
    }
}

// MARK: - Page: Environment

private struct HeroEnvironmentPage: View {
    @Environment(\.heroScale) private var scale

    var body: some View {
        HeroHeader(
            eyebrow: "Environment",
            title: "Sense the\nworld around you.",
            subtitle: "Barometric pressure, altitude, ambient light and proximity — your phone is a pocket weather station.",
            systemImage: "leaf.fill",
            accent: Hero.green
        )
        HeroPageGap()

        HStack(spacing: 12 * scale) {
            HeroRing(progress: 0.66, accent: Hero.cyan, lineWidth: 13, size: 124,
                     centerTop: "101.3", centerBottom: "kPa")
            VStack(alignment: .leading, spacing: 10 * scale) {
                HeroMiniStat(title: "Altitude", value: "128 m", icon: "mountain.2.fill", accent: Hero.mint)
                HeroMiniStat(title: "Brightness", value: "62 %", icon: "sun.max.fill", accent: Hero.yellow)
                HeroMiniStat(title: "Proximity", value: "Clear", icon: "hand.raised.fill", accent: Hero.indigo)
            }
            Spacer()
        }
        .glassCard(cornerRadius: 18)
        HeroPageGap()

        HeroLineChart(series: [
            .wave(name: "Pressure", color: Hero.cyan, amplitude: 0.4, frequency: 0.3, phase: 0.0, baseline: 101.3)
        ], height: 160)
        HeroPageGap()

        HeroPageGrid(minimum: 165) {
            HeroStatTile(icon: "thermometer.medium", title: "Rel. Altitude",
                         value: "+12.4", unit: "m", accent: Hero.mint)
            HeroStatTile(icon: "speaker.wave.2.fill", title: "Output Vol.",
                         value: "45", unit: "%", accent: Hero.purple)
        }
    }
}

private struct HeroMiniStat: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale
    var body: some View {
        HStack(spacing: 10 * scale) {
            Image(systemName: icon)
                .font(.system(size: 14 * scale, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 22 * scale)
            Text(title)
                .font(.system(size: 14 * scale, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15 * scale, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(scheme == .dark ? .white : .black)
        }
    }
}

// MARK: - Page: Logger

private struct HeroLoggerPage: View {
    @Environment(\.heroScale) private var scale

    var body: some View {
        HeroHeader(
            eyebrow: "Data Logger",
            title: "Record. Export.\nAnalyze.",
            subtitle: "Capture every sample to CSV, JSON or SQLite — then share full sessions for research and analysis.",
            systemImage: "record.circle.fill",
            accent: Hero.red
        )
        HeroPageGap()

        // Recording status banner
        HStack(spacing: 14 * scale) {
            ZStack {
                Circle().fill(Hero.red.opacity(0.18)).frame(width: 46 * scale, height: 46 * scale)
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 22 * scale, weight: .bold))
                    .foregroundStyle(Hero.red)
            }
            VStack(alignment: .leading, spacing: 3 * scale) {
                Text("Recording session")
                    .font(.system(size: 13 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("00:14:38")
                    .font(.system(size: 26 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3 * scale) {
                Text("142,907")
                    .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Hero.green)
                Text("samples")
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard(cornerRadius: 18)
        HeroPageGap()

        HeroLineChart(series: [
            .wave(name: "rate", color: Hero.green, amplitude: 6, frequency: 0.6, phase: 0.0, baseline: 50)
        ], height: 120)
        HeroPageGap()

        VStack(spacing: 0) {
            HeroSectionTitle(text: "Active streams", systemImage: "dot.radiowaves.left.and.right")
                .padding(.bottom, 6 * scale)
            HeroLoggerRow(name: "Accelerometer", format: "CSV", rate: "100 Hz", color: Hero.red)
            Divider().opacity(0.15)
            HeroLoggerRow(name: "Gyroscope", format: "CSV", rate: "100 Hz", color: Hero.orange)
            Divider().opacity(0.15)
            HeroLoggerRow(name: "Location", format: "JSON", rate: "1 Hz", color: Hero.green)
            Divider().opacity(0.15)
            HeroLoggerRow(name: "Barometer", format: "SQLite", rate: "10 Hz", color: Hero.cyan)
        }
        .glassCard(cornerRadius: 18)
        HeroPageGap()

        HStack(spacing: 12 * scale) {
            HeroExportChip(title: "CSV", icon: "tablecells", color: Hero.green)
            HeroExportChip(title: "JSON", icon: "curlybraces", color: Hero.orange)
            HeroExportChip(title: "SQLite", icon: "cylinder.split.1x2", color: Hero.blue)
        }
    }
}

private struct HeroLoggerRow: View {
    let name: String
    let format: String
    let rate: String
    let color: Color
    @Environment(\.colorScheme) private var scheme
    @Environment(\.heroScale) private var scale
    var body: some View {
        HStack(spacing: 12 * scale) {
            Circle().fill(color).frame(width: 9 * scale, height: 9 * scale)
            Text(name)
                .font(.system(size: 15 * scale, weight: .medium))
                .foregroundStyle(scheme == .dark ? .white : .black)
            Spacer()
            Text(rate)
                .font(.system(size: 12 * scale, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(format)
                .font(.system(size: 11 * scale, weight: .bold))
                .padding(.horizontal, 8 * scale).padding(.vertical, 3 * scale)
                .background(Capsule().fill(color.opacity(0.15)))
                .foregroundStyle(color)
        }
        .padding(.vertical, 9 * scale)
    }
}

private struct HeroExportChip: View {
    let title: String
    let icon: String
    let color: Color
    @Environment(\.heroScale) private var scale
    var body: some View {
        VStack(spacing: 6 * scale) {
            Image(systemName: icon)
                .font(.system(size: 18 * scale, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 13 * scale, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14 * scale)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Preview

#Preview("Dashboard") { ScreenshotHeroView(page: .dashboard) }
#Preview("Motion")    { ScreenshotHeroView(page: .motion) }
#Preview("Health")    { ScreenshotHeroView(page: .health) }
