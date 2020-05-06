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
        self.defaults = UserDefaults.standard
    }
    
    // MARK: - User Defaults
    
    func getDefaultsItem<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = self.defaults.object(forKey: key) as? Data else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func setDefaultsItem<T: Codable>(_ object: T, forKey key: String) {
        
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        
        self.defaults.set(encodedData, forKey: key)
        self.defaults.synchronize()
    }
    
    func deleteDefaultsItem(forKey key: String) {
        self.defaults.removeObject(forKey: key)
        self.defaults.synchronize()
    }
    
}
