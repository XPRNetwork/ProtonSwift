//
//  Persistence.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import Valet

class Persistence {
    
    private var defaults: UserDefaults
    private var valet: Valet
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    init(keyChainIdentifier: String) {
        self.defaults = UserDefaults.standard
        self.valet = Valet.valet(with: Identifier(nonEmpty: keyChainIdentifier)!, accessibility: .whenUnlocked)
    }
    
    // MARK: - User Defaults
    
    func get<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = self.defaults.object(forKey: key) as? Data else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func set<T: Codable>(_ object: T, forKey key: String) {
        
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        
        self.defaults.set(encodedData, forKey: key)
        self.defaults.synchronize()
    }
    
    func removeObject(forKey key: String) {
        self.defaults.removeObject(forKey: key)
        self.defaults.synchronize()
    }
    
    func clear() {
        
        guard let appDomain = Bundle.main.bundleIdentifier else {
            return
        }
        
        self.defaults.removePersistentDomain(forName: appDomain)
        self.defaults.synchronize()
        
    }
    
    // MARK: - Keychain
    
    func getKeychain<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = self.valet.object(forKey: key) else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func setKeychain<T: Codable>(_ object: T, forKey key: String) {
        
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        
        self.valet.set(object: encodedData, forKey: key)
        
    }
    
}
