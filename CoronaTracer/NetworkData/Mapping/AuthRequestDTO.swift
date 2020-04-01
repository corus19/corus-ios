//
//  AuthRequest.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

struct AuthRequestDTO: Encodable {
    public let fbToken: String
}

struct AuthResponseDTO: Decodable {
    let authToken: String
}
