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
import UIKit

final public class Proton: ObservableObject {
    
    public struct ProtonSigningRequest {
        public let requestor: Account
        public let signer: Account
        public let signingRequest: SigningRequest
    }

    public struct Config {

        public var keyChainIdentifier: String
        public var chainProvidersUrl: String
        
        public init(keyChainIdentifier: String, chainProvidersUrl: String) {
            
            self.keyChainIdentifier = keyChainIdentifier
            self.chainProvidersUrl = chainProvidersUrl
            
        }
        
    }
    
    public static var config: Config?
    
    /**
     Use this function as your starting point to initialize the singleton class Proton
     - Parameter config: The configuration object that includes urls for chainProviders as well as your keychain indentifier string
     - Returns: Initialized Proton singleton
     */
    public static func initialize(_ config: Config) -> Proton {
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
    
    /**
     Live updated esr signing request. This will be initialized when a signing request is made
     */
    @Published public var protonSigningRequest: ProtonSigningRequest? = nil {
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
        self.chainProviders = self.storage.getDefaultsItem(Set<ChainProvider>.self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.getDefaultsItem(Set<TokenContract>.self, forKey: "tokenContracts") ?? []
        self.accounts = self.storage.getDefaultsItem(Set<Account>.self, forKey: "accounts") ?? []
        self.tokenBalances = self.storage.getDefaultsItem(Set<TokenBalance>.self, forKey: "tokenBalances") ?? []
        self.tokenTransferActions = self.storage.getDefaultsItem(Set<TokenTransferAction>.self, forKey: "tokenTransferActions") ?? []
        
    }
    
    /**
     Saves all current data objects that are in memory to disk
     */
    public func saveAll() {
        
        if self.publicKeys.count > 0 { // saftey
            self.storage.setKeychainItem(self.publicKeys, forKey: "publicKeys")
        }
        
        self.storage.setDefaultsItem(self.chainProviders, forKey: "chainProviders")
        self.storage.setDefaultsItem(self.tokenContracts, forKey: "tokenContracts")
        self.storage.setDefaultsItem(self.accounts, forKey: "accounts")
        self.storage.setDefaultsItem(self.tokenBalances, forKey: "tokenBalances")
        self.storage.setDefaultsItem(self.tokenTransferActions, forKey: "tokenTransferActions")
        
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
     Fetchs and updates passed account. This includes, account names, avatars, balances, etc
     - Parameter account: Update an account
     - Parameter completion: Closure thats called when the function is complete
     */
    public func update(account: Account, completion: @escaping () -> ()) {
        
        var account = account
        
        self.fetchAccount(forAccount: account) { returnAccount in
            
            account = returnAccount
            self.accounts.update(with: account)
            
            self.fetchAccountUserInfo(forAccount: account) { returnAccount in
                
                account = returnAccount
                self.accounts.update(with: account)
                
                self.fetchBalances(forAccount: account) { tokenBalances in
                    
                    if let tokenBalances = tokenBalances {
                        
                        self.tokenBalances = self.tokenBalances.union(tokenBalances)

                    }
                    
                    let tokenBalancesCount = self.tokenBalances.count
                    var tokenBalancesProcessed = 0
                    
                    if tokenBalancesCount > 0 {
                        
                        for tokenBalance in self.tokenBalances {
                            
                            self.fetchTransferActions(forTokenBalance: tokenBalance) { _ in
                                
                                tokenBalancesProcessed += 1
                                
                                if tokenBalancesProcessed == tokenBalancesCount {
                                    
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
                        
                        print("🧑‍💻 UPDATE COMPLETED")
                        print("ACCOUNTS => \(self.accounts.count)")
                        print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
                        print("TOKEN BALANCES => \(self.tokenBalances.count)")
                        print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
                        
                        completion()
                    }
                    
                }
                
            }
            
        }
        
    }
    
    /**
     Fetchs and updates all accounts. This includes, account names, avatars, balances, etc
     - Parameter completion: Closure thats called when the function is complete
     */
    public func update(completion: @escaping () -> ()) {
        
        let accountsCount = self.accounts.count
        var accountsProcessed = 0
        
        if accountsCount > 0 {
            
            for account in self.accounts {
                
                self.update(account: account) {
                    
                    accountsProcessed += 1
                    
                    if accountsProcessed == accountsCount {
                        
                        self.saveAll()
                        
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
            
            self.fetchKeyAccounts(forPublicKey: publicKey.stringValue) { accounts in
                
                if let accounts = accounts, accounts.count > 0 {
                    
                    // save private key
                    self.storage.setKeychainItem(privateKey, forKey: publicKey.stringValue)
                    
                    let accountCount = accounts.count
                    var accountsProcessed = 0
                    
                    for account in accounts {
                        
                        self.update(account: account) {
                            accountsProcessed += 1
                            if accountsProcessed == accountCount {
                                self.saveAll()
                                completion()
                            }
                        }
                        
                    }
                    
                } else {
                    completion()
                }
                
            }
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            completion()
        }

    }
    
    /**
     Use this to parse an esr signing request.
     - Parameter openURLContext: UIOpenURLContext passed when opening from custom uri: esr://
     - Parameter completion: Closure thats called when the function is complete. Will return object to be used for displaying request
     */
    public func parseSigningReqeust(openURLContext: UIOpenURLContext, completion: @escaping (ProtonSigningRequest?) -> ()) {
        
        do {
            
            let signingRequest = try SigningRequest(openURLContext.url.absoluteString)
            let chainId = signingRequest.chainId
            
            guard let requestingAccountName = signingRequest.getInfo("account", as: String.self) else { completion(nil); return }
            guard let account = self.accounts.first(where: { $0.chainId == chainId.description }) else { completion(nil); return }
            guard let chainProvider = self.chainProviders.first(where: { $0.chainId == chainId.description }) else { completion(nil); return }
            
            var requestingAccount = Account(chainId: chainId.description, name: requestingAccountName)
            
            WebServices.shared.addSeq(FetchUserAccountInfoOperation(account: requestingAccount, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let acc):
                    
                    if let acc = acc as? Account {
                        requestingAccount = acc
                    }
                    
                    let response = ProtonSigningRequest(requestor: requestingAccount, signer: account, signingRequest: signingRequest)
                    self.protonSigningRequest = response
                    
                    completion(response)

                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                    completion(nil)
                }
                
            }
            
        } catch {
            completion(nil)
        }
        
    }
    
    /**
     Use this to parse an esr signing request.
     - Parameter signingRequest: Wif formated private key
     - Parameter completion: Closure thats called when the function is complete. Will return object to be used for displaying request
     */
//    public func resolveSigningRequest(protonSigningRequest: ProtonSigningRequest, completion: @escaping () -> ()) {
//        
//        do {
//            
//            let signingRequest = protonSigningRequest.signingRequest
//            let chainId = signingRequest.chainId
//            
//            let pk = storage.getKeychainItem(String.self, forKey: <#T##String#>)
//            
//            let resolved = try signingRequest.resolve(using: PermissionLevel(protonSigningRequest.signer.name, Name("active")))
//            
//            
//            
//            
//        } catch {
//            completion()
//        }
//        
//    }
    
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
    
    private func fetchKeyAccounts(forPublicKey publicKey: String, completion: @escaping (Set<Account>?) -> ()) {
        
        let chainProviderCount = self.chainProviders.count
        var chainProvidersProcessed = 0
        
        var accounts = Set<Account>()
        
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
                                accounts.update(with: account)
                            }
                            
                        }
                        
                        self.publicKeys.update(with: publicKey)
                        
                    }

                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                                                                    
                if chainProvidersProcessed == chainProviderCount {
                    completion(accounts)
                }
                
            }
            
        }
        
    }
    
    private func fetchAccount(forAccount account: Account, completion: @escaping (Account) -> ()) {
        
        var account = account
        
        if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
            
            WebServices.shared.addMulti(FetchAccountOperation(accountName: account.name.stringValue, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let acc):
            
                    if let acc = acc as? API.V1.Chain.GetAccount.Response {
                        account.permissions = acc.permissions
                    }
                    
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                
                completion(account)
                
            }
            
        } else {
            
            completion(account)
            
        }
        
    }
    
    private func fetchAccountUserInfo(forAccount account: Account, completion: @escaping (Account) -> ()) {
        
        var account = account
        
        if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
            
            WebServices.shared.addMulti(FetchUserAccountInfoOperation(account: account, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let updatedAccount):
            
                    if let updatedAccount = updatedAccount as? Account {
                        
                        account = updatedAccount
                        self.accounts.update(with: updatedAccount)
                        
                    }
                    
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                
                completion(account)
                
            }
            
        } else {
            completion(account)
        }
        
    }
    
    private func fetchBalances(forAccount account: Account, completion: @escaping (Set<TokenBalance>?) -> ()) {
        
        if let chainProvider = self.chainProviders.first(where: { $0.chainId == account.chainId }) {
            
            WebServices.shared.addMulti(FetchTokenBalancesOperation(account: account, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let tokenBalances):
            
                    if let tokenBalances = tokenBalances as? Set<TokenBalance> {
                        
                        for tokenBalance in tokenBalances {
                            
                            if self.tokenContracts.first(where: { $0.id == tokenBalance.tokenContractId }) == nil {
                                
                                
                                let unknownTokenContract = TokenContract(chainId: tokenBalance.chainId, contract: tokenBalance.contract, issuer: "",
                                                                         resourceToken: false, systemToken: false, name: tokenBalance.amount.symbol.name,
                                                                         description: "", iconUrl: "", supply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         maxSupply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         symbol: tokenBalance.amount.symbol, url: "", blacklisted: true)
                                
                                self.tokenContracts.update(with: unknownTokenContract)
                                
                            }
                            
                        }
                        
                        completion(tokenBalances)
                        
                    }
                    
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                
            }
            
        }
        
    }
    
}
