//
//  Persistence.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import Valet
import EasyStash

class Persistence {
    
    private var defaults: UserDefaults
    private var valet: Valet
    public var disk: Storage
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    init(keyChainIdentifier: String) {
        self.defaults = UserDefaults.standard
        self.valet = Valet.valet(with: Identifier(nonEmpty: keyChainIdentifier)!, accessibility: .whenUnlocked)
        self.disk = try! Storage(options: Options())
    }
    
    // MARK: - Disk
    
    func getDiskItem<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        if self.disk.exists(forKey: key) {
            do {
                return try self.disk.load(forKey: key, as: object)
            } catch {
                print("ERROR: \(error.localizedDescription)")
            }
        }
        
        return nil
        
    }
    
    func setDiskItem<T: Codable>(_ object: T, forKey key: String) {
        
        if self.disk.exists(forKey: key) {
            deleteDiskItem(forKey: key)
            do {
                try self.disk.save(object: object, forKey: key)
            } catch {
                print("ERROR: \(error.localizedDescription)")
            }
        }

    }
    
    func deleteDiskItem(forKey key: String) {
        
        if self.disk.exists(forKey: key) {
            do {
                try self.disk.remove(forKey: key)
            } catch {
                print("ERROR: \(error.localizedDescription)")
            }
        }
        
    }
    
    func clearDisk() {
        
        do {
            try self.disk.removeAll()
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        
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
    
    func clearDefaults() {
        
        guard let appDomain = Bundle.main.bundleIdentifier else {
            return
        }
        
        self.defaults.removePersistentDomain(forName: appDomain)
        self.defaults.synchronize()
        
    }
    
    // MARK: - Keychain
    
    func getKeychainItem<T: Codable>(_ object: T.Type, forKey key: String) -> T? {
        
        guard let data = self.valet.object(forKey: key) else {
            return nil
        }
        
        guard let decodedObject = try? self.decoder.decode(object, from: data) else {
            return nil
        }
        
        return decodedObject
    }
    
    func setKeychainItem<T: Codable>(_ object: T, forKey key: String) {
        
        guard let encodedData = try? self.encoder.encode(object) else {
            return
        }
        
        self.valet.set(object: encodedData, forKey: key)
        
    }
    
    func deleteKeychainItem(forKey key: String) {
        _ = self.valet.removeObject(forKey: key)
    }
    
    func clearKeychain() {
        _ = self.valet.removeAllObjects()
    }
    
}
