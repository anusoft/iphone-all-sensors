import Foundation

struct DeviceMotionPayload: Codable, Equatable, Sendable {
    let roll, pitch, yaw: Double
    let gravityX, gravityY, gravityZ: Double
    let userAccX, userAccY, userAccZ: Double
    let rotationX, rotationY, rotationZ: Double
    let quatW, quatX, quatY, quatZ: Double
    let calMagX, calMagY, calMagZ: Double
    let calMagAccuracy: Int
}

struct PedometerPayload: Codable, Equatable, Sendable {
    let steps: Int; let distance: Double
    let floorsAscended: Int; let floorsDescended: Int
    let pace: Double?; let cadence: Double?
}

struct ActivityPayload: Codable, Equatable, Sendable {
    let state: String   // walking|running|cycling|automotive|stationary|unknown
    let confidence: Int
}

struct LocationPayload: Codable, Equatable, Sendable {
    let lat: Double, lon: Double, alt: Double
    let speed: Double, course: Double
    let horizAccuracy: Double, vertAccuracy: Double
    let speedAccuracy: Double, courseAccuracy: Double
    let floor: Int?
}

struct AudioPayload: Codable, Equatable, Sendable {
    let category: String; let sampleRate: Double; let channels: Int
    let volume: Double; let inputs: [String]; let outputs: [String]
}

struct CameraPayload: Codable, Equatable, Sendable {
    let hasFront: Bool, hasBack: Bool, hasUltraWide: Bool, hasTelephoto: Bool
    let hasLiDAR: Bool; let zoom: Double
}

struct SessionMarkerPayload: Codable, Equatable, Sendable {
    let kind: String   // start|end|throttleOn|throttleOff
    let note: String?
}

enum SensorPayload: Codable, Equatable, Sendable {
    case acceleration(x: Double, y: Double, z: Double)
    case rotationRate(x: Double, y: Double, z: Double)
    case magneticField(x: Double, y: Double, z: Double, accuracy: Int)
    case deviceMotion(DeviceMotionPayload)
    case altitude(relative: Double, pressure: Double)
    case pedometer(PedometerPayload)
    case activity(ActivityPayload)
    case location(LocationPayload)
    case heading(trueHeading: Double?, magneticHeading: Double, accuracy: Double)
    case proximity(near: Bool)
    case brightness(level: Double)
    case torch(level: Double)
    case audio(AudioPayload)
    case battery(level: Double, state: String)
    case thermal(state: String)
    case lowPower(enabled: Bool)
    case orientation(name: String)
    case disk(total: Int64, free: Int64)
    case uptime(seconds: Double)
    case bluetoothState(state: String)
    case bluetoothDevice(name: String?, uuid: String, rssi: Int)
    case network(type: String, connected: Bool)
    case cellular(carrier: String, radio: String)
    case cameraSnapshot(CameraPayload)
    case health(metric: String, value: Double, unit: String, ts: Date)
    case sessionMarker(SessionMarkerPayload)

    var kind: String {
        switch self {
        case .acceleration: return "acceleration"
        case .rotationRate: return "rotationRate"
        case .magneticField: return "magneticField"
        case .deviceMotion: return "deviceMotion"
        case .altitude: return "altitude"
        case .pedometer: return "pedometer"
        case .activity: return "activity"
        case .location: return "location"
        case .heading: return "heading"
        case .proximity: return "proximity"
        case .brightness: return "brightness"
        case .torch: return "torch"
        case .audio: return "audio"
        case .battery: return "battery"
        case .thermal: return "thermal"
        case .lowPower: return "lowPower"
        case .orientation: return "orientation"
        case .disk: return "disk"
        case .uptime: return "uptime"
        case .bluetoothState: return "bluetoothState"
        case .bluetoothDevice: return "bluetoothDevice"
        case .network: return "network"
        case .cellular: return "cellular"
        case .cameraSnapshot: return "cameraSnapshot"
        case .health: return "health"
        case .sessionMarker: return "sessionMarker"
        }
    }

    /// Column names for the CSV writer. Order MUST match `csvValues`.
    var csvColumns: [String] {
        switch self {
        case .acceleration, .rotationRate:        return ["x", "y", "z"]
        case .magneticField:                       return ["x", "y", "z", "accuracy"]
        case .deviceMotion:
            return ["roll","pitch","yaw","gravityX","gravityY","gravityZ",
                    "userAccX","userAccY","userAccZ","rotationX","rotationY","rotationZ",
                    "quatW","quatX","quatY","quatZ",
                    "calMagX","calMagY","calMagZ","calMagAccuracy"]
        case .altitude:                            return ["relative", "pressure"]
        case .pedometer:                           return ["steps","distance","floorsAsc","floorsDesc","pace","cadence"]
        case .activity:                            return ["state", "confidence"]
        case .location:                            return ["lat","lon","alt","speed","course","horizAcc","vertAcc","speedAcc","courseAcc","floor"]
        case .heading:                             return ["trueHeading","magneticHeading","accuracy"]
        case .proximity:                           return ["near"]
        case .brightness:                          return ["level"]
        case .torch:                               return ["level"]
        case .audio:                               return ["category","sampleRate","channels","volume","inputs","outputs"]
        case .battery:                             return ["level","state"]
        case .thermal:                             return ["state"]
        case .lowPower:                            return ["enabled"]
        case .orientation:                         return ["name"]
        case .disk:                                return ["total","free"]
        case .uptime:                              return ["seconds"]
        case .bluetoothState:                      return ["state"]
        case .bluetoothDevice:                     return ["name","uuid","rssi"]
        case .network:                             return ["type","connected"]
        case .cellular:                            return ["carrier","radio"]
        case .cameraSnapshot:                      return ["hasFront","hasBack","hasUltraWide","hasTelephoto","hasLiDAR","zoom"]
        case .health:                              return ["metric","value","unit","ts"]
        case .sessionMarker:                       return ["kind","note"]
        }
    }

    var csvValues: [String] {
        func s(_ d: Double) -> String { String(d) }
        func si(_ i: Int) -> String { String(i) }
        func sb(_ b: Bool) -> String { b ? "true" : "false" }
        switch self {
        case let .acceleration(x,y,z): return [s(x),s(y),s(z)]
        case let .rotationRate(x,y,z): return [s(x),s(y),s(z)]
        case let .magneticField(x,y,z,acc): return [s(x),s(y),s(z),si(acc)]
        case let .deviceMotion(p):
            return [s(p.roll),s(p.pitch),s(p.yaw),
                    s(p.gravityX),s(p.gravityY),s(p.gravityZ),
                    s(p.userAccX),s(p.userAccY),s(p.userAccZ),
                    s(p.rotationX),s(p.rotationY),s(p.rotationZ),
                    s(p.quatW),s(p.quatX),s(p.quatY),s(p.quatZ),
                    s(p.calMagX),s(p.calMagY),s(p.calMagZ),si(p.calMagAccuracy)]
        case let .altitude(rel,pr):    return [s(rel), s(pr)]
        case let .pedometer(p):        return [si(p.steps), s(p.distance), si(p.floorsAscended), si(p.floorsDescended),
                                                p.pace.map(s) ?? "", p.cadence.map(s) ?? ""]
        case let .activity(p):         return [p.state, si(p.confidence)]
        case let .location(p):         return [s(p.lat),s(p.lon),s(p.alt),s(p.speed),s(p.course),
                                                s(p.horizAccuracy),s(p.vertAccuracy),s(p.speedAccuracy),s(p.courseAccuracy),
                                                p.floor.map(si) ?? ""]
        case let .heading(t,m,a):      return [t.map(s) ?? "", s(m), s(a)]
        case let .proximity(n):        return [sb(n)]
        case let .brightness(l):       return [s(l)]
        case let .torch(l):            return [s(l)]
        case let .audio(p):            return [p.category, s(p.sampleRate), si(p.channels), s(p.volume),
                                                p.inputs.joined(separator: "|"), p.outputs.joined(separator: "|")]
        case let .battery(l,st):       return [s(l), st]
        case let .thermal(st):         return [st]
        case let .lowPower(e):         return [sb(e)]
        case let .orientation(n):      return [n]
        case let .disk(t,f):           return [String(t), String(f)]
        case let .uptime(sec):         return [s(sec)]
        case let .bluetoothState(st):  return [st]
        case let .bluetoothDevice(n,u,r): return [n ?? "", u, si(r)]
        case let .network(t,c):        return [t, sb(c)]
        case let .cellular(c,r):       return [c, r]
        case let .cameraSnapshot(p):   return [sb(p.hasFront),sb(p.hasBack),sb(p.hasUltraWide),sb(p.hasTelephoto),sb(p.hasLiDAR),s(p.zoom)]
        case let .health(m,v,u,t):     return [m, s(v), u, ISO8601DateFormatter().string(from: t)]
        case let .sessionMarker(p):    return [p.kind, p.note ?? ""]
        }
    }
}
