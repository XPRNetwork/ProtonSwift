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
    
    public static func initalize(_ config: Config) -> Proton {
        Proton.config = config
        return shared
    }
    
    public static let shared = Proton()

    var storage: Persistence!
    var publicKeys = Set<String>()
    
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
    
    @Published public var tokenBalances: Set<TokenBalance> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
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
        self.accounts = self.storage.get(Set<Account>.self, forKey: "accounts") ?? []
        self.tokenBalances = self.storage.get(Set<TokenBalance>.self, forKey: "tokenBalances") ?? []
        
    }
    
    public func saveAll() {
        
        if self.publicKeys.count > 0 { // saftey
            self.storage.setKeychain(self.publicKeys, forKey: "publicKeys")
        }
        
        self.storage.set(self.chainProviders, forKey: "chainProviders")
        self.storage.set(self.tokenContracts, forKey: "tokenContracts")
        self.storage.set(self.accounts, forKey: "accounts")
        self.storage.set(self.tokenBalances, forKey: "tokenBalances")
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
            
            self.fetchKeyAccounts(forPublicKeys: [publicKey.stringValue]) { accounts in
                if let accounts = accounts {
                    
                    // save private key
                    self.storage.setKeychain(privateKey, forKey: publicKey.stringValue)
                    
                    self.fetchBalances(forAccounts: accounts) { tokenBalances in
                        self.saveAll()
                        completion()
                    }
                    
                } else {
                    self.saveAll()
                    completion()
                }
            }
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            completion()
        }

    }
    
    func fetchKeyAccounts(forPublicKeys publicKeys: [String], completion: @escaping (Set<Account>?) -> ()) {
        
        let publicKeyCount = publicKeys.count
        var publicKeysProcessed = 0
        
        var accounts = Set<Account>()
        
        if publicKeyCount > 0 && self.chainProviders.count > 0 {
            
            for publicKey in publicKeys {
                
                let chainProviderCount = self.chainProviders.count
                var chainProvidersProcessed = 0
                
                for chainProvider in self.chainProviders {
                    
                    WebServices.shared.addMulti(FetchKeyAccountsOperation(publicKey: publicKey,
                                                                          chainProvider: chainProvider)) { result in
                        
                        chainProvidersProcessed += 1
                        
                        switch result {
                        case .success(let accountNames):
                            
                            if let accountNames = accountNames as? [String], accountNames.count > 0 {
                                
                                for accountName in accountNames {
                                    
                                    let account = Account(chainId: chainProvider.chainId, name: accountName)
                                    if !self.accounts.contains(account) {
                                        self.accounts.update(with: account)
                                    }
                                    accounts.update(with: account)
                                    
                                }
                                
                                self.publicKeys.update(with: publicKey)
                                
                            }

                        case .failure(let error):
                            print("ERROR: \(error.localizedDescription)")
                        }
                                                                            
                        if chainProvidersProcessed == chainProviderCount {
                            
                            publicKeysProcessed += 1
                            
                            if publicKeysProcessed == publicKeyCount {
                                completion(accounts)
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            completion(nil)
        }
        
    }
    
    func fetchBalances(forAccounts accounts: Set<Account>, completion: @escaping (Set<TokenBalance>?) -> ()) {
        
        let accountCount = accounts.count
        var accountsProcessed = 0
        
        if accountCount > 0 {
            
            var returnTokenBalances = Set<TokenBalance>()
            
            for account in accounts {
                
                if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
                    
                    WebServices.shared.addMulti(FetchTokenBalancesOperation(account: account, chainProvider: chainProvider)) { result in
                        
                        accountsProcessed += 1
                        
                        switch result {
                        case .success(let tokenBalances):
                    
                            if let tokenBalances = tokenBalances as? Set<TokenBalance> {
                                
                                for tokenBalance in tokenBalances {
                                    
                                    self.tokenBalances.update(with: tokenBalance)
                                    returnTokenBalances.update(with: tokenBalance)
                                    
                                }
                                
                            }
                            
                        case .failure(let error):
                            print("ERROR: \(error.localizedDescription)")
                        }
                        
                        if accountsProcessed == accountCount {
                            completion(returnTokenBalances)
                        }
                        
                    }
                    
                } else {
                    
                    accountsProcessed += 1
                    
                    if accountsProcessed == accountCount {
                        completion(returnTokenBalances)
                    }
                    
                }
                
            }
            
        } else {
            completion(nil)
        }
    
    }

}
