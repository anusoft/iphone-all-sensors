import SwiftUI

// MARK: - Adaptive Layout Primitives
//
// One small set of size-class-aware containers used across every page so layout
// reflows fluidly from iPhone SE portrait up to iPad Pro landscape without any
// per-view hardcoded widths. See docs / CLAUDE.md adaptive-design rules.

/// Size-class-derived metrics shared by the adaptive/responsive layer.
/// Centralizing these keeps the iPhone constants and iPad scale factors in sync.
private enum AdaptiveLayoutMetrics {
    static let regularWidthCardScale: CGFloat = 1.25
    static let compactWidthPagePadding: CGFloat = 16
    static let regularWidthPagePadding: CGFloat = 24
    static let compactWidthSensorIconBox: CGFloat = 40
    static let regularWidthSensorIconBox: CGFloat = 56
    static let regularWidthGaugeScale: CGFloat = 1.55
    static let compactWidthChartHeight: CGFloat = 200
    static let regularWidthChartHeight: CGFloat = 320

    static func isRegularWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }

    static func pagePadding(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isRegularWidth(horizontalSizeClass) ? regularWidthPagePadding : compactWidthPagePadding
    }

    static func cardMinimumWidth(_ minWidth: CGFloat, for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        minWidth * (isRegularWidth(horizontalSizeClass) ? regularWidthCardScale : 1)
    }

    static func sensorIconBoxSize(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isRegularWidth(horizontalSizeClass) ? regularWidthSensorIconBox : compactWidthSensorIconBox
    }

    static func gaugeSize(_ size: CGFloat, for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        size * (isRegularWidth(horizontalSizeClass) ? regularWidthGaugeScale : 1)
    }

    static func chartHeight(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isRegularWidth(horizontalSizeClass) ? regularWidthChartHeight : compactWidthChartHeight
    }
}

/// A grid that collapses to a single column on narrow screens (iPhone portrait / SE)
/// and reflows into 2–4 columns as the available width grows (iPad, large-iPhone
/// landscape). Cards are top-aligned so heterogeneous card heights don't stretch
/// their row-mates. Drop-in replacement for a `VStack(spacing:)` of cards.
struct AdaptiveCardGrid<Content: View>: View {
    var minWidth: CGFloat
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(minWidth: CGFloat = 340, spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.minWidth = minWidth
        self.spacing = spacing
        self.content = content
    }

    // Wider cards on iPad so the enlarged (accessibility-size) text has room, while
    // still reflowing into multiple columns on the larger screen.
    private var effectiveMinimumWidth: CGFloat {
        AdaptiveLayoutMetrics.cardMinimumWidth(minWidth, for: horizontalSizeClass)
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: effectiveMinimumWidth), spacing: spacing, alignment: .top)],
            alignment: .center,
            spacing: spacing
        ) {
            content()
        }
    }
}

/// Lays its children out vertically in a `.compact` width environment (iPhone portrait)
/// and horizontally in a `.regular` one (iPad / large-iPhone landscape). Use for
/// naturally-paired blocks such as side-by-side gauges or summary tiles.
struct AdaptiveStack<Content: View>: View {
    var spacing: CGFloat
    var alignment: VerticalAlignment
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(spacing: CGFloat = 16, alignment: VerticalAlignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: alignment, spacing: spacing) { content() }
        } else {
            VStack(spacing: spacing) { content() }
        }
    }
}

/// Standard page wrapper for a `ScrollView`'s content: lets the content expand to fill
/// the container (`maxWidth: .infinity`) and applies consistent, size-class-aware padding.
/// Replaces the bespoke trailing `.padding()` on each page.
struct ResponsivePageModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(AdaptiveLayoutMetrics.pagePadding(for: horizontalSizeClass))
    }
}

extension View {
    /// Expands content to fill its container and applies adaptive page padding.
    func responsivePage() -> some View { modifier(ResponsivePageModifier()) }

    /// Forces a card to fill the width of its grid cell / column instead of sizing to
    /// its intrinsic content. Use on cards that don't already stretch (no inner `Spacer`).
    func adaptiveCardWidth() -> some View { frame(maxWidth: .infinity) }
}

struct SensorCard: View {
    let title: String
    let icon: String
    let value: String
    let unit: String
    let color: Color
    let isAvailable: Bool
    var isLoading: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var locManager: LocalizationManager

    private var iconBoxSize: CGFloat {
        AdaptiveLayoutMetrics.sensorIconBoxSize(for: horizontalSizeClass)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rounded square icon container
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: iconBoxSize, height: iconBoxSize)

                Image(systemName: icon)
                    .font(.system(size: iconBoxSize * 0.45, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(locManager.t("status.loading"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if value.isEmpty || value == "0" || value == "0.00" {
                        Text(locManager.t("status.waiting"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    } else {
                        Text(value)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if !isAvailable {
                Text(locManager.t("status.unavailable"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark 
                      ? Color.white.opacity(0.04)
                      : Color.white.opacity(0.6))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(colorScheme == .dark 
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.04),
                        lineWidth: 0.5)
        }
    }
}

struct GaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: value)
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ThreeAxisView: View {
    let x: Double
    let y: Double
    let z: Double
    let title: String
    let unit: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locManager: LocalizationManager

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            HStack(spacing: 20) {
                AxisValue(label: locManager.t("label.x"), value: x, unit: unit, color: .red)
                AxisValue(label: locManager.t("label.y"), value: y, unit: unit, color: .green)
                AxisValue(label: locManager.t("label.z"), value: z, unit: unit, color: .blue)
            }
        }
        .padding()
        .glassCard()
    }
}

struct AxisValue: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(String(format: "%.3f", value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    let icon: String?
    @Environment(\.colorScheme) var colorScheme

    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.9) : .primary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct CircularGauge: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    let color: Color
    let size: CGFloat
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(value: Double, maxValue: Double, title: String, unit: String, color: Color, size: CGFloat = 120) {
        self.value = value
        self.maxValue = maxValue
        self.title = title
        self.unit = unit
        self.color = color
        self.size = size
    }

    // Enlarge the gauge on iPad (regular width) so it fills the bigger panels.
    private var scaledSize: CGFloat {
        AdaptiveLayoutMetrics.gaugeSize(size, for: horizontalSizeClass)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: scaledSize * 0.08)
                Circle()
                    .trim(from: 0, to: min(abs(value) / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: scaledSize * 0.08, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: value)
                VStack(spacing: 2) {
                    Text(formatValue(value))
                        .font(.system(size: scaledSize * 0.2, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: scaledSize * 0.1))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: scaledSize, height: scaledSize)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.0f", v) }
        if v >= 100 { return String(format: "%.0f", v) }
        if v >= 10 { return String(format: "%.1f", v) }
        return String(format: "%.2f", v)
    }
}

struct ProgressCard: View {
    let title: String
    let value: Double
    let maxValue: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(formatValue(value)) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            ProgressView(value: min(value / maxValue, 1.0))
                .tint(color)
        }
        .padding()
        .glassCard(cornerRadius: 12)
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.0f", v) }
        if v >= 100 { return String(format: "%.0f", v) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Theme Backgrounds & Modifiers

struct AppBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    if colorScheme == .dark {
                        GeometryReader { geo in
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(red: 0.114, green: 0.227, blue: 0.369), location: 0.0),
                                    .init(color: Color(red: 0.039, green: 0.039, blue: 0.094), location: 0.55),
                                    .init(color: .black, location: 1.0)
                                ]),
                                center: .init(x: 0.3, y: 0.2),
                                startRadius: 0,
                                endRadius: geo.size.width * 1.2
                            )
                            .ignoresSafeArea()
                        }
                    } else {
                        Color(red: 0.941, green: 0.933, blue: 0.914)
                            .ignoresSafeArea()
                    }
                }
            }
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark 
                          ? Color.white.opacity(0.06)
                          : Color.white.opacity(0.7))
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(colorScheme == .dark 
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06),
                            lineWidth: 1)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct GlowIcon: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.35, style: .continuous)
                .fill(color.opacity(0.25))
                .frame(width: size, height: size)
                .blur(radius: size * 0.25)
            
            RoundedRectangle(cornerRadius: size * 0.35, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            RoundedRectangle(cornerRadius: size * 0.35, style: .continuous)
                .stroke(color.opacity(0.4), lineWidth: 1)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DashboardRowBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorScheme == .dark 
                          ? Color.white.opacity(0.04)
                          : Color.white.opacity(0.6))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(colorScheme == .dark 
                            ? Color.white.opacity(0.06)
                            : Color.black.opacity(0.04),
                            lineWidth: 0.5)
            }
    }
}

extension View {
    func dashboardRow() -> some View {
        modifier(DashboardRowBackground())
    }
}

// MARK: - Settings Toolbar Button

struct SettingsToolbarButton: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSettings = false

    var body: some View {
        Button(action: { showSettings = true }) {
            Image(systemName: "gear")
                .font(.system(size: 18, weight: .semibold))
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .environmentObject(locManager)
                .environmentObject(themeManager)
        }
    }
}

struct SettingsSheet: View {
    @EnvironmentObject var locManager: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("consentGivenAt") private var consentTimestamp: Double = 0
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(locManager.t("language.title"))) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(action: {
                            locManager.currentLanguage = lang
                        }) {
                            HStack {
                                Text(lang.flag)
                                    .font(.title3)
                                Text(lang.displayName)
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                Spacer()
                                if locManager.currentLanguage == lang {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section(header: Text(locManager.t("theme.title"))) {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            themeManager.currentTheme = theme
                        }) {
                            HStack {
                                Image(systemName: theme.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                Text(locManager.t("theme.\(theme.rawValue)"))
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                Spacer()
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text(locManager.t("privacy.dataPrivacy"))) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text(locManager.t("privacy.localProcessing"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text(locManager.t("privacy.noExternalServers"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text(locManager.t("privacy.noAnalytics"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text(locManager.t("privacy.noTracking"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text(locManager.t("privacy.manageConsent"))) {
                    Button(action: deleteAllData) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                                .frame(width: 28)
                            Text(locManager.t("privacy.deleteMyData"))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                    .alert(locManager.t("privacy.deleteMyData"), isPresented: $showDeleteConfirm) {
                        Button(locManager.t("button.clearAll"), role: .destructive, action: confirmDeleteAllData)
                        Button(locManager.t("permission.notNow"), role: .cancel) {}
                    } message: {
                        Text(locManager.t("privacy.deleteMyDataConfirm"))
                    }

                    let consentDate = Date(timeIntervalSince1970: consentTimestamp)
                    if consentTimestamp > 0 {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .foregroundStyle(.green)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text(locManager.t("privacy.consentHistory"))
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                Text("\(locManager.t("privacy.consentGivenAt")): \(consentDate.formatted())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                Section(header: Text(locManager.t("settings.privacy"))) {
                    Link(destination: URL(string: "https://1moby.com/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            Text(locManager.t("settings.privacy"))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(locManager.t("settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(locManager.t("button.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func deleteAllData() {
        showDeleteConfirm = true
    }

    private func confirmDeleteAllData() {
        // Delete all recordings
        SensorRecorder.shared.deleteAllRecordings()
        // Delete exported files
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let files = try? FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil) {
                for file in files {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
        // Clear alarm history if stored in UserDefaults
        UserDefaults.standard.removeObject(forKey: "seismometerAlarmHistory")
        // Note: consent timestamp is preserved for audit trail
        print("[Privacy] All user data deleted")
    }
}
import Foundation
import SwiftUI
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}

@MainActor
class SensorChartData: ObservableObject {
    @Published var dataPoints: [ChartDataPoint] = []
    @Published var isPaused = false
    private let maxPoints = 200
    
    func addPoint(x: Double, y: Double, z: Double) {
        guard !isPaused else { return }
        let point = ChartDataPoint(timestamp: Date(), x: x, y: y, z: z)
        dataPoints.append(point)
        if dataPoints.count > maxPoints {
            dataPoints.removeFirst(dataPoints.count - maxPoints)
        }
    }
    
    func clear() {
        dataPoints.removeAll()
    }
}

struct SensorChartView: View {
    @ObservedObject var chartData: SensorChartData
    let title: String
    let unit: String
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var locManager: LocalizationManager

    // Taller charts on iPad.
    private var chartHeight: CGFloat {
        AdaptiveLayoutMetrics.chartHeight(for: horizontalSizeClass)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                Spacer()
                Button(action: { chartData.isPaused.toggle() }) {
                    Image(systemName: chartData.isPaused ? "play.fill" : "pause.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            if chartData.dataPoints.isEmpty {
                Text(locManager.t("status.waiting"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(chartData.dataPoints) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("X", point.x)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Y", point.y)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Z", point.z)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .second, count: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, style: .time)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: chartHeight)
            }
            
            HStack(spacing: 20) {
                LegendItem(color: .red, label: "X")
                LegendItem(color: .green, label: "Y")
                LegendItem(color: .blue, label: "Z")
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassCard()
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SingleValueChartView: View {
    @ObservedObject var chartData: SensorChartData
    let title: String
    let unit: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var locManager: LocalizationManager

    // Taller charts on iPad.
    private var chartHeight: CGFloat {
        AdaptiveLayoutMetrics.chartHeight(for: horizontalSizeClass)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
            
            if chartData.dataPoints.isEmpty {
                Text(locManager.t("status.waiting"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: chartHeight)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(chartData.dataPoints) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.x)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.x)
                        )
                        .foregroundStyle(color.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: chartHeight)
            }
            
            HStack {
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassCard()
    }
}
