import SwiftUI

// MARK: - Sensor registry: ID + display name + accent + ordered variants.
// Mirrors the SENSORS array in design/Show-Off Mode.html.

struct SOSensorEntry: Identifiable, Hashable {
    let id: String          // "01","02"…
    let title: String       // "GPS · LOCATION"
    let short: String       // "GPS"
    let accent: Color
    let variants: [String]  // pill labels, e.g. ["HUD","MIN/MAX",…]

    static func == (lhs: SOSensorEntry, rhs: SOSensorEntry) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var titleLocalizationKey: String { "showoff.sensor.\(id).title" }
    var shortLocalizationKey: String { "showoff.sensor.\(id).short" }

    func variantLocalizationKey(at index: Int) -> String {
        "showoff.sensor.\(id).variant.\(index)"
    }

    func localizedTitle(language: AppLanguage) -> String {
        Translations.get(titleLocalizationKey, language: language)
    }

    func localizedShort(language: AppLanguage) -> String {
        Translations.get(shortLocalizationKey, language: language)
    }

    func localizedVariantName(at index: Int, language: AppLanguage) -> String {
        guard variants.indices.contains(index) else { return "" }
        return Translations.get(variantLocalizationKey(at: index), language: language)
    }

    func localizedVariants(language: AppLanguage) -> [String] {
        variants.indices.map { localizedVariantName(at: $0, language: language) }
    }
}

enum SOSensors {
    static let all: [SOSensorEntry] = [
        .init(id: "01", title: "GPS · LOCATION",   short: "GPS",       accent: SO.gpsAccent,
              variants: ["HUD","MIN/MAX","ALTIMAP","COORDS","ORBIT","TRACK","MAP"]),
        .init(id: "02", title: "HEADING · COMPASS",short: "COMPASS",   accent: SO.headingAccent,
              variants: ["ROSE","RADAR","BEARING","DUAL"]),
        .init(id: "03", title: "ACCELEROMETER",    short: "ACCEL",     accent: SO.accelAccent,
              variants: ["G-FORCE","LEVEL","SCOPE","SHAKE"]),
        .init(id: "04", title: "GYROSCOPE",        short: "GYRO",      accent: SO.gyroAccent,
              variants: ["COCKPIT","GIMBAL","SPIN","INTEG"]),
        .init(id: "05", title: "MAGNETOMETER",     short: "MAG",       accent: SO.magAccent,
              variants: ["STRENGTH","FIELD AR","METAL","VECTOR"]),
        .init(id: "06", title: "DEVICE MOTION",    short: "MOTION",    accent: SO.motionAccent,
              variants: ["FLIGHT","3D PHONE","GRAVITY","QUAT"]),
        .init(id: "07", title: "ALTIMETER",        short: "ALT",       accent: SO.altAccent,
              variants: ["TAPE","ELEVATOR","PRESSURE","STAIRS","GEO ALT"]),
        .init(id: "08", title: "BAROMETER",        short: "BARO",      accent: SO.baroAccent,
              variants: ["STATION","STORM","ELEV"]),
        .init(id: "09", title: "PEDOMETER",        short: "STEPS",     accent: SO.pedAccent,
              variants: ["BIG","PACE","STREAK","STAIRS"]),
        .init(id: "10", title: "ACTIVITY",         short: "ACTIVITY",  accent: SO.activityAccent,
              variants: ["BADGE","LIFE LOG","CONFIDENCE"]),
        .init(id: "11", title: "BATTERY",          short: "BATT",      accent: SO.battAccent,
              variants: ["LIQUID","RUNTIME","CHARGING"]),
        .init(id: "12", title: "THERMAL",          short: "THERMAL",   accent: SO.thermAccent,
              variants: ["THERMO","RADIATOR","COOLING"]),
        .init(id: "13", title: "DISK",             short: "DISK",      accent: SO.diskAccent,
              variants: ["WHEEL","TICKER","BLUEPRINT"]),
        .init(id: "14", title: "MEMORY",           short: "MEM",       accent: SO.memAccent,
              variants: ["BARS","MAP","PRESSURE"]),
        .init(id: "15", title: "PROCESSOR",        short: "CPU",       accent: SO.cpuAccent,
              variants: ["CORE GRID","SPIKE","THREAD"]),
        .init(id: "16", title: "BLUETOOTH",        short: "BT",        accent: SO.btAccent,
              variants: ["RADAR","LIST","BEACON"]),
        .init(id: "17", title: "NETWORK",          short: "NET",       accent: SO.netAccent,
              variants: ["CITY","SPEED","TREE"]),
        .init(id: "18", title: "CAMERA",           short: "CAM",       accent: SO.camAccent,
              variants: ["LENSES","VIEWFINDER","AUDIO"]),
        .init(id: "19", title: "LIGHT",            short: "LIGHT",     accent: SO.lightAccent,
              variants: ["LUX","LAMP","CAM LUX"]),
        .init(id: "20", title: "PROXIMITY",        short: "PROX",      accent: SO.proxAccent,
              variants: ["RIPPLE","TOGGLE","EARPIECE"]),
        .init(id: "21", title: "TORCH",            short: "TORCH",     accent: SO.torchAccent,
              variants: ["SWITCH","LIGHTHOUSE","TEMP"]),
    ]

    static func index(of id: String) -> Int {
        all.firstIndex(where: { $0.id == id }) ?? 0
    }
}

// MARK: - Show-Off Mode container

struct ShowOffMode: View {
    let initialSensorID: String
    var initialVariant: Int = 0
    /// Suppressed for deterministic screenshot captures so the first-run
    /// instruction overlay never bleeds into App Store images.
    var showsTutorial: Bool = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locManager: LocalizationManager

    @State private var sensorIdx: Int = 0
    @State private var variantIdx: [String: Int] = [:]
    @State private var showIndex = false
    @State private var showTutorial = false
    @AppStorage("hasSeenShowOffTutorial") private var hasSeenShowOffTutorial = false

    var body: some View {
        let sensor = SOSensors.all[sensorIdx]
        let activeVariant = variantIdx[sensor.id] ?? 0
        let language = locManager.currentLanguage

        ZStack {
            Color.black.ignoresSafeArea()

            // Paged show-off screen swipe (horizontal) over the current sensor's variants.
            // Vertical drag switches sensors — swipe up = next sensor, down = previous.
            TabView(selection: variantBinding(for: sensor)) {
                ForEach(sensor.variants.indices, id: \.self) { vIdx in
                    SOPage(sensor: sensor, variant: vIdx)
                        .tag(vIdx)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 24)
                                .onEnded { value in
                                    handleVerticalSwipe(value)
                                }
                        )
                }
            }
            .id(sensor.id)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Floating chrome (close, sensor name, index button) + bottom pills.
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        chip(icon: "xmark")
                    }
                    .accessibilityLabel(locManager.t("showoff.accessibility.close"))

                    Spacer()

                    HStack(spacing: 6) {
                        // Up/down affordance — vertical swipe changes the sensor.
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(sensor.localizedTitle(language: language).uppercased())
                            .font(.system(size: 11, weight: .semibold).width(.condensed))
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(String(format: locManager.t("showoff.accessibility.sensorSwipe"), sensor.localizedTitle(language: language)))

                    Spacer()

                    Button { showIndex = true } label: {
                        chip(icon: "square.grid.3x3.fill")
                    }
                    .accessibilityLabel(locManager.t("showoff.accessibility.showAllSensors"))
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                if sensor.variants.count > 1 {
                    // Left/right affordance — horizontal swipe changes the show-off screen,
                    // naming the previous and next screens flanking the current one.
                    HStack(spacing: 14) {
                        if activeVariant > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(sensor.localizedVariantName(at: activeVariant - 1, language: language).uppercased())
                            }
                        } else {
                            Image(systemName: "chevron.left").opacity(0.15)
                        }

                        if activeVariant < sensor.variants.count - 1 {
                            HStack(spacing: 4) {
                                Text(sensor.localizedVariantName(at: activeVariant + 1, language: language).uppercased())
                                Image(systemName: "chevron.right")
                            }
                        } else {
                            Image(systemName: "chevron.right").opacity(0.15)
                        }
                    }
                    .font(.system(size: 9, weight: .heavy).width(.condensed))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 6)
                    .accessibilityHidden(true)
                }

                SOPills(
                    variants: sensor.localizedVariants(language: language),
                    active: activeVariant,
                    accent: sensor.accent
                ) { newIdx in
                    variantIdx[sensor.id] = newIdx
                }
                .padding(.bottom, 30)
            }

            // First-run gesture coach. Shown once (tracked via AppStorage),
            // dismissed by tap; suppressed entirely in screenshot mode.
            if showTutorial {
                ShowOffTutorialOverlay(accent: sensor.accent) {
                    hasSeenShowOffTutorial = true
                    withAnimation(.easeOut(duration: 0.25)) { showTutorial = false }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .sheet(isPresented: $showIndex) {
            SOSensorIndex(currentID: sensor.id) { newID in
                showIndex = false
                if let i = SOSensors.all.firstIndex(where: { $0.id == newID }) {
                    sensorIdx = i
                }
            }
            .presentationDetents([.large, .medium])
        }
        .onAppear {
            sensorIdx = SOSensors.index(of: initialSensorID)
            if variantIdx[initialSensorID] == nil {
                variantIdx[initialSensorID] = initialVariant
            }
            if showsTutorial && !hasSeenShowOffTutorial {
                showTutorial = true
            }
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

    // Maps the current sensor to its stored show-off screen (variant) index,
    // so horizontal TabView paging reads/writes the right slot.
    private func variantBinding(for s: SOSensorEntry) -> Binding<Int> {
        Binding(
            get: { variantIdx[s.id] ?? 0 },
            set: { variantIdx[s.id] = $0 }
        )
    }

    // Vertical swipe = sensor switch. Up = next sensor, down = previous.
    // Reject swipes that look horizontal so the TabView's screen paging keeps working.
    private func handleVerticalSwipe(_ value: DragGesture.Value) {
        let dx = abs(value.translation.width)
        let dy = value.translation.height
        guard abs(dy) > 50, abs(dy) > dx * 1.3 else { return }

        let count = SOSensors.all.count
        let next: Int
        if dy < 0 {
            next = min(sensorIdx + 1, count - 1)
        } else {
            next = max(sensorIdx - 1, 0)
        }
        guard next != sensorIdx else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            sensorIdx = next
        }
    }
}

// MARK: - One sensor's page (resolves to a specific variant view)

struct SOPage: View {
    let sensor: SOSensorEntry
    let variant: Int
    var body: some View {
        let content = SOVariantRouter(sensor: sensor, variant: variant)
            .id("\(sensor.id)-\(variant)")

        if UIDevice.current.userInterfaceIdiom == .pad {
            // Scale the phone-proportioned canvas up to fill the available space
            // while preserving the design aspect ratio — adaptive across every
            // iPad size and both orientations (was a hardcoded 430×932 preview).
            GeometryReader { geo in
                let baseW: CGFloat = 430
                let baseH: CGFloat = 932
                let scale = min(geo.size.width / baseW, geo.size.height / baseH)
                ZStack {
                    Color.black.ignoresSafeArea()
                    content
                        .frame(width: baseW, height: baseH)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 32)
                        .scaleEffect(scale)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        } else {
            content
        }
    }
}

// MARK: - First-run gesture coach overlay

/// One-time instructional overlay explaining the two Show-Off swipe axes.
/// Tap anywhere to dismiss. Fully localized.
struct ShowOffTutorialOverlay: View {
    let accent: Color
    let onDismiss: () -> Void
    @EnvironmentObject private var locManager: LocalizationManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(locManager.t("showoff.tutorial.title"))
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .tracking(1)
                        .foregroundStyle(.white)
                    Text(locManager.t("showoff.tutorial.subtitle"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 18) {
                    gestureRow(icon: "arrow.up.arrow.down",
                               title: locManager.t("showoff.tutorial.vertical.title"),
                               detail: locManager.t("showoff.tutorial.vertical.detail"))
                    gestureRow(icon: "arrow.left.arrow.right",
                               title: locManager.t("showoff.tutorial.horizontal.title"),
                               detail: locManager.t("showoff.tutorial.horizontal.detail"))
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: onDismiss) {
                    Text(locManager.t("showoff.tutorial.gotIt"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(accent, in: Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .accessibilityAddTraits(.isModal)
    }

    private func gestureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 44, height: 44)
                .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Sensor index sheet — grid of all sensors w/ accent dots

struct SOSensorIndex: View {
    let currentID: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locManager: LocalizationManager

    private let cols = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(SOSensors.all) { s in
                        Button {
                            onSelect(s.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle().fill(s.accent).frame(width: 10, height: 10)
                                        .shadow(color: s.accent.opacity(0.7), radius: 6)
                                    Text(s.id)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if s.id == currentID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(s.accent)
                                    }
                                }
                                Text(s.localizedShort(language: locManager.currentLanguage))
                                    .font(.system(size: 16, weight: .heavy).width(.condensed))
                                    .tracking(0.5)
                                Text("\(s.variants.count) \(locManager.t("showoff.variants"))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        s.id == currentID ? s.accent : Color.white.opacity(0.06),
                                        lineWidth: s.id == currentID ? 1.5 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(locManager.t("showoff.allSensors"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(locManager.t("button.done")) { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Tail label tag — small "Show-Off" entry button used on detail views

struct ShowOffEntryButton: View {
    let sensorID: String
    let accent: Color
    @State private var present = false
    @EnvironmentObject private var locManager: LocalizationManager
    var body: some View {
        Button {
            present = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.inset.filled.and.cursorarrow")
                    .font(.system(size: 14, weight: .semibold))
                Text(locManager.t("showoff.mode"))
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(0.6)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.55)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .foregroundStyle(.white)
            .cornerRadius(14)
            .shadow(color: accent.opacity(0.45), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $present) {
            ShowOffMode(initialSensorID: sensorID)
        }
    }
}

// MARK: - Convenience modifier — drop a Show-Off banner above any sensor detail.

struct ShowOffEntryModifier: ViewModifier {
    let sensorID: String
    let accent: Color
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            ShowOffEntryButton(sensorID: sensorID, accent: accent)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            content
        }
    }
}

extension View {
    func showOffEntry(sensorID: String, accent: Color) -> some View {
        modifier(ShowOffEntryModifier(sensorID: sensorID, accent: accent))
    }
}

// MARK: - Dashboard launcher — prominent Show-Off button on the main screen.

/// Hero call-to-action on the Dashboard. Launches Show-Off Mode at the very
/// first sensor; first-ever launch surfaces the gesture coach overlay.
struct DashboardShowOffButton: View {
    @State private var present = false
    @EnvironmentObject private var locManager: LocalizationManager

    private var accent: Color { SOSensors.all.first?.accent ?? .blue }

    var body: some View {
        Button {
            present = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.18))
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.bold))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(locManager.t("showoff.button.title"))
                        .font(.headline.weight(.heavy))
                        .lineLimit(1)
                    Text(locManager.t("showoff.button.subtitle"))
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .opacity(0.86)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.headline.weight(.bold))
                    .opacity(0.74)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(
                LinearGradient(
                    colors: [accent, Color(red: 0.93, green: 0.27, blue: 0.60)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 54, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.16))
                    .padding(.trailing, 16)
                    .padding(.top, 8)
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: accent.opacity(0.28), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locManager.t("showoff.button.title"))
        .accessibilityHint(locManager.t("showoff.button.subtitle"))
        .fullScreenCover(isPresented: $present) {
            ShowOffMode(initialSensorID: SOSensors.all.first?.id ?? "01")
        }
    }
}
