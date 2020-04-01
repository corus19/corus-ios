//
//  AppDIContainer.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

final class DIContainer {

    static let shared = DIContainer()

    // MARK: - Network
    lazy var apiDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(baseURL: AppConfiguration.apiBaseURL)

        let apiDataNetwork = DefaultNetworkService(config: config, sessionManager: authNetworkSessionManager)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()

    var authNetworkSessionManager = AuthNetworkSessionManager()
}
