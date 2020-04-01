//
//  PeripheralsPostRequestDTO.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

struct PeripheralsPostRequestDTO: Encodable {
    let deviceRequests: [PeripheralDTO]

    struct PeripheralDTO: Encodable {
        public let name: String?
        public let bluetoothSignature: String
        public let rssi: Int
        public let txPower: Int?
        public let lat: Double?
        public let lng: Double?
        public let timestamp: Double?

        init(peripheral: Peripheral) {
            self.name = peripheral.name
            self.bluetoothSignature = peripheral.bluetoothSignature
            self.rssi = peripheral.rssi
            self.txPower = peripheral.txPower
            self.lat = peripheral.lat
            self.lng = peripheral.lng
            self.timestamp = peripheral.timestamp
        }
    }

    init(peripherals: [Peripheral]) {
        deviceRequests = peripherals.map(PeripheralDTO.init)
    }
}

struct PeripheralsPostResponseDTO: Decodable {

}
