//
//  Proton.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import Combine
import Valet
import EOSIO

final public class Proton: ObservableObject {

    public struct Config {
        var keyChainIdentifier: String
        var chainProvidersUrl: String
        var tokenContractsUrl: String
    }
    
    public static var config: Config?
    
    public static func setup(_ config: Config) {
        Proton.config = config
    }
    
    public static let shared = Proton()

    var valet: Valet!
    var storage = Persistence()
    
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
    
    private init() {
        
        guard let config = Proton.config else {
            fatalError("ERROR: You must call setup before accessing ProtonWalletManager.shared")
        }
        self.valet = Valet.valet(with: Identifier(nonEmpty: config.keyChainIdentifier)!,
                                                accessibility: .whenUnlocked)
        
    }
    
    public func loadAll() {
        
        self.chainProviders = self.storage.get(Set<ChainProvider>.self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.get(Set<TokenContract>.self, forKey: "tokenContracts") ?? []
        
    }
    
    public func saveAll() {
        
        self.storage.set(Set<ChainProvider>.self, forKey: "chainProviders")
        self.storage.set(Set<TokenContract>.self, forKey: "tokenContracts")
        
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
            
            var accounts = [API.V1.Chain.GetAccount.Response]()
            
            let chainProviderCount = self.chainProviders.count
            var chainProvidersProcessed = 0
            
            for chainProvider in self.chainProviders {
                
                WebServices.shared.addMulti(FetchKeyAccountsOperation(publicKey: publicKey.stringValue,
                                                                      chainProvider: chainProvider)) { result in
                    
                    chainProvidersProcessed += 1
                    
                    switch result {
                    case .success(let account):
                        
                        if let account = account as? API.V1.Chain.GetAccount.Response {
                            accounts.append(account)
                        }
                        
                        if chainProviderCount == chainProvidersProcessed {
                            
                        }
                        
                    case .failure(let error):
                        print("ERROR: \(error.localizedDescription)")
                    }
                    
                }
                
            }
            
            
        } catch {
            
        }

    }

}
