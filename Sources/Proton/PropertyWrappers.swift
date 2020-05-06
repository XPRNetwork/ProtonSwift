//
//  PropertyWrappers.swift
//  
//
//  Created by Jacob Davis on 5/6/20.
//

import Foundation

@propertyWrapper
public struct UserDefault<T: Codable> {
    
    let key: String
    let defaultValue: T
    
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            guard let data = self.defaults.object(forKey: key) as? Data else {
                return defaultValue
            }
            guard let decodedObject = try? self.decoder.decode(T.self, from: data) else {
                return defaultValue
            }
            return decodedObject
        }
        set {
            guard let encodedData = try? self.encoder.encode(newValue) else {
                return
            }
            self.defaults.set(encodedData, forKey: key)
            self.defaults.synchronize()
        }
    }
}
