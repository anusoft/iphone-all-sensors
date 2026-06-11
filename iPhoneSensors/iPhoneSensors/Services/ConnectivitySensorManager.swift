import Foundation
import CoreBluetooth
import Network
import CoreTelephony
import Combine

@MainActor
class ConnectivitySensorManager: NSObject, ObservableObject {
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var bluetoothStateText: String = "bluetooth.unknown"
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectedPeripherals: [CBPeripheral] = []
    @Published var isScanning = false

    @Published var wifiSSID: String = "N/A"
    @Published var wifiBSSID: String = "N/A"
    @Published var wifiSignalStrength: String = "N/A"
    @Published var networkType: String = "Unknown"
    @Published var isConnectedToNetwork = false

    @Published var cellularCarrier: String = "N/A"
    @Published var cellularRadioTechnology: String = "N/A"

    /// Stream of sensor samples for the logging pipeline.
    let samplePublisher = PassthroughSubject<SensorSample, Never>()

    private var centralManager: CBCentralManager?
    private var monitor: NWPathMonitor?
    private var isStarted = false

    override init() {
        super.init()
        appLog("[Connectivity] ── Connectivity Manager initialized ──")
    }

    func startUpdates() {
        guard !isStarted else {
            appLog("[Connectivity] ⚠ Already started")
            return
        }
        isStarted = true
        appLog("[Connectivity] ── Starting Connectivity Sensors ──")
        let authStatus = CBManager.authorization
        if authStatus == .denied {
            bluetoothState = .unauthorized
            bluetoothStateText = "bluetooth.unauthorized"
            appLog("[Connectivity] ⏭ Bluetooth denied — skipping CBCentralManager")
        } else {
            // Keep the central manager alive so CoreBluetooth can deliver the real
            // state and trigger the system permission prompt when status is not determined.
            centralManager = CBCentralManager(delegate: self, queue: nil)
            appLog("[Connectivity] ✓ CBCentralManager initialized (authorization: \(authStatus.rawValue))")
        }
        startNetworkMonitoring()
        updateCellularInfo()
        appLog("[Connectivity] ✅ Connectivity sensors started")
    }

    func stopUpdates() {
        guard isStarted else { return }
        isStarted = false
        appLog("[Connectivity] ■ Stopping connectivity sensors")
        centralManager?.stopScan()
        isScanning = false
        monitor?.cancel()
    }

    func startScanning() {
        guard centralManager?.state == .poweredOn else {
            appLog("[Connectivity] ❌ Cannot scan - Bluetooth not powered on (state: \(bluetoothStateText))")
            return
        }
        isScanning = true
        discoveredPeripherals = []
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        appLog("[Connectivity] 🔍 Started scanning for BLE peripherals...")
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        appLog("[Connectivity] ■ Stopped scanning (found \(discoveredPeripherals.count) devices)")
    }

    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                let connected = path.status == .satisfied
                self.isConnectedToNetwork = connected
                let typeString: String
                if path.usesInterfaceType(.wifi) {
                    self.networkType = "Wi-Fi"
                    typeString = "wifi"
                } else if path.usesInterfaceType(.cellular) {
                    self.networkType = "Cellular"
                    typeString = "cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.networkType = "Ethernet"
                    typeString = "wired"
                } else if connected {
                    self.networkType = "Other"
                    typeString = "other"
                } else {
                    self.networkType = "Disconnected"
                    typeString = "unavailable"
                }
                self.samplePublisher.send(SensorSample(
                    sensorID: .network,
                    payload: .network(type: typeString, connected: connected)))
                appLog("[Connectivity] 🌐 Network: \(self.networkType) (connected: \(connected))")
            }
        }
        monitor?.start(queue: .global())
        appLog("[Connectivity] ✓ Network monitor started")
    }

    private func updateCellularInfo() {
        #if !targetEnvironment(simulator)
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value {
            cellularCarrier = carrier.carrierName ?? "Unknown"
            appLog("[Connectivity] 📶 Carrier: \(cellularCarrier)")
        }
        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.first?.value {
            cellularRadioTechnology = radioTech
            appLog("[Connectivity] 📶 Radio: \(cellularRadioTechnology)")
        }
        #else
        appLog("[Connectivity] 📶 Running on simulator - cellular info N/A")
        #endif
        samplePublisher.send(SensorSample(
            sensorID: .cellular,
            payload: .cellular(carrier: cellularCarrier, radio: cellularRadioTechnology)))
    }
}

extension ConnectivitySensorManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor in
            bluetoothState = state
            let stateLower: String
            switch state {
            case .unknown:
                bluetoothStateText = "bluetooth.unknown"
                stateLower = "unknown"
            case .resetting:
                bluetoothStateText = "bluetooth.resetting"
                stateLower = "resetting"
            case .unsupported:
                bluetoothStateText = "bluetooth.unsupported"
                stateLower = "unsupported"
            case .unauthorized:
                bluetoothStateText = "bluetooth.unauthorized"
                stateLower = "unauthorized"
            case .poweredOff:
                bluetoothStateText = "bluetooth.poweredoff"
                stateLower = "poweredOff"
            case .poweredOn:
                bluetoothStateText = "bluetooth.poweredon"
                stateLower = "poweredOn"
            @unknown default:
                bluetoothStateText = "bluetooth.unknown"
                stateLower = "unknown"
            }
            samplePublisher.send(SensorSample(
                sensorID: .bluetoothState,
                payload: .bluetoothState(state: stateLower)))
            appLog("[Connectivity] 📡 Bluetooth state: \(bluetoothStateText)")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name
        let uuid = peripheral.identifier.uuidString
        let rssi = RSSI.intValue
        Task { @MainActor in
            if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredPeripherals.append(peripheral)
                appLog("[Connectivity] 📱 Found: \(name ?? "Unknown") [\(peripheral.identifier)] RSSI:\(RSSI)")
            }
            samplePublisher.send(SensorSample(
                sensorID: .bluetoothScan,
                payload: .bluetoothDevice(name: name, uuid: uuid, rssi: rssi)))
        }
    }
}
