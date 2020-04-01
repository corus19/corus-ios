//
//  UserResponseDTO.swift
//  CoronaTracer
//
//  Created by Arifin Firdaus on 30/03/20.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import UIKit

struct UserResponseDTO: Codable {
    let id: String
    let bluetoothSignature: String
    let deviceID: String?
    let email: String?
    let name: String?
    let covidContactStatus: String?
    let country: String?
    let sendContactDetails: Bool?
    let os: String?
    let osVersion: String?
    let fcmID: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case bluetoothSignature = "bluetoothSignature"
        case deviceID = "deviceId"
        case email = "email"
        case name = "name"
        case covidContactStatus = "covidContactStatus"
        case country = "country"
        case sendContactDetails = "sendContactDetails"
        case os = "os"
        case osVersion = "osVersion"
        case fcmID = "fcmId"
    }
}
