import SwiftUI
import CoreLocation
import MapKit

// ════════════════════════════════════════════════════════════
// Sensor 01 — GPS / LOCATION
// ════════════════════════════════════════════════════════════

struct SOGPS: View {
    let variant: Int
    @EnvironmentObject var loc: LocationSensorManager
    var body: some View {
        switch variant {
        case 0: GPSHud(loc: loc)
        case 1: GPSMinMax(loc: loc)
        case 2: GPSAltimap(loc: loc)
        case 3: GPSCoords(loc: loc)
        case 4: GPSOrbit(loc: loc)
        case 5: GPSTrack(loc: loc)
        default: GPSMap(loc: loc)
        }
    }
}

private struct GPSHud: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                HStack {
                    SOLabel(text: "FLR · \(loc.floor.map(String.init) ?? "—")", size: 9)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                            .shadow(color: .green, radius: 6)
                        SOLabel(text: loc.horizontalAccuracy < 10 ? "FIX · GREAT" : "FIX · OK", size: 9)
                    }
                }
                .padding(.horizontal, 20)
                Spacer().frame(height: 24)
                SOLabel(text: "Ground Speed · km/h", opacity: 0.55)
                let kph = max(0, loc.speed) * 3.6
                SOHero(text: String(format: "%.0f", kph), size: 140, color: .white)
                    .padding(.top, 8)
                Spacer().frame(height: 32)
                stripCompass
                    .padding(.horizontal, 18)
                Spacer().frame(height: 16)
                SOTickerBar(accent: SO.gpsAccent, items: [
                    .init(label: "ALT",   value: String(format: "%.0f m", loc.altitude)),
                    .init(label: "H.ACC", value: String(format: "%.1f m", max(0, loc.horizontalAccuracy))),
                    .init(label: "V.ACC", value: String(format: "%.1f m", max(0, loc.verticalAccuracy))),
                ])
                .padding(.horizontal, 18)
                Spacer()
            }
        }
    }

    private var stripCompass: some View {
        VStack(spacing: 6) {
            SOFormattedLabel(format: "Heading %d°", value: Int(loc.trueHeading.rounded()), size: 9)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                    .frame(height: 18)
                HStack(spacing: 0) {
                    ForEach(["N","030","060","E","120","150","S","210"], id: \.self) { c in
                        Text(c)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(c == "E" ? SO.gpsAccent : .white.opacity(0.7))
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(x: -22)
                Rectangle().fill(SO.gpsAccent).frame(width: 1).frame(maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 18)
        }
    }
}

private struct GPSMinMax: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "SPEED · km/h · session", size: 9).padding(.horizontal, 18)
                Spacer().frame(height: 14)
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        statRow("MIN", "0.0", color: .white.opacity(0.5))
                        statRow("AVG", "18.4", color: .white)
                        statRow("MAX", String(format: "%.1f", max(loc.speed * 3.6, 47.6)),
                                color: SO.gpsAccent, glow: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    histogram
                }
                .padding(.horizontal, 18)
                Spacer().frame(height: 32)
                SOLabel(text: "ALTITUDE · m", size: 9).padding(.horizontal, 18)
                HStack {
                    altCol("MIN", "42", accent: false)
                    Spacer()
                    altCol("AVG", "107", accent: false)
                    Spacer()
                    altCol("MAX", "198", accent: true)
                }
                .padding(.horizontal, 18).padding(.top, 8)
                Spacer()
                SOTextLabel("RESET")
                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                    .tracking(1.5)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.08)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 110)
            }
        }
    }

    private func statRow(_ label: String, _ value: String, color: Color, glow: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SOLabel(text: label, size: 9)
            Text(value)
                .font(.system(size: 64, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(color)
                .shadow(color: glow ? SO.gpsAccent : .clear, radius: glow ? 20 : 0)
        }
    }

    private var histogram: some View {
        let heights: [Double] = [0.2,0.5,0.7,0.9,0.85,0.6,0.45,0.3,0.5,0.7,1,0.95,0.8,0.65,0.4,0.25,0.5,0.7,0.85,0.95]
        return VStack(alignment: .trailing, spacing: 2) {
            ForEach(heights.reversed().indices, id: \.self) { i in
                let h = heights.reversed()[heights.index(heights.startIndex, offsetBy: i)]
                Capsule()
                    .fill(SO.gpsAccent.opacity(h))
                    .frame(width: 56 * h, height: 8)
            }
            SOLabel(text: "60 s", size: 8).padding(.top, 4)
        }
        .frame(width: 56)
    }

    private func altCol(_ l: String, _ v: String, accent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SOLabel(text: l, size: 8, opacity: 0.5)
            Text(v).font(.system(size: 26, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent ? SO.gpsAccent : .white)
        }
    }
}

private struct GPSAltimap: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent, bg: .custom(
            LinearGradient(colors: [Color(red: 0.10, green: 0.14, blue: 0.20),
                                    Color(red: 0.05, green: 0.08, blue: 0.14),
                                    Color(red: 0.09, green: 0.13, blue: 0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing))) {
            ZStack(alignment: .top) {
                streets
                pin.padding(.top, 200)
                infoSheet
            }
        }
    }

    private var streets: some View {
        Canvas { ctx, size in
            ctx.stroke(streetPath1(size: size), with: .color(.white.opacity(0.18)), lineWidth: 2.5)
            ctx.stroke(streetPath2(size: size), with: .color(.white.opacity(0.18)), lineWidth: 2.5)
        }
    }

    private func streetPath1(size: CGSize) -> Path {
        var p = Path()
        p.move(to: .init(x: -20, y: 320))
        p.addQuadCurve(to: .init(x: 220, y: 340), control: .init(x: 100, y: 290))
        p.addLine(to: .init(x: size.width + 20, y: 380))
        return p
    }
    private func streetPath2(size: CGSize) -> Path {
        var p = Path()
        p.move(to: .init(x: 50, y: -10))
        p.addQuadCurve(to: .init(x: 120, y: 400), control: .init(x: 80, y: 200))
        p.addLine(to: .init(x: 200, y: size.height + 20))
        return p
    }

    private var pin: some View {
        ZStack {
            Circle().fill(SO.gpsAccent.opacity(0.25))
                .frame(width: 80, height: 80)
            Circle().fill(SO.gpsAccent)
                .frame(width: 16, height: 16)
                .shadow(color: SO.gpsAccent, radius: 12)
                .overlay(Circle().strokeBorder(.white.opacity(0.95), lineWidth: 3))
        }
    }

    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
                SOLabel(text: "POSITION", size: 9)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    infoRow("LAT",   String(format: "%.6f", loc.latitude))
                    infoRow("LON",   String(format: "%.6f", loc.longitude))
                    infoRow("ALT",   String(format: "%.1f m", loc.altitude))
                    infoRow("SPEED", String(format: "%.1f m/s", max(0, loc.speed)))
                    infoRow("FLOOR", loc.floor.map { String($0) } ?? "—")
                    infoRow("H.ACC", String(format: "%.1f m", max(0, loc.horizontalAccuracy)))
                }
            }
            .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 110)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .overlay(.ultraThinMaterial.opacity(0.6))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoRow(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: k, size: 8)
            Text(v).font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white).monospacedDigit()
        }
    }
}

private struct GPSCoords: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent) {
            ZStack {
                graticule
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    SOLabel(text: "COORDINATES · DD")
                    let lat = String(format: "%.6f", loc.latitude)
                    let lon = String(format: "%.6f", loc.longitude)
                    coordLine(lat)
                    coordLine(lon).padding(.top, 8)
                    HStack(spacing: 4) {
                        format("DD",  active: true)
                        format("DMS", active: false)
                    }
                    .padding(4)
                    .background(Capsule().fill(.black.opacity(0.4)))
                    .padding(.top, 26)
                    Spacer()
                    SOLabel(text: "FIX · ISO 8601", size: 9)
                    Text(ISO8601DateFormatter().string(from: loc.timestamp))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 4)
                    Spacer().frame(height: 96)
                }
                .padding(.horizontal, 18)
            }
        }
    }
    private var graticule: some View {
        Canvas { ctx, size in
            ctx.opacity = 0.06
            for i in 0..<18 {
                var p = Path()
                p.addEllipse(in: .init(x: 0, y: 50 + CGFloat(i) * 45 - 6, width: size.width, height: 12))
                ctx.stroke(p, with: .color(.white), lineWidth: 0.4)
            }
        }
    }
    private func coordLine(_ s: String) -> some View {
        let parts = s.split(separator: ".", maxSplits: 1)
        return HStack(spacing: 0) {
            Text(parts.first.map(String.init) ?? "").foregroundStyle(.white)
            Text(".").foregroundStyle(.white)
            Text(parts.dropFirst().first.map(String.init) ?? "").foregroundStyle(SO.gpsAccent)
        }
        .font(.system(size: 56, weight: .semibold, design: .monospaced))
        .monospacedDigit()
    }
    private func format(_ t: String, active: Bool) -> some View {
        Text(t)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(active ? .white : .white.opacity(0.5))
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(active ? Capsule().fill(SO.gpsAccent) : Capsule().fill(Color.clear))
    }
}

private struct GPSOrbit: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Satellite Lock")
                Text(String(format: "%.1f", max(0, loc.horizontalAccuracy)))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SO.gpsAccent)
                + Text("m").font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                orbits
                Spacer()
                SOTickerBar(accent: SO.gpsAccent, items: [
                    .init(label: "SATS",  value: "6 / 8"),
                    .init(label: "PDOP",  value: "1.4"),
                    .init(label: "STATE", value: loc.isAuthorized ? "LOCKED" : "—", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var orbits: some View {
        SOTick { t in
            ZStack {
                ForEach([280, 200, 120], id: \.self) { d in
                    Circle()
                        .strokeBorder(SO.gpsAccent.opacity(0.25), style: .init(lineWidth: 1, dash: [3, 4]))
                        .frame(width: CGFloat(d), height: CGFloat(d))
                }
                ForEach(0..<6, id: \.self) { i in
                    let cfgs = [(280.0, 30.0, 14.0),(280.0, 200.0, 14.0),(200.0, 110.0, 9.0),
                                (200.0, 290.0, 9.0),(120.0, 60.0, 5.0),(120.0, 240.0, 5.0)]
                    let (d, baseA, dur) = cfgs[i]
                    let a = (baseA + t * 360.0 / dur).truncatingRemainder(dividingBy: 360)
                    let r = d / 2
                    let rad = a * .pi / 180
                    Rectangle()
                        .fill(SO.gpsAccent)
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                        .shadow(color: SO.gpsAccent, radius: 8)
                        .offset(x: r * cos(rad), y: r * sin(rad))
                }
                VStack(spacing: 4) {
                    Text(String(format: "%.4f° N", abs(loc.latitude)))
                    Text(String(format: "%.4f° W", abs(loc.longitude)))
                }
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.white)
            }
            .frame(width: 320, height: 320)
        }
    }
}

// MARK: - GPS Map View

private struct GPSTrackMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var course: Double
    var horizontalAccuracy: Double
    var trackCoordinates: [CLLocationCoordinate2D]
    var trackColor: UIColor
    var accuracyBadgeColor: Color

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.mapType = .hybrid
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        context.coordinator.mapView = mapView
        context.coordinator.setupGestureRecognizer()
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.updateMap(
            mapView,
            coordinate: coordinate,
            course: course,
            horizontalAccuracy: horizontalAccuracy,
            trackCoordinates: trackCoordinates,
            trackColor: trackColor
        )
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        private var trackPolyline: MKPolyline?
        private var accuracyCircle: MKCircle?
        private var currentAnnotation: MKPointAnnotation?
        private var recenterTimer: Timer?
        private var isUserPanning = false
        var trackColor: UIColor = .red

        func setupGestureRecognizer() {
            guard let mv = mapView else { return }
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan.delegate = self
            mv.addGestureRecognizer(pan)
        }

        @objc private func handlePan(_ g: UIPanGestureRecognizer) {
            switch g.state {
            case .began:
                isUserPanning = true
                recenterTimer?.invalidate()
            case .ended, .cancelled:
                recenterTimer?.invalidate()
                recenterTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                    self?.isUserPanning = false
                    self?.mapView?.setUserTrackingMode(.followWithHeading, animated: true)
                }
            default: break
            }
        }

        func updateMap(
            _ mapView: MKMapView,
            coordinate: CLLocationCoordinate2D,
            course: Double,
            horizontalAccuracy: Double,
            trackCoordinates: [CLLocationCoordinate2D],
            trackColor: UIColor
        ) {
            self.trackColor = trackColor
            guard CLLocationCoordinate2DIsValid(coordinate) else { return }

            if currentAnnotation == nil {
                let ann = MKPointAnnotation()
                ann.coordinate = coordinate
                mapView.addAnnotation(ann)
                currentAnnotation = ann
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.currentAnnotation?.coordinate = coordinate
                }
            }

            if let old = accuracyCircle { mapView.removeOverlay(old) }
            let circle = MKCircle(center: coordinate, radius: max(0, horizontalAccuracy))
            mapView.addOverlay(circle)
            accuracyCircle = circle

            if !isUserPanning, course >= 0 {
                mapView.setCamera(
                    MKMapCamera(lookingAtCenter: coordinate, fromDistance: 500, pitch: 60, heading: course),
                    animated: true
                )
            }

            if trackCoordinates.count >= 2 {
                if let old = trackPolyline { mapView.removeOverlay(old) }
                let polyline = MKPolyline(coordinates: trackCoordinates, count: trackCoordinates.count)
                polyline.title = "track"
                mapView.addOverlay(polyline)
                trackPolyline = polyline
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let r = MKCircleRenderer(circle: circle)
                if circle.radius < 10 {
                    r.fillColor = UIColor.green.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.green.withAlphaComponent(0.5)
                } else if circle.radius < 30 {
                    r.fillColor = UIColor.yellow.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.yellow.withAlphaComponent(0.5)
                } else {
                    r.fillColor = UIColor.red.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.red.withAlphaComponent(0.5)
                }
                r.lineWidth = 1.5
                return r
            }
            if let polyline = overlay as? MKPolyline, polyline.title == "track" {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = self.trackColor
                r.lineWidth = 4
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "com.allsensors.gpsPin"
            var v = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if v == nil {
                v = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                v?.canShowCallout = false
            }
            v?.frame = CGRect(x: 0, y: 0, width: 32, height: 44)

            let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 44))
            let img = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 44)).image { ctx in
                let c = ctx.cgContext
                c.setFillColor(UIColor.white.cgColor)
                c.fillEllipse(in: CGRect(x: 8, y: 8, width: 16, height: 16))
                c.setFillColor(self.trackColor.cgColor)
                c.fillEllipse(in: CGRect(x: 12, y: 12, width: 8, height: 8))

                let t = UIBezierPath()
                t.move(to: CGPoint(x: 16, y: 2))
                t.addLine(to: CGPoint(x: 32, y: 44))
                t.addLine(to: CGPoint(x: 0, y: 44))
                t.close()
                self.trackColor.setFill()
                t.fill()
            }
            iv.image = img
            v?.subviews.forEach { $0.removeFromSuperview() }
            v?.addSubview(iv)
            v?.annotation = annotation
            return v
        }
    }
}

extension GPSTrackMapView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

private struct GPSTrack: View {
    @ObservedObject var loc: LocationSensorManager
    @State private var track: [CLLocationCoordinate2D] = []
    @State private var lastCoord: CLLocationCoordinate2D?

    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent, bg: .none) {
            ZStack {
                GPSTrackMapView(
                    coordinate: validCoord,
                    course: loc.course,
                    horizontalAccuracy: max(0, loc.horizontalAccuracy),
                    trackCoordinates: track,
                    trackColor: UIColor(SO.gpsAccent),
                    accuracyBadgeColor: SO.gpsAccent
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    infoSheet
                }
            }
            .onChange(of: coordKey) { _ in
                let coord = validCoord
                guard coord.latitude != 0 || coord.longitude != 0 else { return }
                if let last = lastCoord {
                    let l1 = CLLocation(latitude: last.latitude, longitude: last.longitude)
                    let l2 = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                    guard l2.distance(from: l1) > 0.5 else { return }
                }
                track.append(coord)
                lastCoord = coord
                if track.count > 500 { track.removeFirst(track.count - 500) }
            }
        }
    }

    private var coordKey: String {
        "\(loc.latitude),\(loc.longitude)"
    }

    private var validCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
            SOLabel(text: "POSITION", size: 9)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                infoRow("LAT",   String(format: "%.6f", loc.latitude))
                infoRow("LON",   String(format: "%.6f", loc.longitude))
                infoRow("ALT",   String(format: "%.1f m", loc.altitude))
                infoRow("SPEED", String(format: "%.1f m/s", max(0, loc.speed)))
                infoRow("COURSE", String(format: "%.0f°", loc.course))
                infoRow("H.ACC", accBadge)
            }
        }
        .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 110)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(.ultraThinMaterial.opacity(0.6))
        )
    }

    private var accBadge: some View {
        let acc = max(0, loc.horizontalAccuracy)
        let (label, color): (String, Color) = {
            if acc < 10 { return ("OK · \(String(format: "%.1f", acc)) m", .green) }
            if acc < 30 { return ("FAIR · \(String(format: "%.1f", acc)) m", .yellow) }
            return ("POOR · \(String(format: "%.1f", acc)) m", .red)
        }()
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    private func infoRow(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: k, size: 8)
            Text(v).font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white).monospacedDigit()
        }
    }

    private func infoRow(_ k: String, _ v: some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: k, size: 8)
            v
        }
    }
}

// MARK: - GPS Map Variant

private struct GPSMap: View {
    @ObservedObject var loc: LocationSensorManager

    // Persisted map customization — survives relaunch (MapKit defaults out of the box).
    @AppStorage("gpsmap.style")      private var styleRaw    = SOMapStyleKind.standard.rawValue
    @AppStorage("gpsmap.tracking")   private var trackingRaw = SOMapTracking.heading.rawValue
    @AppStorage("gpsmap.realistic")  private var realistic   = false
    @AppStorage("gpsmap.pitch3D")    private var pitch3D     = false
    @AppStorage("gpsmap.traffic")    private var traffic     = false
    @AppStorage("gpsmap.poi")        private var poi         = true
    @AppStorage("gpsmap.selectable") private var selectable  = false
    @AppStorage("gpsmap.compass")    private var compass     = true
    @AppStorage("gpsmap.scale")      private var scale       = true
    @AppStorage("gpsmap.zoomLimit")  private var zoomLimit   = false
    @AppStorage("gpsmap.flyover")    private var flyover     = false

    @State private var showPanel = false
    @State private var lookAround: SOLookAroundItem?
    @State private var lookAroundBusy = false
    @State private var lookAroundUnavailable = false

    private var config: SOMapConfig {
        SOMapConfig(
            style: SOMapStyleKind(rawValue: styleRaw) ?? .standard,
            realistic: realistic,
            pitch3D: pitch3D,
            traffic: traffic,
            poi: poi,
            selectable: selectable,
            tracking: SOMapTracking(rawValue: trackingRaw) ?? .heading,
            compass: compass,
            scale: scale,
            zoomLimit: zoomLimit,
            flyover: flyover
        )
    }

    var body: some View {
        SOVariant(sensor: "GPS", accent: SO.gpsAccent, bg: .none) {
            ZStack(alignment: .bottom) {
                GPSShowcaseMapView(
                    coordinate: validCoord,
                    course: loc.course,
                    horizontalAccuracy: max(0, loc.horizontalAccuracy),
                    config: config,
                    accent: SO.gpsAccent
                )
                .ignoresSafeArea()

                // Apple-Maps-style control buttons on the trailing edge.
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        mapButton(icon: "slider.horizontal.3", active: showPanel) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showPanel.toggle()
                            }
                        }
                        mapButton(icon: lookAroundBusy ? "hourglass" : "binoculars.fill", active: false) {
                            requestLookAround()
                        }
                    }
                    .padding(.trailing, 14)
                }
                .padding(.top, 56)
                .frame(maxHeight: .infinity, alignment: .top)

                if lookAroundUnavailable {
                    VStack {
                        SOTextLabel("LOOK AROUND UNAVAILABLE HERE")
                            .font(.system(size: 11, weight: .heavy).width(.condensed))
                            .tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Capsule().fill(.black.opacity(0.8)))
                        Spacer()
                    }
                    .padding(.top, 110)
                    .transition(.opacity)
                }

                if showPanel {
                    controlPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    infoSheet
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .fullScreenCover(item: $lookAround) { item in
            SOLookAroundSheet(scene: item.scene)
        }
    }

    private var validCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    // MARK: Controls

    private func mapButton(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(active ? .black : .white)
                .frame(width: 44, height: 44)
                .background {
                    if active { Circle().fill(SO.gpsAccent) }
                    else { Circle().fill(.ultraThinMaterial) }
                }
                .overlay(Circle().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var styleBinding: Binding<SOMapStyleKind> {
        Binding(get: { SOMapStyleKind(rawValue: styleRaw) ?? .standard },
                set: { styleRaw = $0.rawValue })
    }
    private var trackingBinding: Binding<SOMapTracking> {
        Binding(get: { SOMapTracking(rawValue: trackingRaw) ?? .heading },
                set: { trackingRaw = $0.rawValue })
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SOLabel(text: "MAP OPTIONS", size: 9)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showPanel = false }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    segRow("STYLE", selection: styleBinding, options: SOMapStyleKind.allCases)
                    segRow("CAMERA TRACKING", selection: trackingBinding, options: SOMapTracking.allCases)
                    Divider().overlay(.white.opacity(0.1))
                    toggleRow("3D REALISTIC TERRAIN", $realistic)
                    toggleRow("3D TILT · MANUAL MODE", $pitch3D)
                    toggleRow("FLYOVER ORBIT", $flyover)
                    Divider().overlay(.white.opacity(0.1))
                    toggleRow("TRAFFIC", $traffic)
                    toggleRow("POINTS OF INTEREST", $poi)
                    toggleRow("TAPPABLE MAP FEATURES", $selectable)
                    Divider().overlay(.white.opacity(0.1))
                    toggleRow("COMPASS", $compass)
                    toggleRow("SCALE BAR", $scale)
                    toggleRow("ZOOM LIMIT", $zoomLimit)
                }
            }
            .frame(maxHeight: 280)
        }
        .padding(20)
        .padding(.bottom, 90)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(.ultraThinMaterial.opacity(0.6))
        )
    }

    private func segRow<T: SOSegOption>(_ title: String, selection: Binding<T>, options: [T]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SOLabel(text: title, size: 8)
            Picker(title, selection: selection) {
                ForEach(options) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func toggleRow(_ title: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Text(title)
                .font(.system(size: 12, weight: .semibold).width(.condensed))
                .tracking(1)
                .foregroundStyle(.white)
        }
        .tint(SO.gpsAccent)
    }

    // MARK: Look Around

    private func requestLookAround() {
        let coord = validCoord
        guard CLLocationCoordinate2DIsValid(coord), coord.latitude != 0 || coord.longitude != 0 else {
            showUnavailable(); return
        }
        lookAroundBusy = true
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coord)
            let scene = try? await request.scene
            await MainActor.run {
                lookAroundBusy = false
                if let scene {
                    lookAround = SOLookAroundItem(scene: scene)
                } else {
                    showUnavailable()
                }
            }
        }
    }

    private func showUnavailable() {
        withAnimation { lookAroundUnavailable = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            await MainActor.run { withAnimation { lookAroundUnavailable = false } }
        }
    }

    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(.white.opacity(0.3)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
            SOLabel(text: "CURRENT POSITION", size: 9)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                mapInfoRow("LAT",   String(format: "%.6f", loc.latitude))
                mapInfoRow("LON",   String(format: "%.6f", loc.longitude))
                mapInfoRow("ALT",   String(format: "%.0f m", loc.altitude))
                mapInfoRow("SPEED", String(format: "%.1f m/s", max(0, loc.speed)))
                mapInfoRow("COURSE", String(format: "%.0f°", loc.course))
                mapInfoRow("H.ACC", accBadge)
            }
        }
        .padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 110)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .overlay(.ultraThinMaterial.opacity(0.6))
        )
    }

    private var accBadge: some View {
        let acc = max(0, loc.horizontalAccuracy)
        let (label, color): (String, Color) = {
            if acc < 10 { return ("OK", .green) }
            if acc < 30 { return ("FAIR", .yellow) }
            return ("POOR", .red)
        }()
        return HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(label) \(String(format: "%.1f", acc))m")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }

    private func mapInfoRow(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: k, size: 8)
            Text(v).font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white).monospacedDigit()
        }
    }

    private func mapInfoRow(_ k: String, _ v: some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SOLabel(text: k, size: 8)
            v
        }
    }
}

// MARK: - GPS Map showcase — configuration model

protocol SOSegOption: Identifiable, Hashable {
    var label: String { get }
}

enum SOMapStyleKind: String, CaseIterable, SOSegOption {
    case standard, hybrid, imagery
    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid:   return "Hybrid"
        case .imagery:  return "Satellite"
        }
    }
}

enum SOMapTracking: String, CaseIterable, SOSegOption {
    case off, follow, heading
    var id: String { rawValue }
    var label: String {
        switch self {
        case .off:     return "Off"
        case .follow:  return "Follow"
        case .heading: return "Heading"
        }
    }
}

struct SOMapConfig {
    var style: SOMapStyleKind
    var realistic: Bool
    var pitch3D: Bool
    var traffic: Bool
    var poi: Bool
    var selectable: Bool
    var tracking: SOMapTracking
    var compass: Bool
    var scale: Bool
    var zoomLimit: Bool
    var flyover: Bool

    var trackingMode: MKUserTrackingMode {
        switch tracking {
        case .off:     return .none
        case .follow:  return .follow
        case .heading: return .followWithHeading
        }
    }

    // Properties that only affect the static map presentation (so we can skip
    // re-applying the preferredConfiguration on every camera tick).
    func displayEquals(_ o: SOMapConfig) -> Bool {
        style == o.style && realistic == o.realistic && traffic == o.traffic &&
        poi == o.poi && selectable == o.selectable && compass == o.compass &&
        scale == o.scale && zoomLimit == o.zoomLimit
    }
}

// MARK: - GPS Map showcase — MKMapView wrapper

private struct GPSShowcaseMapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var course: Double
    var horizontalAccuracy: Double
    var config: SOMapConfig
    var accent: Color

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true     // native dot + accuracy halo + heading
        map.isPitchEnabled = true
        map.isRotateEnabled = true
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        context.coordinator.accent = UIColor(accent)
        context.coordinator.map = map
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.accent = UIColor(accent)
        context.coordinator.update(map,
                                   coordinate: coordinate,
                                   course: course,
                                   accuracy: horizontalAccuracy,
                                   config: config)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        weak var map: MKMapView?
        var accent: UIColor = .systemBlue
        private var applied: SOMapConfig?
        private var didInitialCenter = false
        private var flyoverTimer: Timer?
        private var flyoverHeading: Double = 0

        deinit { flyoverTimer?.invalidate() }

        func update(_ map: MKMapView,
                    coordinate: CLLocationCoordinate2D,
                    course: Double,
                    accuracy: Double,
                    config c: SOMapConfig) {
            self.map = map
            let valid = CLLocationCoordinate2DIsValid(coordinate) &&
                        (coordinate.latitude != 0 || coordinate.longitude != 0)

            if applied?.displayEquals(c) != true {
                applyDisplay(map, c)
            }

            if c.flyover {
                if flyoverTimer == nil {
                    startFlyover(map, around: valid ? coordinate : map.centerCoordinate)
                }
            } else {
                if flyoverTimer != nil {
                    stopFlyover()
                    map.setUserTrackingMode(c.trackingMode, animated: true)
                }
                if applied?.tracking != c.tracking {
                    map.setUserTrackingMode(c.trackingMode, animated: true)
                }
                if c.tracking == .off, valid {
                    let pitchChanged = applied?.pitch3D != c.pitch3D
                    if !didInitialCenter || pitchChanged {
                        if c.pitch3D {
                            map.setCamera(
                                MKMapCamera(lookingAtCenter: coordinate,
                                            fromDistance: 600,
                                            pitch: 55,
                                            heading: course >= 0 ? course : 0),
                                animated: true)
                        } else if !didInitialCenter {
                            map.setRegion(
                                MKCoordinateRegion(center: coordinate,
                                                   latitudinalMeters: 500,
                                                   longitudinalMeters: 500),
                                animated: true)
                        }
                        didInitialCenter = true
                    }
                }
            }

            applied = c
        }

        private func applyDisplay(_ map: MKMapView, _ c: SOMapConfig) {
            let elevation: MKMapConfiguration.ElevationStyle = c.realistic ? .realistic : .flat
            let poiFilter: MKPointOfInterestFilter = c.poi ? .includingAll : .excludingAll

            switch c.style {
            case .standard:
                let cfg = MKStandardMapConfiguration(elevationStyle: elevation, emphasisStyle: .default)
                cfg.showsTraffic = c.traffic
                cfg.pointOfInterestFilter = poiFilter
                map.preferredConfiguration = cfg
            case .hybrid:
                let cfg = MKHybridMapConfiguration(elevationStyle: elevation)
                cfg.showsTraffic = c.traffic
                cfg.pointOfInterestFilter = poiFilter
                map.preferredConfiguration = cfg
            case .imagery:
                map.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: elevation)
            }

            map.selectableMapFeatures = c.selectable
                ? [.pointsOfInterest, .physicalFeatures, .territories]
                : []
            map.showsCompass = c.compass
            map.showsScale = c.scale

            let range = c.zoomLimit
                ? MKMapView.CameraZoomRange(minCenterCoordinateDistance: 150,
                                            maxCenterCoordinateDistance: 4000)
                : MKMapView.CameraZoomRange(minCenterCoordinateDistance: 1)
            if let range { map.setCameraZoomRange(range, animated: true) }
        }

        private func startFlyover(_ map: MKMapView, around coord: CLLocationCoordinate2D) {
            map.setUserTrackingMode(.none, animated: false)
            flyoverHeading = map.camera.heading
            flyoverTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self, weak map] _ in
                guard let self, let map else { return }
                self.flyoverHeading = (self.flyoverHeading + 0.25).truncatingRemainder(dividingBy: 360)
                let cam = MKMapCamera(lookingAtCenter: coord,
                                      fromDistance: 900,
                                      pitch: 62,
                                      heading: self.flyoverHeading)
                map.setCamera(cam, animated: false)
            }
        }

        private func stopFlyover() {
            flyoverTimer?.invalidate()
            flyoverTimer = nil
        }
    }
}

// MARK: - GPS Map showcase — Look Around

private struct SOLookAroundItem: Identifiable {
    let id = UUID()
    let scene: MKLookAroundScene
}

private struct SOLookAroundSheet: View {
    let scene: MKLookAroundScene
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topTrailing) {
            SOLookAroundContainer(scene: scene)
                .ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}

private struct SOLookAroundContainer: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let vc = MKLookAroundViewController(scene: scene)
        vc.isNavigationEnabled = true
        vc.showsRoadLabels = true
        return vc
    }
    func updateUIViewController(_ vc: MKLookAroundViewController, context: Context) {
        vc.scene = scene
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 02 — HEADING / COMPASS
// ════════════════════════════════════════════════════════════

struct SOHeading: View {
    let variant: Int
    @EnvironmentObject var loc: LocationSensorManager
    var body: some View {
        switch variant {
        case 0: HeadingRose(loc: loc)
        case 1: HeadingRadar(loc: loc)
        case 2: HeadingBearing(loc: loc)
        default: HeadingDual(loc: loc)
        }
    }
}

private struct HeadingRose: View {
    @ObservedObject var loc: LocationSensorManager
    private let cardinals = [(0, "N"), (45, "NE"), (90, "E"), (135, "SE"),
                             (180, "S"), (225, "SW"), (270, "W"), (315, "NW")]
    var body: some View {
        SOVariant(sensor: "HEADING", accent: SO.headingAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 70)
                ZStack {
                    SOCompassRose(heading: loc.trueHeading, accent: SO.headingAccent, size: 300)
                    VStack(spacing: 4) {
                        Text("\(Int(loc.trueHeading.rounded()))°")
                            .font(.system(size: 72, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(directionFor(loc.trueHeading))
                            .font(.system(size: 22, weight: .heavy).width(.condensed))
                            .tracking(8)
                            .foregroundStyle(SO.headingAccent)
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        toggle("TRUE", active: true)
                        toggle("MAG",  active: false)
                    }
                    .padding(4).background(Capsule().fill(.black.opacity(0.4)))
                    HStack(spacing: 6) {
                        Circle().fill(.green).frame(width: 5, height: 5)
                        Text("ACC ±\(Int(max(1, loc.headingAccuracy)))°")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.green.opacity(0.15)))
                    .foregroundStyle(.green)
                }
                Spacer().frame(height: 100)
            }
        }
    }
    private func directionFor(_ deg: Double) -> String {
        let d = ((deg.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360))
        let idx = Int((d / 45.0).rounded()) % 8
        return cardinals[idx].1
    }
    private func toggle(_ s: String, active: Bool) -> some View {
        Text(s)
            .font(.system(size: 10, weight: .heavy))
            .tracking(1)
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(active ? Capsule().fill(SO.headingAccent) : Capsule().fill(Color.clear))
            .foregroundStyle(active ? .white : .white.opacity(0.5))
    }
}

private struct HeadingRadar: View {
    @ObservedObject var loc: LocationSensorManager
    private let scope = Color(red: 0x22/255.0, green: 0xc5/255.0, blue: 0x5e/255.0)
    var body: some View {
        SOVariant(sensor: "HEADING", accent: scope, bg: .custom(
            LinearGradient(colors: [Color(red: 0.03, green: 0.15, blue: 0.10),
                                    Color(red: 0.01, green: 0.04, blue: 0.03)],
                           startPoint: .top, endPoint: .bottom))) {
            VStack(spacing: 0) {
                Spacer().frame(height: 76)
                Triangle().fill(scope).frame(width: 14, height: 20)
                Text("\(Int(loc.trueHeading.rounded()))°")
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(scope)
                    .padding(.top, 4)
                Spacer().frame(height: 30)
                radar
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BRG: \(Int(loc.trueHeading.rounded()))°")
                        Text("RNG: ∞")
                        Text("SWP: 1 Hz")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(scope.opacity(0.85))
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.bottom, 110)
            }
        }
    }
    private var radar: some View {
        SOTick { t in
            ZStack {
                ForEach([260, 200, 140, 80], id: \.self) { d in
                    Circle().strokeBorder(scope.opacity(0.27), lineWidth: 1)
                        .frame(width: CGFloat(d), height: CGFloat(d))
                }
                Rectangle().fill(scope.opacity(0.13)).frame(width: 260, height: 1)
                Rectangle().fill(scope.opacity(0.13)).frame(width: 1, height: 260)
                // sweep
                Path { p in
                    p.move(to: .init(x: 130, y: 130))
                    p.addArc(center: .init(x: 130, y: 130), radius: 130,
                             startAngle: .degrees(-90), endAngle: .degrees(-30), clockwise: false)
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [scope.opacity(0.55), scope.opacity(0)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(t * 120))
                ForEach(0..<4, id: \.self) { i in
                    let pings = [(60.0, 90.0),(-50.0, 60.0),(80.0, -40.0),(-30.0, -90.0)]
                    Circle().fill(Color(red: 0.52, green: 0.94, blue: 0.69))
                        .frame(width: 6, height: 6)
                        .shadow(color: scope, radius: 6)
                        .offset(x: pings[i].0, y: pings[i].1)
                }
            }
            .frame(width: 280, height: 280)
        }
    }
}

private struct HeadingBearing: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "HEADING", accent: SO.headingAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 90)
                SOLabel(text: "BEARING TO")
                SOTextLabel("QIBLA · MECCA")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white).padding(.top, 4)
                Text("21.4225° N · 39.8262° E")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 2)
                Spacer().frame(height: 30)
                arrow
                Spacer()
                SOLabel(text: "DISTANCE", size: 9)
                Text("11,438")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                + Text(" km")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer().frame(height: 24)
                HStack(spacing: 6) {
                    chip("MAG.N",   active: false)
                    chip("TRUE.N",  active: false)
                    chip("QIBLA",   active: true)
                    chip("PIN",     active: false)
                }
                Spacer().frame(height: 100)
            }
        }
    }
    private var arrow: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 140, weight: .black))
            .foregroundStyle(
                LinearGradient(colors: [SO.headingAccent, SO.headingAccent.opacity(0.4)],
                               startPoint: .top, endPoint: .bottom))
            .shadow(color: SO.headingAccent, radius: 16)
            .rotationEffect(.degrees(-32))
    }
    private func chip(_ t: String, active: Bool) -> some View {
        Text(t)
            .font(.system(size: 9.5, weight: .heavy)).tracking(1)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(active ? SO.headingAccent : Color.white.opacity(0.06)))
            .foregroundStyle(active ? .white : .white.opacity(0.6))
    }
}

private struct HeadingDual: View {
    @ObservedObject var loc: LocationSensorManager
    var body: some View {
        SOVariant(sensor: "HEADING", accent: SO.headingAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                HStack(spacing: 30) {
                    halfArc("MAGNETIC", deg: loc.magneticHeading,
                            color: Color(red: 0.38, green: 0.64, blue: 0.98))
                    halfArc("TRUE", deg: loc.trueHeading,
                            color: Color(red: 0.97, green: 0.44, blue: 0.44))
                }
                Spacer().frame(height: 32)
                SOLabel(text: "MAGNETIC DECLINATION", size: 9)
                declinationBar.padding(.horizontal, 18).padding(.top, 10)
                Spacer().frame(height: 20)
                SOLabel(text: "DECLINATION · 30 s", size: 9).padding(.horizontal, 18)
                SOSpark(accent: SO.headingAccent, amp: 0.35, freq: 0.5)
                    .frame(height: 48)
                    .padding(.horizontal, 18).padding(.top, 6)
                Spacer().frame(height: 100)
            }
        }
    }
    private func halfArc(_ label: String, deg: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            SOLabel(text: label, size: 9, opacity: 0.85).foregroundStyle(color)
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(.white.opacity(0.08), lineWidth: 3)
                    .rotationEffect(.degrees(180))
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: max(0, min(0.5, (deg.truncatingRemainder(dividingBy: 360)) / 720)))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .frame(width: 110, height: 110)
                Rectangle().fill(.white).frame(width: 2, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(deg))
                Circle().fill(.white).frame(width: 8, height: 8)
            }
            Text(String(format: "%.1f°", deg))
                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
    private var declinationBar: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                .frame(height: 60)
            Rectangle().fill(.white.opacity(0.15)).frame(width: 1, height: 60)
            Rectangle().fill(SO.headingAccent)
                .frame(width: 32, height: 32)
                .cornerRadius(4)
                .shadow(color: SO.headingAccent, radius: 14)
                .offset(x: 16)
            VStack {
                Spacer()
                Text("+6.3°")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 4)
            }
            .frame(height: 60)
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 03 — ACCELEROMETER
// ════════════════════════════════════════════════════════════

struct SOAccel: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: AccelGForce(motion: motion)
        case 1: AccelLevel(motion: motion)
        case 2: AccelScope(motion: motion)
        default: AccelShake(motion: motion)
        }
    }
}

private struct AccelGForce: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ACCEL", accent: SO.accelAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "G-Force · Lateral")
                Spacer().frame(height: 16)
                gBall.frame(width: 280, height: 280)
                Spacer().frame(height: 16)
                SOLabel(text: "PEAK 1.42 G", size: 9)
                Text(String(format: "%.2f", motion.accX * motion.accX + motion.accY * motion.accY + motion.accZ * motion.accZ))
                    .font(.system(size: 60, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                + Text("g").font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                SOTickerBar(accent: SO.accelAccent, items: [
                    .init(label: "MAG", value: String(format: "%.2f g", sqrt(motion.accX*motion.accX + motion.accY*motion.accY + motion.accZ*motion.accZ))),
                    .init(label: "MAX", value: "1.42 g", accent: true),
                    .init(label: "RMS", value: "0.21 g"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var gBall: some View {
        ZStack {
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { r in
                Circle()
                    .strokeBorder(r == 1.0 ? Color.red : .white.opacity(0.12),
                                  style: .init(lineWidth: 1, dash: r == 1.0 ? [] : [2, 4]))
                    .frame(width: 260 * r, height: 260 * r)
            }
            Rectangle().fill(.white.opacity(0.1)).frame(width: 260, height: 0.5)
            Rectangle().fill(.white.opacity(0.1)).frame(width: 0.5, height: 260)
            // ball
            let x = max(-1, min(1, motion.accX / 2)) * 110
            let y = max(-1, min(1, motion.accY / 2)) * 110
            Circle().fill(SO.accelAccent.opacity(0.15)).frame(width: 44, height: 44)
                .offset(x: CGFloat(x), y: CGFloat(y))
            Circle().fill(SO.accelAccent).frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                .shadow(color: SO.accelAccent, radius: 14)
                .offset(x: CGFloat(x), y: CGFloat(y))
        }
    }
}

private struct AccelLevel: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ACCEL", accent: SO.accelAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Spirit Level · Tilt")
                Spacer().frame(height: 14)
                vial
                Spacer().frame(height: 30)
                HStack {
                    tiltCol("X TILT", value: -motion.accX * 90)
                    Spacer()
                    tiltCol("Y TILT", value: -motion.accY * 90)
                }
                .padding(.horizontal, 40)
                Spacer().frame(height: 28)
                SOLabel(text: "HORIZONTAL · X-AXIS", size: 9).padding(.horizontal, 18)
                horizontalVial.frame(height: 32)
                    .padding(.horizontal, 18).padding(.top, 8)
                Spacer().frame(height: 110)
            }
        }
    }
    private var vial: some View {
        ZStack {
            Circle().fill(
                RadialGradient(colors: [Color(red: 0.10, green: 0.19, blue: 0.31),
                                        Color(red: 0.04, green: 0.08, blue: 0.14)],
                               center: .center, startRadius: 0, endRadius: 130))
                .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1.5))
                .frame(width: 260, height: 260)
            Rectangle().fill(.white.opacity(0.18)).frame(width: 260, height: 1)
            Rectangle().fill(.white.opacity(0.18)).frame(width: 1, height: 260)
            Circle().strokeBorder(.white.opacity(0.18), style: .init(lineWidth: 1, dash: [3, 4]))
                .frame(width: 68, height: 68)
            // bubble
            let bx = max(-1, min(1, -motion.accX)) * 70
            let by = max(-1, min(1, -motion.accY)) * 70
            Circle().fill(.white.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(Circle().fill(.white.opacity(0.5)).frame(width: 24, height: 24).offset(x: -8, y: -8))
                .offset(x: CGFloat(bx), y: CGFloat(by))
        }
    }
    private func tiltCol(_ l: String, value: Double) -> some View {
        VStack(spacing: 4) {
            SOLabel(text: l, size: 9)
            Text(String(format: "%+.1f°", value))
                .font(.system(size: 36, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
    private var horizontalVial: some View {
        ZStack(alignment: .center) {
            Capsule()
                .fill(LinearGradient(colors: [Color(red: 0.04, green: 0.08, blue: 0.14),
                                              Color(red: 0.10, green: 0.19, blue: 0.31),
                                              Color(red: 0.04, green: 0.08, blue: 0.14)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
            Rectangle().fill(.white.opacity(0.18)).frame(width: 1)
            Circle().fill(.white.opacity(0.25)).frame(width: 24, height: 24)
                .overlay(Circle().strokeBorder(.white, lineWidth: 1))
                .offset(x: CGFloat(max(-1, min(1, -motion.accX)) * 80))
        }
    }
}

private struct AccelScope: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "ACCEL", accent: SO.accelAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Triple-Axis · Oscilloscope")
                Spacer().frame(height: 18)
                ForEach(["X","Y","Z"], id: \.self) { axis in
                    let color: Color = axis == "X" ? .red : axis == "Y" ? .green : SO.accelAccent
                    let amp: Double = axis == "X" ? abs(motion.accX) : axis == "Y" ? abs(motion.accY) : abs(motion.accZ)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            SOLabel(text: axis, size: 9, opacity: 0.85)
                                .foregroundStyle(color)
                            Spacer()
                            Text(String(format: "%+.3f g", axisValue(axis: axis)))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(color)
                        }
                        SOSpark(accent: color, amp: 0.4 + amp * 0.5, freq: axis == "Z" ? 0.7 : 1.2)
                            .frame(height: 60)
                            .background(.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 18).padding(.vertical, 8)
                }
                Spacer()
                SOTickerBar(accent: SO.accelAccent, items: [
                    .init(label: "FREQ", value: "60 Hz"),
                    .init(label: "RES",  value: "16 bit"),
                    .init(label: "RANGE", value: "±2 g", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private func axisValue(axis: String) -> Double {
        switch axis {
        case "X": return motion.accX
        case "Y": return motion.accY
        default:  return motion.accZ
        }
    }
}

private struct AccelShake: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        let mag = sqrt(motion.accX*motion.accX + motion.accY*motion.accY + motion.accZ*motion.accZ)
        SOVariant(sensor: "ACCEL", accent: SO.accelAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Shake Detector")
                Text(mag > 1.6 ? "SHAKE" : "STILL")
                    .font(.system(size: 96, weight: .heavy).width(.condensed))
                    .tracking(4)
                    .foregroundStyle(mag > 1.6 ? SO.accelAccent : .white.opacity(0.4))
                    .shadow(color: mag > 1.6 ? SO.accelAccent : .clear, radius: 28)
                Spacer().frame(height: 12)
                SOLabel(text: "PEAK HISTORY", size: 9).padding(.horizontal, 18)
                HStack(spacing: 4) {
                    ForEach(0..<24, id: \.self) { i in
                        let h = (sin(Double(i) * 0.6) + 1.2) * 30
                        Capsule().fill(SO.accelAccent.opacity(0.7))
                            .frame(width: 10, height: max(6, h))
                    }
                }
                .frame(height: 80, alignment: .bottom)
                .padding(.horizontal, 18).padding(.top, 8)
                Spacer()
                SOTickerBar(accent: SO.accelAccent, items: [
                    .init(label: "THRESH", value: "1.60 g"),
                    .init(label: "CURR",   value: String(format: "%.2f g", mag), accent: mag > 1.6),
                    .init(label: "EVENTS", value: "12"),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Sensor 04 — GYROSCOPE
// ════════════════════════════════════════════════════════════

struct SOGyro: View {
    let variant: Int
    @EnvironmentObject var motion: MotionSensorManager
    var body: some View {
        switch variant {
        case 0: GyroCockpit(motion: motion)
        case 1: GyroGimbal(motion: motion)
        case 2: GyroSpin(motion: motion)
        default: GyroIntegrator(motion: motion)
        }
    }
}

private struct GyroCockpit: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "GYRO", accent: SO.gyroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Attitude Indicator")
                Spacer().frame(height: 24)
                horizon.frame(width: 260, height: 260)
                Spacer().frame(height: 24)
                HStack {
                    metric("PITCH", value: motion.pitch * 180 / .pi)
                    Spacer()
                    metric("ROLL",  value: motion.roll * 180 / .pi)
                    Spacer()
                    metric("YAW",   value: motion.yaw * 180 / .pi)
                }
                .padding(.horizontal, 28)
                Spacer().frame(height: 110)
            }
        }
    }
    private var horizon: some View {
        ZStack {
            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 2)
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.40, green: 0.62, blue: 0.85),
                                              Color(red: 0.40, green: 0.62, blue: 0.85),
                                              Color(red: 0.55, green: 0.40, blue: 0.20),
                                              Color(red: 0.55, green: 0.40, blue: 0.20)],
                                     startPoint: .top, endPoint: .bottom))
                .clipShape(Circle())
                .rotationEffect(.degrees(motion.roll * 180 / .pi))
                .offset(y: CGFloat(motion.pitch) * 60)
                .clipShape(Circle())
            // ladder
            ForEach([-30, -20, -10, 10, 20, 30], id: \.self) { p in
                Rectangle().fill(.white.opacity(0.4))
                    .frame(width: p == 0 ? 100 : 60, height: 1)
                    .offset(y: CGFloat(-p) * 3)
            }
            Triangle().fill(SO.gyroAccent).frame(width: 16, height: 14)
                .offset(y: -120)
            Rectangle().fill(.white).frame(width: 60, height: 2)
            Circle().fill(.white).frame(width: 6, height: 6)
        }
    }
    private func metric(_ l: String, value: Double) -> some View {
        VStack(spacing: 2) {
            SOLabel(text: l, size: 9)
            Text(String(format: "%+.0f°", value))
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundStyle(SO.gyroAccent)
        }
    }
}

private struct GyroGimbal: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "GYRO", accent: SO.gyroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "3-Axis Gimbal")
                Spacer().frame(height: 30)
                gimbal.frame(width: 280, height: 280)
                Spacer()
                SOTickerBar(accent: SO.gyroAccent, items: [
                    .init(label: "ROLL",  value: String(format: "%.0f°", motion.roll * 180 / .pi)),
                    .init(label: "PITCH", value: String(format: "%.0f°", motion.pitch * 180 / .pi)),
                    .init(label: "YAW",   value: String(format: "%.0f°", motion.yaw * 180 / .pi), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var gimbal: some View {
        ZStack {
            Circle().strokeBorder(SO.gyroAccent.opacity(0.6), lineWidth: 2)
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(motion.roll * 180 / .pi))
            Circle().strokeBorder(SO.gyroAccent.opacity(0.4), lineWidth: 2)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(motion.pitch * 180 / .pi))
            Circle().strokeBorder(SO.gyroAccent.opacity(0.25), lineWidth: 2)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(motion.yaw * 180 / .pi))
            // marker dots
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(SO.gyroAccent)
                    .frame(width: 10, height: 10)
                    .shadow(color: SO.gyroAccent, radius: 6)
                    .offset(y: -CGFloat([130, 100, 70][i]))
                    .rotationEffect(.degrees([motion.roll, motion.pitch, motion.yaw][i] * 180 / .pi))
            }
            Circle().fill(.white).frame(width: 8, height: 8)
        }
    }
}

private struct GyroSpin: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        let mag = sqrt(motion.rotX*motion.rotX + motion.rotY*motion.rotY + motion.rotZ*motion.rotZ)
        SOVariant(sensor: "GYRO", accent: SO.gyroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Spin Rate · rad/s")
                Spacer().frame(height: 16)
                SORadialGauge(value: min(1.0, mag / 5.0),
                              label: "rotation rate",
                              valueText: String(format: "%.2f", mag),
                              accent: SO.gyroAccent, ticks: 14, size: 240)
                Spacer().frame(height: 24)
                axisStrip
                Spacer()
                SOTickerBar(accent: SO.gyroAccent, items: [
                    .init(label: "X",   value: String(format: "%.2f", motion.rotX)),
                    .init(label: "Y",   value: String(format: "%.2f", motion.rotY)),
                    .init(label: "Z",   value: String(format: "%.2f", motion.rotZ), accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var axisStrip: some View {
        HStack(spacing: 8) {
            ForEach(["X","Y","Z"], id: \.self) { axis in
                let val = axis == "X" ? motion.rotX : axis == "Y" ? motion.rotY : motion.rotZ
                let color: Color = axis == "X" ? .red : axis == "Y" ? .green : SO.gyroAccent
                VStack(spacing: 4) {
                    Text(axis).font(.system(size: 11, weight: .heavy)).foregroundStyle(color)
                    GeometryReader { geo in
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.06))
                            let w = max(2, abs(val) / 5.0 * geo.size.width / 2)
                            RoundedRectangle(cornerRadius: 3).fill(color)
                                .frame(width: w)
                                .offset(x: CGFloat(val < 0 ? -w/2 : w/2))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct GyroIntegrator: View {
    @ObservedObject var motion: MotionSensorManager
    var body: some View {
        SOVariant(sensor: "GYRO", accent: SO.gyroAccent) {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)
                SOLabel(text: "Total Rotations · session")
                Spacer().frame(height: 14)
                SOHero(text: String(format: "%.1f", abs(motion.rotZ) * 12), size: 130, color: SO.gyroAccent,
                       glow: SO.gyroAccent)
                SOTextLabel("REVOLUTIONS")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer().frame(height: 24)
                ringStack.frame(width: 260, height: 260)
                Spacer()
                SOTickerBar(accent: SO.gyroAccent, items: [
                    .init(label: "X TURNS", value: "12.4"),
                    .init(label: "Y TURNS", value: "8.3"),
                    .init(label: "Z TURNS", value: "21.7", accent: true),
                ])
                .padding(.horizontal, 18)
                Spacer().frame(height: 110)
            }
        }
    }
    private var ringStack: some View {
        SOTick { t in
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .trim(from: 0, to: 0.78)
                        .stroke(SO.gyroAccent.opacity(0.7 - Double(i) * 0.18),
                                style: .init(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(t * (40 + Double(i) * 25)))
                        .frame(width: CGFloat(220 - i * 60), height: CGFloat(220 - i * 60))
                }
            }
        }
    }
}
