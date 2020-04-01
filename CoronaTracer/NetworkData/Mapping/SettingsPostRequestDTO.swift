//
//  SettingsPostRequestDTO.swift
//  CoronaTracer
//
//  Created by Arifin Firdaus on 29/03/20.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation


struct SettingsPostRequestDTO: Encodable {
    let country: String
    let keys: [String]
}

extension SettingsPostRequestDTO: Decodable {
    
}

struct SettingsPostResponseDTO: Decodable {
    let regionURL: String?
    
    enum CodingKeys: String, CodingKey {
        case regionURL = "regionUrl"
    }
}

