//
//  User.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import UIKit

struct User {
    let name: String
}

extension User {
    static var isLoggedInToServer: Bool { DIContainer.shared.authNetworkSessionManager.accessToken != nil && bluetoothSignature != nil }
    static var bluetoothSignature: UUID? {
        get {
            guard let bluetoothSignatureStr = UserDefaults.standard.string(forKey: UserDefaultsConstants.userDefaultsBluetoothSignatureKey) else { return nil }
            return UUID(uuidString: bluetoothSignatureStr)
        }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: UserDefaultsConstants.userDefaultsBluetoothSignatureKey) }
    }
}
