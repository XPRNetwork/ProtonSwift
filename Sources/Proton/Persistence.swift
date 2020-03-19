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
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
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
    
    func get<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = defaults.object(forKey: key) as? Data else {
            return nil
        }
        
        guard let decodedObject = try? decoder.decode(object, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func set<T: Codable>(_ object: T, forKey key: String) {
        
        guard let encodedData = try? encoder.encode(object) else {
            return
        }
        
        defaults.set(encodedData, forKey: key)
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

