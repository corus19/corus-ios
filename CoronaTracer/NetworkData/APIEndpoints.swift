//
//  APIEndpoints.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

struct APIEndpoints {

    static let headerParamaters = ["Content-Type": "application/json"]

    static func postBulkContactDetails(with peripheralsRequestDTO: PeripheralsPostRequestDTO) -> Endpoint<PeripheralsPostResponseDTO> {
        return Endpoint(path: "v1/api/user/bulkContactDetails",
                        method: .post,
                        headerParamaters: headerParamaters,
                        bodyParamatersEncodable: peripheralsRequestDTO)
    }

    static func auth(with authRequestDTO: AuthRequestDTO) -> Endpoint<AuthResponseDTO> {

        return Endpoint(path: "v1/api/auth/login",
                        method: .post,
                        headerParamaters: headerParamaters,
                        bodyParamatersEncodable: authRequestDTO)
    }

    static func postGetSettings(with settingsRequestDTO: SettingsPostRequestDTO) -> Endpoint<SettingsPostResponseDTO> {
        return Endpoint(path: "v1/api/settings",
                               method: .post,
                               headerParamaters: headerParamaters,
                               bodyParamatersEncodable: settingsRequestDTO)
    }
    
    static func putMarkPositive() -> Endpoint<MarkPostiveResponseDTO> {
        let authToken = DIContainer.shared.authNetworkSessionManager.accessToken ?? "2696829a81b1b5827d515ff121700838"
        return Endpoint(path: "v1/api/user/markpositive", method: .put, headerParamaters: [ "authToken" : authToken ])
    }
    
    static func getUserInfo() -> Endpoint<UserResponseDTO> {
        let authToken = DIContainer.shared.authNetworkSessionManager.accessToken ?? "2696829a81b1b5827d515ff121700838"
        return Endpoint(path: "v1/api/user",
                        method: .get,
                        headerParamaters: [ "authToken" : authToken ])
    }
}
