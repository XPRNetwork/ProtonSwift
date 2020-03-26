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
    
    /**
     Use this function as your starting point to initialize the singleton class Proton
     - Parameter config: The configuration object that includes urls for chainProviders as well as your keychain indentifier string
     - Returns: Initialized Proton singleton
     */
    public static func initalize(_ config: Config) -> Proton {
        Proton.config = config
        return shared
    }
    
    public static let shared = Proton()

    var storage: Persistence!
    var publicKeys = Set<String>()
    
    /**
     Live updated set of chainProviders. Subscribe to this for your chainProviders
     */
    @Published public var chainProviders: Set<ChainProvider> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenContracts. Subscribe to this for your tokenContracts
     */
    @Published public var tokenContracts: Set<TokenContract> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of accounts. Subscribe to this for your accounts
     */
    @Published public var accounts: Set<Account> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenBalances. Subscribe to this for your tokenBalances
     */
    @Published public var tokenBalances: Set<TokenBalance> = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenTransferActions. Subscribe to this for your tokenTransferActions
     */
    @Published public var tokenTransferActions: Set<TokenTransferAction> = [] {
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
    
    /**
     Loads all data objects from disk into memory
     */
    public func loadAll() {
        
        self.publicKeys = self.storage.getKeychainItem(Set<String>.self, forKey: "publicKeys") ?? []
        self.chainProviders = self.storage.getDiskItem(Set<ChainProvider>.self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.getDiskItem(Set<TokenContract>.self, forKey: "tokenContracts") ?? []
        self.accounts = self.storage.getDiskItem(Set<Account>.self, forKey: "accounts") ?? []
        self.tokenBalances = self.storage.getDiskItem(Set<TokenBalance>.self, forKey: "tokenBalances") ?? []
        self.tokenTransferActions = self.storage.getDiskItem(Set<TokenTransferAction>.self, forKey: "tokenTransferActions") ?? []
        
    }
    
    /**
     Saves all current data objects that are in memory to disk
     */
    public func saveAll() {
        
        if self.publicKeys.count > 0 { // saftey
            self.storage.setKeychainItem(self.publicKeys, forKey: "publicKeys")
        }
        
        self.storage.setDiskItem(self.chainProviders, forKey: "chainProviders")
        self.storage.setDiskItem(self.tokenContracts, forKey: "tokenContracts")
        self.storage.setDiskItem(self.accounts, forKey: "accounts")
        self.storage.setDiskItem(self.tokenBalances, forKey: "tokenBalances")
        self.storage.setDiskItem(self.tokenTransferActions, forKey: "tokenTransferActions")
        
    }
    
    /**
     Fetchs all required data objects from external data sources. This should be done at startup
     - Parameter completion: Closure thats called when the function is complete
     */
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
            
            let chainProvidersCount = self.chainProviders.count
            var chainProvidersProcessed = 0
            
            if chainProvidersCount > 0 {
                
                for chainProvider in self.chainProviders {
                    
                    let tokenContracts = self.tokenContracts.filter({ $0.chainId == chainProvider.chainId })
                    
                    WebServices.shared.addMulti(FetchTokenContractsOperation(chainProvider: chainProvider, tokenContracts: tokenContracts)) { result in
                        
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
                        
                        chainProvidersProcessed += 1
                        
                        if chainProvidersProcessed == chainProvidersCount {
                           completion()
                        }

                    }
                    
                }
                    
            } else {
                completion()
            }

        }
        
    }
    
    /**
     Fetchs and updates all accounts. This includes, account names, avatars, balances, etc
     - Parameter accounts?: Pass in a set of accounts or nil. Passing nil causes the function to update all known accounts from memory
     - Parameter completion: Closure thats called when the function is complete
     */
    public func update(accounts: Set<Account>? = nil, completion: @escaping () -> ()) {
        
        let accounts = accounts ?? self.accounts
        
        if accounts.count > 0 {
            
            self.fetchBalances(forAccounts: accounts) { _ in
                self.fetchUserInfo(forAccounts: accounts) {
                    self.fetchTransferActions(forAccounts: accounts) {
                        self.saveAll()
                        
                        print("🧑‍💻 UPDATE COMPLETED")
                        print("ACCOUNTS => \(self.accounts.count)")
                        print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
                        print("TOKEN BALANCES => \(self.tokenBalances.count)")
                        print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
                        
                        completion()
                    }
                }
            }

        } else {
            completion()
        }
        
    }
    
    /**
     Use this to add an account
     - Parameter privateKey: Wif formated private key
     - Parameter completion: Closure thats called when the function is complete
     */
    public func importAccount(with privateKey: String, completion: @escaping () -> ()) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            self.fetchKeyAccounts(forPublicKeys: [publicKey.stringValue]) { accounts in
                if let accounts = accounts {
                    
                    // save private key
                    self.storage.setKeychainItem(privateKey, forKey: publicKey.stringValue)
                    
                    self.update(accounts: accounts) {
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
    
    private func fetchKeyAccounts(forPublicKeys publicKeys: [String], completion: @escaping (Set<Account>?) -> ()) {
        
        let publicKeyCount = publicKeys.count
        var publicKeysProcessed = 0
        
        var retval = Set<Account>()
        
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
                                    retval.update(with: account)
                                    
                                }
                                
                                self.publicKeys.update(with: publicKey)
                                
                            }

                        case .failure(let error):
                            print("ERROR: \(error.localizedDescription)")
                        }
                                                                            
                        if chainProvidersProcessed == chainProviderCount {
                            
                            publicKeysProcessed += 1
                            
                            if publicKeysProcessed == publicKeyCount {
                                completion(retval)
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            completion(nil)
        }
        
    }
    
    private func fetchBalances(forAccounts accounts: Set<Account>, completion: @escaping (Set<TokenBalance>?) -> ()) {
        
        let accountCount = accounts.count
        var accountsProcessed = 0
        
        if accountCount > 0 {
            
            var retval = Set<TokenBalance>()
            
            for account in accounts {
                
                if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
                    
                    WebServices.shared.addMulti(FetchTokenBalancesOperation(account: account, chainProvider: chainProvider)) { result in
                        
                        accountsProcessed += 1
                        
                        switch result {
                        case .success(let tokenBalances):
                    
                            if let tokenBalances = tokenBalances as? Set<TokenBalance> {
                                
                                for tokenBalance in tokenBalances {
                                    
                                    self.tokenBalances.update(with: tokenBalance)
                                    retval.update(with: tokenBalance)
                                    
                                    if self.tokenContracts.first(where: { $0.id == tokenBalance.tokenContractId }) == nil {
                                        
                                        
                                        let unknownTokenContract = TokenContract(chainId: tokenBalance.chainId, contract: tokenBalance.contract, issuer: "",
                                                                                 resourceToken: false, systemToken: false, name: tokenBalance.amount.symbol.name,
                                                                                 description: "", iconUrl: "", supply: Asset(0.0, tokenBalance.amount.symbol),
                                                                                 maxSupply: Asset(0.0, tokenBalance.amount.symbol),
                                                                                 symbol: tokenBalance.amount.symbol, url: "", blacklisted: true)
                                        
                                        self.tokenContracts.update(with: unknownTokenContract)
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        case .failure(let error):
                            print("ERROR: \(error.localizedDescription)")
                        }
                        
                        if accountsProcessed == accountCount {
                            completion(retval)
                        }
                        
                    }
                    
                } else {
                    
                    accountsProcessed += 1
                    
                    if accountsProcessed == accountCount {
                        completion(retval)
                    }
                    
                }
                
            }
            
        } else {
            completion(nil)
        }
    
    }
    
    private func fetchCurrencyStats(forTokenContracts tokenContracts: Set<TokenContract>, completion: @escaping () -> ()) {
        
        let tokenContractCount = tokenContracts.count
        var tokenContractsProcessed = 0
        
        if tokenContractCount > 0 {
            
            for tokenContract in tokenContracts {
                
                if let chainProvider = self.chainProviders.first(where: { $0.chainId == tokenContract.chainId }) {
                    
                    WebServices.shared.addMulti(FetchTokenContractCurrencyStat(tokenContract: tokenContract, chainProvider: chainProvider)) { result in
                         
                         switch result {
                         case .success(let updatedTokenContract):
                     
                             if let updatedTokenContract = updatedTokenContract as? TokenContract {
                                self.tokenContracts.update(with: updatedTokenContract)
                             }
                             
                         case .failure(let error):
                             print("ERROR: \(error.localizedDescription)")
                         }
                    
                        tokenContractsProcessed += 1
                        
                        if tokenContractsProcessed == tokenContractCount {
                            completion()
                        }
                    
                    }
                    
                } else {
                    
                    tokenContractsProcessed += 1
                    
                    if tokenContractsProcessed == tokenContractCount {
                        completion()
                    }
                    
                }
                
            }

        } else {
            completion()
        }

    }
    
    private func fetchTransferActions(forTokenBalance tokenBalance: TokenBalance, completion: @escaping (Set<TokenTransferAction>?) -> ()) {
        
        guard let account = self.accounts.first(where: { $0.id == tokenBalance.accountId }) else {
            completion(nil)
            return
        }
        
        guard let chainProvider = self.chainProviders.first(where: { $0.chainId == tokenBalance.chainId }) else {
            completion(nil)
            return
        }
        
        guard let tokenContract = self.tokenContracts.first(where: { $0.id == tokenBalance.tokenContractId }) else {
            completion(nil)
            return
        }
        
        var retval = Set<TokenTransferAction>()
        
        WebServices.shared.addMulti(FetchTokenTransferActionsOperation(account: account, tokenContract: tokenContract,
                                                                       chainProvider: chainProvider, tokenBalance: tokenBalance)) { result in
            
            switch result {
            case .success(let transferActions):
        
                if let transferActions = transferActions as? Set<TokenTransferAction> {
                    
                    for transferAction in transferActions {
                        
                        self.tokenTransferActions.update(with: transferAction)
                        retval.update(with: transferAction)
                        
                    }
                    
                }
                
                completion(retval)
                
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
                completion(nil)
            }
            
        }
        
    }
    
    private func fetchTransferActions(forAccounts accounts: Set<Account>, completion: @escaping () -> ()) {
        
        let accountCount = accounts.count
        var accountsProcessed = 0
        
        if accountCount > 0 {
            
            for account in accounts {
                
                let tokenBalances = self.tokenBalances.filter({ $0.accountId == account.id })
                let tokenBalancesCount = tokenBalances.count
                var tokenBalancesProcessed = 0
                
                if tokenBalancesCount > 0 {
                    
                    for tokenBalance in tokenBalances {
                        
                        self.fetchTransferActions(forTokenBalance: tokenBalance) { _ in
                            
                            tokenBalancesProcessed += 1
                            
                            if tokenBalancesProcessed == tokenBalancesCount {
                                
                                accountsProcessed += 1
                                
                                if accountsProcessed == accountCount {
                                    
                                    completion()
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    accountsProcessed += 1
                    
                    if accountsProcessed == accountCount {
                        completion()
                    }
                    
                }

            }
            
        } else {
            completion()
        }
    
    }
    
    private func fetchUserInfo(forAccounts accounts: Set<Account>, completion: @escaping () -> ()) {
        
        let accountCount = accounts.count
        var accountsProcessed = 0
        
        if accountCount > 0 {
            
            for account in accounts {
                
                if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
                    
                    WebServices.shared.addMulti(FetchUserAccountInfoOperation(account: account, chainProvider: chainProvider)) { result in
                        
                        accountsProcessed += 1
                        
                        switch result {
                        case .success(let updatedAccount):
                    
                            if let updatedAccount = updatedAccount as? Account {
                                
                                self.accounts.update(with: updatedAccount)
                                
                            }
                            
                        case .failure(let error):
                            print("ERROR: \(error.localizedDescription)")
                        }
                        
                        if accountsProcessed == accountCount {
                            completion()
                        }
                        
                    }
                    
                } else {
                    
                    accountsProcessed += 1
                    
                    if accountsProcessed == accountCount {
                        completion()
                    }
                    
                }
                
            }
            
        } else {
            completion()
        }
    
    }

}
