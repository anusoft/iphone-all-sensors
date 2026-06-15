import Foundation

protocol LogWriter: Actor {
    var bytesWritten: Int64 { get }
    var entriesWritten: Int64 { get }
    var pendingBytes: Int { get }
    var lastErrorMessage: String? { get }
    func write(_ sample: SensorSample) async
    func flush() async
    func close() async
}
