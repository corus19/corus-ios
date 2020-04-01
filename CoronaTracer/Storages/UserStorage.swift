//
//  UserStorage.swift
//  CoronaTracer
//
//  Created by Arifin Firdaus on 30/03/20.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

struct UserStorageKey {
    static var SHOULD_MARKED_AS_POSITIVE = "SHOULD_MARKED_AS_POSITIVE"
}

struct UserStorage {
    public static var shared = UserStorage()
    
    private let defaults = UserDefaults.standard
    
    var shouldMarkedAsPositive: Bool {
        get {
            return defaults.bool(forKey: UserStorageKey.SHOULD_MARKED_AS_POSITIVE)
        }
        set {
            defaults.set(newValue, forKey: UserStorageKey.SHOULD_MARKED_AS_POSITIVE)
        }
    }
}
