import Foundation
import CoreBluetooth
import Network
import CoreTelephony
import Combine

@MainActor
class ConnectivitySensorManager: NSObject, ObservableObject {
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var bluetoothStateText: String = "Unknown"
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

    private var centralManager: CBCentralManager?
    private var monitor: NWPathMonitor?

    override init() {
        super.init()
        print("[Connectivity] ── Connectivity Manager initialized ──")
    }

    func startUpdates() {
        print("[Connectivity] ── Starting Connectivity Sensors ──")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startNetworkMonitoring()
        updateCellularInfo()
        print("[Connectivity] ✅ Connectivity sensors started")
    }

    func stopUpdates() {
        print("[Connectivity] ■ Stopping connectivity sensors")
        centralManager?.stopScan()
        isScanning = false
        monitor?.cancel()
    }

    func startScanning() {
        guard centralManager?.state == .poweredOn else {
            print("[Connectivity] ❌ Cannot scan - Bluetooth not powered on (state: \(bluetoothStateText))")
            return
        }
        isScanning = true
        discoveredPeripherals = []
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        print("[Connectivity] 🔍 Started scanning for BLE peripherals...")
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        print("[Connectivity] ■ Stopped scanning (found \(discoveredPeripherals.count) devices)")
    }

    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnectedToNetwork = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.networkType = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.networkType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.networkType = "Ethernet"
                } else {
                    self?.networkType = path.status == .satisfied ? "Other" : "Disconnected"
                }
                print("[Connectivity] 🌐 Network: \(self?.networkType ?? "Unknown") (connected: \(self?.isConnectedToNetwork ?? false))")
            }
        }
        monitor?.start(queue: .global())
        print("[Connectivity] ✓ Network monitor started")
    }

    private func updateCellularInfo() {
        #if !targetEnvironment(simulator)
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value {
            cellularCarrier = carrier.carrierName ?? "Unknown"
            print("[Connectivity] 📶 Carrier: \(cellularCarrier)")
        }
        if let radioTech = networkInfo.serviceCurrentRadioAccessTechnology?.first?.value {
            cellularRadioTechnology = radioTech
            print("[Connectivity] 📶 Radio: \(cellularRadioTechnology)")
        }
        #else
        print("[Connectivity] 📶 Running on simulator - cellular info N/A")
        #endif
    }
}

extension ConnectivitySensorManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothState = central.state
            switch central.state {
            case .unknown: bluetoothStateText = "Unknown"
            case .resetting: bluetoothStateText = "Resetting"
            case .unsupported: bluetoothStateText = "Unsupported"
            case .unauthorized: bluetoothStateText = "Unauthorized"
            case .poweredOff: bluetoothStateText = "Powered Off"
            case .poweredOn: bluetoothStateText = "Powered On"
            @unknown default: bluetoothStateText = "Unknown"
            }
            print("[Connectivity] 📡 Bluetooth state: \(bluetoothStateText)")
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredPeripherals.append(peripheral)
                let name = peripheral.name ?? "Unknown"
                print("[Connectivity] 📱 Found: \(name) [\(peripheral.identifier)] RSSI:\(RSSI)")
            }
        }
    }
}
