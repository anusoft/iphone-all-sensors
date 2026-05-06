import Foundation

struct SensorSample: Sendable {
    let sensorID: SensorID
    let wallTime: Date
    let monotonicNs: UInt64
    let payload: SensorPayload

    init(sensorID: SensorID, payload: SensorPayload, wallTime: Date = Date(), monotonicNs: UInt64 = monotonicNow()) {
        self.sensorID = sensorID
        self.wallTime = wallTime
        self.monotonicNs = monotonicNs
        self.payload = payload
    }
}

@inlinable
func monotonicNow() -> UInt64 {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
}
