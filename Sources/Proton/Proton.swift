//
//  Proton.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import Combine
import EOSIO

final public class Proton: ObservableObject {

    public struct Config {

        public var keyChainIdentifier: String
        public var chainProvidersUrl: String
        public var tokenContractsUrl: String
        
        public init(keyChainIdentifier: String, chainProvidersUrl: String,
                    tokenContractsUrl: String) {
            
            self.keyChainIdentifier = keyChainIdentifier
            self.chainProvidersUrl = chainProvidersUrl
            self.tokenContractsUrl = tokenContractsUrl
            
        }
        
    }
    
    public static var config: Config?
    
    public static func setup(_ config: Config) {
        Proton.config = config
    }
    
    public static let shared = Proton()

    var storage: Persistence!
    
    @Published public var chainProviders: Set<ChainProvider> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published public var tokenContracts: Set<TokenContract> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published public var accounts: Set<Account> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    var publicKeys = Set<String>()
    
    private init() {
        
        guard let config = Proton.config else {
            fatalError("ERROR: You must call setup before accessing ProtonWalletManager.shared")
        }
        self.storage = Persistence(keyChainIdentifier: config.keyChainIdentifier)
        
        self.loadAll()
        
    }
    
    public func loadAll() {
        
        self.publicKeys = self.storage.getKeychain(Set<String>.self, forKey: "publicKeys") ?? []
        self.chainProviders = self.storage.get(Set<ChainProvider>.self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.get(Set<TokenContract>.self, forKey: "tokenContracts") ?? []
        
    }
    
    public func saveAll() {
        
        if self.publicKeys.count > 0 { // saftey
            self.storage.setKeychain(self.publicKeys, forKey: "publicKeys")
        }
        
        self.storage.set(self.chainProviders, forKey: "chainProviders")
        self.storage.set(self.tokenContracts, forKey: "tokenContracts")
        
    }
    
    public func fetchRequirements(completion: @escaping () -> ()) {
    
        WebServices.shared.addSeq(FetchChainProvidersOperation()) { result in
            
            switch result {
                
            case .success(let chainProviders):
                if let chainProviders = chainProviders as? Set<ChainProvider> {
                    for chainProvider in chainProviders {
                        self.chainProviders.update(with: chainProvider)
                    }
                }
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
            }
            
            WebServices.shared.addSeq(FetchTokenContractsOperation()) { result in

                switch result {
                    
                case .success(let tokenContracts):
                    if let tokenContracts = tokenContracts as? Set<TokenContract> {
                        for tokenContract in tokenContracts {
                            self.tokenContracts.update(with: tokenContract)
                        }
                    }
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                
                self.saveAll()
                
                completion()
                
            }
            
        }
        
    }
    
    public func importAccount(with privateKey: String, completion: @escaping () -> ()) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            let chainProviderCount = self.chainProviders.count
            var chainProvidersProcessed = 0
            
            for chainProvider in self.chainProviders {
                
                WebServices.shared.addMulti(FetchKeyAccountsOperation(publicKey: publicKey.stringValue,
                                                                      chainProvider: chainProvider)) { result in
                    
                    chainProvidersProcessed += 1
                    
                    switch result {
                    case .success(let accountNames):
                        
                        if let accountNames = accountNames as? [String], accounts.count > 0 {
                            
                            for accountName in accountNames {
                                
                                let account = Account(chainId: chainProvider.chainId, name: accountName)
                                if !self.accounts.contains(account) {
                                    self.accounts.update(with: account)
                                }
                                
                            }
                            
                            self.publicKeys.update(with: publicKey.stringValue)
                            
                        }

                    case .failure(let error):
                        print("ERROR: \(error.localizedDescription)")
                    }
                                                                        
                    if chainProviderCount == chainProvidersProcessed {
                        
                        // fetch balances
                        self.saveAll()
                        completion()
                        
                    }
                    
                }
                
            }
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            completion()
        }

    }

}
