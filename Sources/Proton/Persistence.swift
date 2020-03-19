//
//  Persistence.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

class Persistence {
    
    private var defaults: UserDefaults
    
    init() {
        defaults = UserDefaults.standard
    }
    
    func data(forKey key: String) -> Data? {
        return defaults.data(forKey: key)
    }
    
    func object(forKey key: String) -> Any? {
        return defaults.object(forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }
    
    func integer(forKey key: String) -> Int {
        return defaults.integer(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }
    
    func get<T>(_ object: T.Type, forKey key: String) -> T? {
        return defaults.object(forKey: key) as? T
    }
    
    func set<T>(_ object: T, forKey key: String) {
        defaults.set(object, forKey: key)
        defaults.synchronize()
    }
    
    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
    
    func clear() {
        
        guard let appDomain = Bundle.main.bundleIdentifier else {
            return
        }
        
        defaults.removePersistentDomain(forName: appDomain)
        defaults.synchronize()
        
    }
    
}

