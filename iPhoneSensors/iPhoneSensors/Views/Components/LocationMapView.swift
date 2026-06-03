import SwiftUI
import MapKit

struct LocationMapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    let horizontalAccuracy: Double
    let course: Double
    var showsUserLocation: Bool = false
    var mapType: MKMapType = .standard

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = mapType
        map.isPitchEnabled = false
        map.isRotateEnabled = true
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.showsCompass = true
        map.showsScale = true
        map.showsUserLocation = showsUserLocation
        context.coordinator.setupGestureRecognizer(map)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.updateMap(map, coordinate: coordinate, horizontalAccuracy: horizontalAccuracy, course: course)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        private var annotation: MKPointAnnotation?
        private var accuracyCircle: MKCircle?
        private var recenterTimer: Timer?
        private var isUserPanning = false

        func setupGestureRecognizer(_ map: MKMapView) {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan.delegate = self
            map.addGestureRecognizer(pan)
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
                }
            default: break
            }
        }

        func updateMap(_ map: MKMapView, coordinate: CLLocationCoordinate2D, horizontalAccuracy: Double, course: Double) {
            guard CLLocationCoordinate2DIsValid(coordinate) else { return }
            let coord = coordinate

            if annotation == nil {
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                map.addAnnotation(ann)
                annotation = ann
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.annotation?.coordinate = coord
                }
            }

            if let old = accuracyCircle { map.removeOverlay(old) }
            let circle = MKCircle(center: coord, radius: max(1, horizontalAccuracy))
            map.addOverlay(circle)
            accuracyCircle = circle

            if !isUserPanning {
                let region = MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: max(200, horizontalAccuracy * 4),
                    longitudinalMeters: max(200, horizontalAccuracy * 4)
                )
                map.setRegion(region, animated: true)
            }
        }

        func mapView(_ map: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let r = MKCircleRenderer(circle: circle)
                let acc = circle.radius
                if acc < 10 {
                    r.fillColor = UIColor.green.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.green.withAlphaComponent(0.5)
                } else if acc < 30 {
                    r.fillColor = UIColor.yellow.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.yellow.withAlphaComponent(0.5)
                } else {
                    r.fillColor = UIColor.red.withAlphaComponent(0.12)
                    r.strokeColor = UIColor.red.withAlphaComponent(0.5)
                }
                r.lineWidth = 1.5
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "com.allsensors.locationPin"
            let v = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            v.canShowCallout = false
            v.frame = CGRect(x: 0, y: 0, width: 24, height: 24)

            let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            let img = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { ctx in
                let c = ctx.cgContext
                c.setFillColor(UIColor.white.cgColor)
                c.fillEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
                c.setFillColor(UIColor.systemBlue.cgColor)
                c.fillEllipse(in: CGRect(x: 7, y: 7, width: 10, height: 10))
            }
            iv.image = img
            v.addSubview(iv)
            return v
        }
    }
}

extension LocationMapView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
