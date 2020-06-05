//
//  Persistence.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import KeychainAccess

class Persistence {
    
    private var defaults: UserDefaults
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    static let pkService = "proton.swfit"
    static let defaultsPrefix = "proton.swift"
    
    init() {
        self.defaults = UserDefaults.standard
    }
    
    // MARK: - User Defaults
    
    func getDefaultsItem<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = self.defaults.object(forKey: Persistence.defaultsPrefix+key) as? Data else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object.self, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func setDefaultsItem<T: Codable>(_ object: T, forKey key: String) {
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        self.defaults.set(encodedData, forKey: Persistence.defaultsPrefix+key)
        self.defaults.synchronize()
    }
    
    func deleteDefaultsItem(forKey key: String) {
        self.defaults.removeObject(forKey: Persistence.defaultsPrefix+key)
        self.defaults.synchronize()
    }
    
    // MARK: - Keychain
    
    func setKeychainItem<T: Codable>(_ object: T, forKey key: String, service: String = pkService,
                                     synchronizable: Bool = false,
                                     accessibility: Accessibility = .whenUnlocked,
                                     authenticationPolicy: AuthenticationPolicy = .userPresence,
                                     completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        
        let keychain = Keychain(service: service)
                        .synchronizable(synchronizable)
                        .accessibility(accessibility, authenticationPolicy: authenticationPolicy)
        
        do {
            try keychain.set(encodedData, key: key)
            completion(.success(true))
        } catch {
            completion(.failure(ProtonError.error("MESSAGE => \(error.localizedDescription)")))
        }

    }
    
    func getKeychainItem<T: Codable>(_ object: T.Type, forKey key: String, service: String = pkService) -> T? {
        
        let keychain = Keychain(service: service)

        guard let data = try? keychain.getData(key) else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object.self, from: data) else {
            return nil
        }
        
        return decodedObject

    }
    
    func deleteKeychainItem<T: Codable>(_ object: T.Type, forKey key: String, service: String = pkService,
                                        completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        let keychain = Keychain(service: service)
        
        do {
            try keychain.remove(key)
            completion(.success(true))
        } catch {
            completion(.failure(ProtonError.error("MESSAGE => \(error.localizedDescription)")))
        }

    }
    
}
