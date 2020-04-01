//
//  BluetoothScannerService.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import CoreBluetooth

public enum BluetoothError: Error {
    case notEnabled
    case unauthorized
    case unknown
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notEnabled:
            return NSLocalizedString("Bluetooth Disabled Make sure your Bluetooth is turned on", comment: "")
        case .unauthorized:
            return NSLocalizedString("Please enable your bluetooth in settings for this app", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "")
        }
    }
}

class BluetoothScannerService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    struct PeripheralInfo {
        let peripheral: CBPeripheral
        let discoveredDate: Date
        let advertisementData: [String : Any]
        let rssi: NSNumber
    }

    public typealias DidStartScanningClosure = () -> Void
    public typealias DidFailStartClosure = (BluetoothError) -> Void

    static let shared = BluetoothScannerService()

    var isScanning: Bool { centralManager?.isScanning ?? false }
    private var state: CBManagerState = .unknown
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var peripheralCoreDataStorage = PeripheralCoreDataStorage()
    private var knownPeripherals: [PeripheralInfo] = []
    private var onStartScanning: DidStartScanningClosure?
    private var onFailStart: DidFailStartClosure?
    private var recentlyAddedCharacteristic: [(CBUUID, Date)] = []

    override init() {
        super.init()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.state = central.state
        switch central.state {
        case .poweredOn:
            setupOurPeripheral(with: User.bluetoothSignature)
            scanForPeripherals()
        case .poweredOff:
            onFailStart?(.notEnabled)
            onFailStart = nil
            central.stopScan()
        case .unauthorized:
            onFailStart?(.unauthorized)
            onFailStart = nil
            central.stopScan()
        case .unsupported:
            onFailStart?(.unknown)
            onFailStart = nil
            print("Error: note you should run only on real device")
        default: break
        }
    }

    func startScanning(onStartScanning: DidStartScanningClosure? = nil, onFailStarting: DidFailStartClosure? = nil) {

        centralManager = CBCentralManager(delegate: self,
                                          queue: .main,
                                          options: [CBCentralManagerOptionRestoreIdentifierKey: "myCentralManager"])

        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)

        onStartScanning.map { self.onStartScanning = $0 }
        onFailStarting.map { self.onFailStart = $0 }
    }

    open func stopScanning() {
        self.centralManager?.stopScan()
    }

    private func scanForPeripherals() {
        centralManager?.scanForPeripherals(withServices: [serviceId], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]) // to make all discoveries in one event

        onStartScanning?()
        onStartScanning = nil
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        knownPeripherals = knownPeripherals.filter { $0.peripheral != peripheral }
        knownPeripherals.append(.init(peripheral: peripheral, discoveredDate: Date(), advertisementData: advertisementData, rssi: RSSI))
        centralManager?.connect(peripheral, options: nil)

        print("Discovered peripheral %s at %d", String(describing: peripheral.name), RSSI.intValue)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceId])
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        knownPeripherals = knownPeripherals.filter { $0.peripheral != peripheral }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("peripheral didDiscoverServices error: \(error.localizedDescription)")
            centralManager?.cancelPeripheralConnection(peripheral)
        } else {
            if let services = peripheral.services, let service = services.first(where: { $0.uuid == serviceId }) {
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.uuid == serviceId, let characteristics = service.characteristics, !characteristics.isEmpty else { return }

        let peripherals: [Peripheral] = characteristics.compactMap { characteristic in
            let peripheralInfo = knownPeripherals.first { $0.peripheral == peripheral }
            guard let peripheralData = peripheralInfo else { return nil }

            if let (id, date) = (recentlyAddedCharacteristic.first { $0.0 == characteristic.uuid }), Date().timeIntervalSince(date) < 60 {
                print("Skipping recently added bluetoothSignature \(id)")
                return nil
            }

            let peripheralModel = peripheral.toDomain(bluetoothSignature: characteristic.uuid.uuidString,
                                                      advertisementData: peripheralData.advertisementData,
                                                      rssi: peripheralData.rssi.intValue)
            print("Came in contact with UserId: \(characteristic.uuid.uuidString)")
            recentlyAddedCharacteristic = recentlyAddedCharacteristic.filter { $0.0 != characteristic.uuid }
            recentlyAddedCharacteristic.append((characteristic.uuid, Date()))

            return peripheralModel
        }

        //centralManager?.cancelPeripheralConnection(peripheral)

        guard !peripherals.isEmpty else { return }
        peripheralCoreDataStorage.save(peripherals: peripherals, completion: { _ in })
        SyncStorageManager.shared.sync()

        LocalNotificationCenterService.shared.scheduleNotification(title: "User", body: "Came in contact with User with bluetoothSignature \(peripherals.first?.bluetoothSignature ?? "")")

        if recentlyAddedCharacteristic.count > 1000 { recentlyAddedCharacteristic.removeAll() }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                             didModifyServices invalidatedServices: [CBService]) {}
}


extension BluetoothScannerService: CBPeripheralManagerDelegate {

    func setupOurPeripheral(with bluetoothSignature: UUID? = User.bluetoothSignature) {

        guard let bluetoothSignature = bluetoothSignature,
            let peripheralManager = peripheralManager else { return }

        let transferCharacteristic = CBMutableCharacteristic(type: CBUUID(nsuuid: bluetoothSignature),
                                                             properties: [.read],
                                                             value: nil,
                                                             permissions: [.readable])

        let service = CBMutableService(type: serviceId, primary: true)
        service.characteristics = [transferCharacteristic]
        peripheralManager.removeAllServices() // important, we only need one service
        peripheralManager.add(service)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("PerformerUtility.publishServices() returned error: \(error.localizedDescription)")
        } else {

        }
    }

    // MARK: - Mostly logs
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [serviceId],
                                                 CBAdvertisementDataLocalNameKey: "CORTRPeripheralApp"])
            print("Current Bluetooth State:  poweredOn")
        } else if peripheral.state == .poweredOff {
            peripheralManager?.stopAdvertising()
            print("Current Bluetooth State:  poweredOff")
        }
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("peripheralManagerDidStartAdvertising returned error: \(error.localizedDescription)")
        } else {
            print("peripheralManagerDidStartAdvertising")
        }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {

        guard let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }

        for peripheral in restoredPeripherals {
            peripheral.delegate = self
            peripheral.discoverServices([serviceId])
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

    }
}
