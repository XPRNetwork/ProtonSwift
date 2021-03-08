//
//  Persistence.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import KeychainAccess

class Persistence {
    
    private var defaults: UserDefaults
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    static let pkService = "proton.swift"
    static let defaultsPrefix = "proton.swift"
    
    init() {
        self.defaults = UserDefaults.standard
    }
    
    // MARK: - User Defaults
    
    func getDefaultsItem(forKey key: String) -> [String: Any]? {
        
        guard let data = self.defaults.object(forKey: Persistence.defaultsPrefix+key) as? Data else {
            return nil
        }
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
        } catch {
            return nil
        }

    }
    
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
        
        if Proton.shared.authenticationEnabled() {
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
                completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
            }
        } else {
            completion(.failure(Proton.ProtonError(message: "Device authentication not set")))
        }

    }
    
    func getKeychainItem<T: Codable>(_ object: T.Type, forKey key: String, service: String = pkService) -> T? {
        
        if Proton.shared.authenticationEnabled() {
            let keychain = Keychain(service: service)

            guard let data = try? keychain.getData(key) else {
                return nil
            }
            
            guard let decodedObject = try? self.decoder.decode(object.self, from: data) else {
                return nil
            }
            
            return decodedObject
            
        } else {
            return nil
        }

    }
    
    func deleteKeychainItem(forKey key: String, service: String = pkService,
                                        completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        if Proton.shared.authenticationEnabled() {
            let keychain = Keychain(service: service)
            
            do {
                try keychain.remove(key)
                completion(.success(true))
            } catch {
                completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
            }
        }

    }
    
    func keychainContains(key: String, service: String = pkService) -> Bool {
        
        if Proton.shared.authenticationEnabled() {
            let keychain = Keychain(service: service)
            do {
                return try keychain.contains(key)
            } catch {
                return false
            }
        } else {
            return false
        }
        
    }
    
}
