import Foundation

enum SensorCategory: String, CaseIterable, Identifiable {
    case motion = "Motion"
    case location = "Location"
    case environment = "Environment"
    case system = "System"
    case health = "Health"
    case connectivity = "Connectivity"
    case camera = "Camera & Audio"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .motion: return "gyroscope"
        case .location: return "location.fill"
        case .environment: return "thermometer.medium"
        case .system: return "cpu"
        case .health: return "heart.fill"
        case .connectivity: return "wifi"
        case .camera: return "camera.fill"
        }
    }

    var color: String {
        switch self {
        case .motion: return "blue"
        case .location: return "green"
        case .environment: return "orange"
        case .system: return "purple"
        case .health: return "red"
        case .connectivity: return "cyan"
        case .camera: return "yellow"
        }
    }
}

struct SensorData: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let unit: String
    let icon: String
    let color: String
    let detail: String
}
