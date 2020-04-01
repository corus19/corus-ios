//
//  AuthNetworkSessionManager.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

public class AuthNetworkSessionManager: NetworkSessionManager {

    var accessToken: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsConstants.authTokenServer)
        }
        get {
            UserDefaults.standard.string(forKey: UserDefaultsConstants.authTokenServer)
        }
    }

    public init() {}
    public func request(_ request: URLRequest,
                        completion: @escaping CompletionHandler) -> NetworkCancellable {

        var request = request
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}
