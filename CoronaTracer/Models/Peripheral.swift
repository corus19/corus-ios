//
//  Peripheral.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct Peripheral {

    public let name: String?
    public let bluetoothSignature: String
    public let rssi: Int
    public let txPower: Int?
    public let lat: Double? = nil
    public let lng: Double? = nil
    public let timestamp: Double

    init(_ peripheral: CBPeripheral, bluetoothSignature: String, advertisementData: [String: Any], rssi: Int) {
        self.bluetoothSignature = bluetoothSignature
        self.name = peripheral.name
        self.rssi = rssi
        self.txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
        self.timestamp = advertisementData["kCBAdvDataTimestamp"] as? Double ?? Date().timeIntervalSince1970
    }
}

extension CBPeripheral {
    public func toDomain(bluetoothSignature: String, advertisementData: [String: Any], rssi: Int) -> Peripheral {
        return Peripheral(self, bluetoothSignature: bluetoothSignature, advertisementData: advertisementData, rssi: rssi)
    }
}

extension Peripheral {

    public var represntableData: String {
        return """
        "bluetoothSignature": \(bluetoothSignature) "NAME": \(name ?? "unknown") "RSSI": "\(rssi)", "TXPower": "\(txPower?.description ?? "")", "LAT": "\(lat?.description ?? "")", LNG: "\(lng?.description ?? ""), TIMESTAMP: "\(timestamp.description)"
        """
    }
}
