//
//  Proton.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import KeychainAccess

public class Proton {
    
    public struct Config {
        
        public var chainProvidersUrl: String
        
        public init(chainProvidersUrl: String) {
            self.chainProvidersUrl = chainProvidersUrl
        }
        
    }
    
    public static var config: Config?
    
    /**
     Use this function as your starting point to initialize the singleton class Proton
     - Parameter config: The configuration object that includes urls for chainProviders
     - Returns: Initialized Proton singleton
     */
    @discardableResult
    public static func initialize(_ config: Config) -> Proton {
        Proton.config = config
        return self.shared
    }
    
    public static let shared = Proton()
    var storage: Persistence!
    
    public enum Notifications {
        public static let chainProvidersWillSet = Notification.Name("chainProvidersWillSet")
        public static let chainProvidersDidSet = Notification.Name("chainProvidersDidSet")
        public static let tokenContractsWillSet = Notification.Name("tokenContractsWillSet")
        public static let tokenContractsDidSet = Notification.Name("tokenContractsDidSet")
        public static let tokenBalancesWillSet = Notification.Name("tokenBalancesWillSet")
        public static let tokenBalancesDidSet = Notification.Name("tokenBalancesDidSet")
        public static let tokenTransferActionsWillSet = Notification.Name("tokenTransferActionsWillSet")
        public static let tokenTransferActionsDidSet = Notification.Name("tokenTransferActionsDidSet")
        public static let esrSessionsWillSet = Notification.Name("esrSessionsWillSet")
        public static let esrSessionsDidSet = Notification.Name("esrSessionsDidSet")
        public static let esrWillSet = Notification.Name("esrWillSet")
        public static let esrDidSet = Notification.Name("esrDidSet")
        public static let activeAccountWillSet = Notification.Name("activeAccountWillSet")
        public static let activeAccountDidSet = Notification.Name("activeAccountDidSet")
        public static let activeAccountDidUpdate = Notification.Name("activeAccountDidUpdate")
    }
    
    /**
     Live updated array of chainProviders. You can observe changes via NotificaitonCenter: chainProvidersWillSet, chainProvidersDidSet
     */
    public var chainProviders: [ChainProvider] = [] {
        willSet {
            NotificationCenter.default.post(name: Notifications.chainProvidersWillSet, object: nil,
                                            userInfo: ["newValue": newValue])
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.chainProvidersDidSet, object: nil)
        }
    }
    
    /**
     Live updated array of tokenContracts. You can observe changes via NotificaitonCenter: tokenContractsWillSet, tokenContractsDidSet
     */
    public var tokenContracts: [TokenContract] = [] {
        willSet {
            NotificationCenter.default.post(name: Notifications.tokenContractsWillSet, object: nil,
                                            userInfo: ["newValue": newValue])
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.tokenContractsDidSet, object: nil)
        }
    }
    
    /**
     Live updated array of tokenBalances. You can observe changes via NotificaitonCenter: tokenBalancesWillSet, tokenBalancesDidSet
     */
    public var tokenBalances: [TokenBalance] = [] {
        willSet {
            NotificationCenter.default.post(name: Notifications.tokenBalancesWillSet, object: nil,
                                            userInfo: ["newValue": newValue])
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.tokenBalancesDidSet, object: nil)
        }
    }
    
    /**
     Live updated array of tokenTransferActions. You can observe changes via NotificaitonCenter: tokenTransferActionsWillSet, tokenTransferActionsDidSet
     */
    public var tokenTransferActions: [TokenTransferAction] = [] {
        willSet {
            NotificationCenter.default.post(name: Notifications.tokenTransferActionsWillSet, object: nil,
                                            userInfo: ["newValue": newValue])
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.tokenTransferActionsDidSet, object: nil)
        }
    }
    
    /**
     Live updated array of esrSessions. You can observe changes via NotificaitonCenter: esrSessionsWillSet, esrSessionsDidSet
     */
    public var esrSessions: [ESRSession] = [] {
        willSet {
            NotificationCenter.default.post(name: Notifications.esrSessionsWillSet, object: nil,
                                            userInfo: ["newValue": newValue])
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.esrSessionsDidSet, object: nil)
        }
    }
    
    /**
     Live updated esr. You can observe changes via NotificaitonCenter: esrWillSet, esrDidSet
     */
    public var esr: ESR? = nil {
        willSet {
            NotificationCenter.default.post(name: Notifications.esrWillSet, object: nil,
                                            userInfo: newValue != nil ? ["newValue": newValue!] : nil)
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.esrDidSet, object: nil)
        }
    }
    
    /**
     Live updated array of accounts. You can observe changes via NotificaitonCenter: accountsWillSet, accountsDidSet
     */
    public var activeAccount: Account? = nil {
        willSet {
            NotificationCenter.default.post(name: Notifications.activeAccountWillSet, object: nil,
                                            userInfo: newValue != nil ? ["newValue": newValue!] : nil)
        }
        didSet {
            NotificationCenter.default.post(name: Notifications.activeAccountDidSet, object: nil)
        }
    }
    
    private init() {
        
        guard let _ = Proton.config else {
            fatalError("ERROR: You must call setup before accessing Proton.shared")
        }
        
        self.storage = Persistence()
        
        self.loadAll()
        
        print("🧑‍💻 LOAD COMPLETED")
        print("ACTIVE ACCOUNT => \(String(describing: self.activeAccount))")
        print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
        print("TOKEN BALANCES => \(self.tokenBalances.count)")
        print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
        print("ESR SESSIONS => \(self.esrSessions.count)")
        
    }
    
    /**
     Loads all data objects from disk into memory
     */
    public func loadAll() {
        
        self.activeAccount = self.storage.getDefaultsItem(Account.self, forKey: "activeAccount") ?? nil
        self.chainProviders = self.storage.getDefaultsItem([ChainProvider].self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.getDefaultsItem([TokenContract].self, forKey: "tokenContracts") ?? []
        self.tokenBalances = self.storage.getDefaultsItem([TokenBalance].self, forKey: "tokenBalances") ?? []
        self.tokenTransferActions = self.storage.getDefaultsItem([TokenTransferAction].self, forKey: "tokenTransferActions") ?? []
        self.esrSessions = self.storage.getDefaultsItem([ESRSession].self, forKey: "esrSessions") ?? []
        
    }
    
    /**
     Saves all current data objects that are in memory to disk
     */
    public func saveAll() {
        
        self.storage.setDefaultsItem(self.activeAccount, forKey: "activeAccount")
        self.storage.setDefaultsItem(self.chainProviders, forKey: "chainProviders")
        self.storage.setDefaultsItem(self.tokenContracts, forKey: "tokenContracts")
        self.storage.setDefaultsItem(self.tokenBalances, forKey: "tokenBalances")
        self.storage.setDefaultsItem(self.tokenTransferActions, forKey: "tokenTransferActions")
        self.storage.setDefaultsItem(self.esrSessions, forKey: "esrSessions")
        
    }
    
    /**
     Sets the active account, fetchs and updates. This includes, account names, avatars, balances, etc
     - Parameter forAccountName: Proton account name not including @
     - Parameter chainId: chainId for the account
     - Parameter completion: Closure returning Result<Account, Error>
     */
    public func setActiveAccount(forAccountName accountName: String, chainId: String,
                                 completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        self.setActiveAccount(Account(chainId: chainId, name: accountName)) { result in
            switch result {
            case .success(let account):
                completion(.success(account))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     Sets the active account, fetchs and updates. This includes, account names, avatars, balances, etc
     - Parameter account: Account
     - Parameter completion: Closure returning Result<Account, Error>
     */
    public func setActiveAccount(_ account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let activeAccount = self.activeAccount, activeAccount == account {
            account = activeAccount
        } else {
            self.activeAccount = account
            self.tokenBalances.removeAll()
            self.tokenTransferActions.removeAll()
            self.esrSessions.removeAll() // TODO: Actually loop through call the remove session callbacks, etc
            self.esr = nil
        }

        self.update { result in
            switch result {
            case .success(let account):
                self.activeAccount = account
                completion(.success(account))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     Fetchs all required data objects from external data sources. This should be done at startup
     - Parameter completion: Closure returning Result<Bool, Error>.
     */
    public func fetchRequirements(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        WebServices.shared.addSeq(FetchChainProvidersOperation()) { result in
            
            switch result {
                
            case .success(let chainProviders):
                
                if let chainProviders = chainProviders as? Set<ChainProvider> {
                    
                    for chainProvider in chainProviders {
                        if let idx = self.chainProviders.firstIndex(of: chainProvider) {
                            self.chainProviders[idx] = chainProvider
                        } else {
                            self.chainProviders.append(chainProvider)
                        }
                    }
                    
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
            
            let chainProvidersCount = self.chainProviders.count
            var chainProvidersProcessed = 0
            
            if chainProvidersCount > 0 {
                
                for chainProvider in self.chainProviders {
                    
                    let tokenContracts = chainProvider.tokenContracts
                    
                    WebServices.shared.addMulti(FetchTokenContractsOperation(chainProvider: chainProvider, tokenContracts: tokenContracts)) { result in
                        
                        switch result {
                            
                        case .success(let tokenContracts):
                            
                            if let tokenContracts = tokenContracts as? [TokenContract] {
                                
                                for tokenContract in tokenContracts {
                                    if let idx = self.tokenContracts.firstIndex(of: tokenContract) {
                                        self.tokenContracts[idx] = tokenContract
                                    } else {
                                        self.tokenContracts.append(tokenContract)
                                    }
                                }
                                
                            }
                            
                        case .failure: break
                        }
                        
                        chainProvidersProcessed += 1
                        
                        if chainProvidersProcessed == chainProvidersCount {
                            completion(.success(true))
                        }
                        
                    }
                    
                }
                
            } else {
                completion(.failure(ProtonError.error("MESSAGE => No chainproviders")))
            }
            
        }
        
    }
    
    /**
     Fetchs and updates the active account. This includes, account names, avatars, balances, etc
     - Parameter completion: Closure returning Result<Account, Error>
     */
    public func update(completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard var account = self.activeAccount else {
            completion(.failure(ProtonError.error("MESSAGE => No active account")))
            return
        }
        
        self.fetchAccount(forAccount: account) { result in
            
            switch result {
            case .success(let returnAccount):
                
                account = returnAccount
                
                self.fetchAccountUserInfo(forAccount: account) { result in
                    
                    account = returnAccount
                    
                    switch result {
                    case .success(let returnAccount):
                        
                        account = returnAccount
                        
                        self.fetchBalances(forAccount: account) { result in
                            
                            switch result {
                            case .success(let tokenBalances):
                                
                                for tokenBalance in tokenBalances {
                                    if let idx = self.tokenBalances.firstIndex(of: tokenBalance) {
                                        self.tokenBalances[idx] = tokenBalance
                                    } else {
                                        self.tokenBalances.append(tokenBalance)
                                    }
                                }
                                
                                let tokenBalancesCount = self.tokenBalances.count
                                var tokenBalancesProcessed = 0
                                
                                if tokenBalancesCount > 0 {
                                    
                                    for tokenBalance in self.tokenBalances {
                                        
                                        self.fetchTransferActions(forTokenBalance: tokenBalance) { result in
                                            
                                            tokenBalancesProcessed += 1
                                            
                                            switch result {
                                            case .success(let transferActions):
                                                
                                                for transferAction in transferActions {
                                                    
                                                    if let idx = self.tokenTransferActions.firstIndex(of: transferAction) {
                                                        self.tokenTransferActions[idx] = transferAction
                                                    } else {
                                                        self.tokenTransferActions.append(transferAction)
                                                    }
                                                    
                                                }

                                            case .failure: break
                                            }
                                            
                                            if tokenBalancesProcessed == tokenBalancesCount {
                                                
                                                completion(.success(account))
                                                self.saveAll()
                                                NotificationCenter.default.post(name: Notifications.activeAccountDidUpdate, object: nil)
                                                
                                                print("🧑‍💻 UPDATE COMPLETED")
                                                print("ACCOUNT => \(String(describing: self.activeAccount?.name))")
                                                print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
                                                print("TOKEN BALANCES => \(self.tokenBalances.count)")
                                                print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
                                                print("ESR SESSIONS => \(self.esrSessions.count)")
                                                
                                            }

                                        }
                                        
                                    }
                                    
                                } else {
                                    completion(.failure(ProtonError.error("MESSAGE => No TokenBalances found for account: \(account.name)")))
                                }
                                
                            case .failure(let error):
                                completion(.failure(error))
                            }

                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            case .failure(let error):
                completion(.failure(error))
            }

        }
        
    }
    
    /**
     Use this function to store the account and private key after finding the account you want to save via findAccounts
     - Parameter account: Account object, normally retrieved via findAccounts
     - Parameter privateKey: Wif formated private key
     - Parameter completion: Closure returning Result<Account, Error>
     */
    public func store(account: Account, forPrivateKey privateKey: String, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            if account.isKeyAssociated(publicKey: publicKey.stringValue) {
                
                let keychain = Keychain(service: "proton-swift-ks")
                                .synchronizable(false)
                                .accessibility(.whenUnlocked, authenticationPolicy: .userPresence)
                
                try keychain.set(Data(privateKey.utf8), key: publicKey.stringValue)
                
                self.setActiveAccount(account) { result in
                    switch result {
                    case .success(let account):
                        completion(.success(account))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            } else {
                completion(.failure(ProtonError.error("MESSAGE => Key not associated with Account")))
            }

        } catch {
            completion(.failure(ProtonError.error(error.localizedDescription)))
        }
        
    }
    
    /**
     Use this function to obtain a list of Accounts which match a given private key. These accounts are not stored. If you want to store the Account and private key, you should then call store(account:)
     - Parameter privateKey: Wif formated private key
     - Parameter completion: Closure returning Result<Set<Account>, Error>
     */
    public func findAccounts(forPrivateKey privateKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            findAccounts(forPublicKey: publicKey.stringValue) { result in
                switch result {
                case .success(let accounts):
                    completion(.success(accounts))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(ProtonError.error("MESSAGE => Unable to parse Private Key")))
        }
        
    }
    
    private func findAccounts(forPublicKey publicKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        self.fetchKeyAccounts(forPublicKey: publicKey) { result in
            
            switch result {
            case .success(var accounts):
                
                if accounts.count > 0 {
                    
                    let accountCount = accounts.count
                    var accountsProcessed = 0
                    
                    for var account in accounts {
                        
                        self.fetchAccount(forAccount: account) { result in
                            
                            switch result {
                            case .success(let acc):
                                account = acc
                                accounts.update(with: acc)
                            case .failure: break
                            }
                            
                            self.fetchAccountUserInfo(forAccount: account) { result in
                                switch result {
                                case .success(let acc):
                                    accounts.update(with: acc)
                                case .failure: break
                                }
                                
                                accountsProcessed += 1
                                
                                if accountCount == accountsProcessed {
                                    completion(.success(accounts))
                                }
                            }
                            
                        }
                        
                    }

                } else {
                    completion(.failure(ProtonError.error("MESSAGE => No accounts found for publicKey: \(publicKey)")))
                }
            case .failure(let error):
                completion(.failure(error))
            }

        }
        
    }
    
    private func fetchCurrencyStats(forTokenContracts tokenContracts: [TokenContract], completion: @escaping () -> ()) {
        
        let tokenContractCount = tokenContracts.count
        var tokenContractsProcessed = 0
        
        if tokenContractCount > 0 {
            
            for tokenContract in tokenContracts {
                
                if let chainProvider = tokenContract.chainProvider {
                    
                    WebServices.shared.addMulti(FetchTokenContractCurrencyStat(tokenContract: tokenContract, chainProvider: chainProvider)) { result in
                        
                        switch result {
                        case .success(let updatedTokenContract):
                            
                            if let updatedTokenContract = updatedTokenContract as? TokenContract {
                                if let idx = self.tokenContracts.firstIndex(of: updatedTokenContract) {
                                    self.tokenContracts[idx] = updatedTokenContract
                                } else {
                                    self.tokenContracts.append(updatedTokenContract)
                                }
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
    
    private func fetchTransferActions(forTokenBalance tokenBalance: TokenBalance, completion: @escaping ((Result<Set<TokenTransferAction>, Error>) -> Void)) {
        
        var retval = Set<TokenTransferAction>()
        
        guard let account = tokenBalance.account else {
            completion(.failure(ProtonError.error("MESSAGE => TokenBalance missing Account")))
            return
        }
        
        guard let chainProvider = account.chainProvider else {
            completion(.failure(ProtonError.error("MESSAGE => Account missing ChainProvider")))
            return
        }
        
        guard let tokenContract = tokenBalance.tokenContract else {
            completion(.failure(ProtonError.error("MESSAGE => TokenBalance missing TokenContract")))
            return
        }
        
        WebServices.shared.addMulti(FetchTokenTransferActionsOperation(account: account, tokenContract: tokenContract,
                                                                       chainProvider: chainProvider, tokenBalance: tokenBalance)) { result in
            
            switch result {
            case .success(let transferActions):
                
                if let transferActions = transferActions as? Set<TokenTransferAction> {
                    retval = transferActions
                }
                
                completion(.success(retval))

            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        
    }
    
    private func fetchKeyAccounts(forPublicKey publicKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        let chainProviderCount = self.chainProviders.count
        var chainProvidersProcessed = 0
        
        var accounts = Set<Account>()
        
        if chainProviderCount == 0 {
            completion(.failure(ProtonError.error("MESSAGE => No ChainProviders")))
            return
        }
        
        for chainProvider in self.chainProviders {
            
            WebServices.shared.addMulti(FetchKeyAccountsOperation(publicKey: publicKey,
                                                                  chainProvider: chainProvider)) { result in
                
                chainProvidersProcessed += 1
                
                switch result {
                case .success(let accountNames):
                    
                    if let accountNames = accountNames as? Set<String>, accountNames.count > 0 {
                        for accountName in accountNames {
                            accounts.update(with: Account(chainId: chainProvider.chainId, name: accountName))
                        }
                    }
                    
                case .failure: break
                }
                
                if chainProvidersProcessed == chainProviderCount {
                    if accounts.count > 0 {
                        completion(.success(accounts))
                    } else {
                        completion(.failure(ProtonError.error("MESSAGE => No accounts found for \(publicKey)")))
                    }
                }
                
            }
            
        }
        
    }
    
    private func fetchAccount(forAccount account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let chainProvider = account.chainProvider {
            
            WebServices.shared.addMulti(FetchAccountOperation(accountName: account.name.stringValue, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let acc):
                    
                    if let acc = acc as? API.V1.Chain.GetAccount.Response {
                        account.permissions = acc.permissions
                    }
                    
                    completion(.success(account))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(ProtonError.error("MESSAGE => Account missing chainProvider")))
        }
        
    }
    
    private func fetchAccountUserInfo(forAccount account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let chainProvider = account.chainProvider {
            
            WebServices.shared.addMulti(FetchUserAccountInfoOperation(account: account, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let updatedAccount):
                    
                    if let updatedAccount = updatedAccount as? Account {
                        account = updatedAccount
                    }
                    
                    completion(.success(account))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(ProtonError.error("MESSAGE => Account missing chainProvider")))
        }
        
    }
    
    private func fetchBalances(forAccount account: Account, completion: @escaping ((Result<Set<TokenBalance>, Error>) -> Void)) {
        
        var retval = Set<TokenBalance>()
        
        if let chainProvider = account.chainProvider {
            
            WebServices.shared.addMulti(FetchTokenBalancesOperation(account: account, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let tokenBalances):
                    
                    if let tokenBalances = tokenBalances as? Set<TokenBalance> {
                        
                        for tokenBalance in tokenBalances {
                            
                            if self.tokenContracts.first(where: { $0.id == tokenBalance.tokenContractId }) == nil {
                                
                                let unknownTokenContract = TokenContract(chainId: tokenBalance.chainId, contract: tokenBalance.contract, issuer: "",
                                                                         resourceToken: false, systemToken: false, name: tokenBalance.amount.symbol.name,
                                                                         desc: "", iconUrl: "", supply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         maxSupply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         symbol: tokenBalance.amount.symbol, url: "", blacklisted: true)
                                
                                self.tokenContracts.append(unknownTokenContract)
                                
                            }
                            
                        }
                        
                        retval = tokenBalances
                        
                    }
                    
                    completion(.success(retval))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(ProtonError.error("MESSAGE => Account missing chainProvider")))
        }
        
    }
    
    // MARK: - ESR Functions
    // 🚧 UNDER CONSTRUCTION
    
    /**
     🚧 UNDER CONSTRUCTION
     Use this to parse an esr signing request.
     - Parameter withURL: URL passed when opening from custom uri: esr://
     - Parameter completion: Closure thats called when the function is complete. Will return object to be used for displaying request
     */
    public func parseESR(withURL url: URL, completion: @escaping (ESR?) -> ()) {
        
        do {
            
            let signingRequest = try SigningRequest(url.absoluteString)
            let chainId = signingRequest.chainId
            
            guard let requestingAccountName = signingRequest.getInfo("account", as: String.self) else { completion(nil); return }
            guard let sid = signingRequest.getInfo("sid", as: String.self) else { completion(nil); return }
            guard let account = self.activeAccount, account.chainId == String(chainId) else { completion(nil); return }
            guard let chainProvider = account.chainProvider else { completion(nil); return }
            
            var requestingAccount = Account(chainId: chainId.description, name: requestingAccountName)
            
            WebServices.shared.addSeq(FetchUserAccountInfoOperation(account: requestingAccount, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let acc):
                    
                    if let acc = acc as? Account {
                        requestingAccount = acc
                    }
                    
                    if signingRequest.isIdentity {
                        
                        let response = ESR(requestor: requestingAccount, signer: account, signingRequest: signingRequest, sid: sid, actions: [])
                        self.esr = response
                        completion(response)
                        
                    } else {
                        
                        var abiAccounts = signingRequest.actions.map { $0.account }
                        abiAccounts = abiAccounts.unique()
                        
                        var abiAccountsProcessed = 0
                        var rawAbis: [String: API.V1.Chain.GetRawAbi.Response] = [:]
                        
                        if abiAccounts.count == 0 { completion(nil); return }
                        
                        let abidecoder = ABIDecoder()
                        
                        for abiAccount in abiAccounts {
                            
                            WebServices.shared.addMulti(FetchRawAbiOperation(account: abiAccount, chainProvider: chainProvider)) { result in
                                
                                abiAccountsProcessed += 1
                                
                                switch result {
                                case .success(let rawAbi):
                                    
                                    if let rawAbi = rawAbi as? API.V1.Chain.GetRawAbi.Response {
                                        
                                        rawAbis[abiAccount.stringValue] = rawAbi
                                        
                                    }
                                    
                                    if abiAccountsProcessed == abiAccounts.count && abiAccounts.count == rawAbis.count {
                                        
                                        let actions: [ESRAction] = signingRequest.actions.compactMap {
                                            
                                            let account = $0.account
                                            
                                            if let abi = rawAbis[account.stringValue]?.decodedAbi { // TODO
                                                
                                                if let transferActionABI = try? abidecoder.decode(TransferActionABI.self, from: $0.data) {
                                                    
                                                    let symbol = transferActionABI.quantity.symbol
                                                    
                                                    if let tokenContract = self.tokenContracts.first(where: { $0.chainId == String(chainId)
                                                                                                                && $0.symbol == symbol && $0.contract == account }) {
                                                        
                                                        let formatter = NumberFormatter()  // TODO: make this more effiecent
                                                        formatter.numberStyle = .currency
                                                        formatter.locale = Locale(identifier: "en_US")
                                                        let extra = formatter.string(for: transferActionABI.quantity.value * tokenContract.usdRate) ?? "$0.00"
                                                        
                                                        
                                                        let basicDisplay = ESRAction.BasicDisplay(actiontype: .transfer, name: tokenContract.name,
                                                                                                  secondary: transferActionABI.quantity.stringValue, extra: "-\(extra)", tokenContract: tokenContract)
                                                        
                                                        return ESRAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay, abi: abi)
                                                        
                                                    }

                                                } else {
                                                    
                                                    let basicDisplay = ESRAction.BasicDisplay(actiontype: .custom, name: $0.name.stringValue.uppercased(),
                                                                                              secondary: nil, extra: nil, tokenContract: nil)
                                                    
                                                    return ESRAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay, abi: abi)
                                                    
                                                }

                                            }
                                            
                                            return nil
                                            
                                        }
                                        
                                        print("ESR ACTIONS => \(actions.count)")
                                        
                                        if actions.count > 0 {
                                            
                                            let response = ESR(requestor: requestingAccount, signer: account, signingRequest: signingRequest, sid: sid, actions: actions)
                                            self.esr = response
                                            completion(response)

                                        } else {
                                            completion(nil)
                                        }

                                    }
                                    
                                case .failure(let error):
                                    print("ERROR: \(error.localizedDescription)")
                                    completion(nil)
                                }
                                
                            }
                            
                        }
                        
                    }

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
     🚧 UNDER CONSTRUCTION
     Use this to decline signing request
     - Parameter completion: Closure thats called when the function is complete.
     */
    public func declineESR(completion: @escaping () -> ()) {
        
        self.esr = nil
        completion()
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION
     Use this to accept signing request
     - Parameter completion: Closure thats called when the function is complete.
     */
    public func acceptESR(completion: @escaping (URL?) -> ()) {
        
        guard let esr = self.esr else { completion(nil); return }
        
        Authentication.shared.authenticate { success, _, error in
            
            if success {
                
                if esr.signingRequest.isIdentity {
                    
                    self.handleIdentityESR { url in

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        
                            self.esr = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            
                                print(self.esrSessions.count)
                                completion(url)
                                
                            }
                            
                        }

                    }
                    
                } else if esr.signingRequest.actions.count > 0 {

                    self.handleActionsESR { url in
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        
                            self.esr = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            
                                print(self.esrSessions.count)
                                completion(url)
                                
                            }
                            
                        }
                        
                    }
                    
                } else {
                    
                    self.esr = nil
                    completion(nil)
                    
                }

            } else {
                self.esr = nil
                completion(nil) // return error
            }
            
        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION
     Use this to remove authorization
     - Parameter forId: esr Session Id
     */
    public func removeESRSession(forId: String) {
        
        guard let esrSession = self.esrSessions.first(where: { $0.id == forId }) else { return }
        WebServices.shared.addMulti(PostRemoveSessionESROperation(esrSession: esrSession)) { _ in }
        
    }
    
    private func handleActionsESR(completion: @escaping (URL?) -> ()) {
        
        guard let privateKey = esr?.signer.privateKey(forPermissionName: "active") else { completion(nil); return }
        guard let signer = esr?.signer else { completion(nil); return }
        guard let chainProvider = signer.chainProvider else { completion(nil); return }
        guard let chainId = esr?.signingRequest.chainId else { completion(nil); return }
        guard let sid = esr?.sid else { completion(nil); return }
        guard let actions = esr?.actions else { completion(nil); return }
        
        var abis: [Name: ABI] = [:]
        
        for action in actions {
            if let abi = action.abi {
                abis[action.account] = abi
            }
        }
        
        if abis.count == 0 { completion(nil); return }
        
        WebServices.shared.addSeq(FetchChainInfoOperation(chainProvider: chainProvider)) { result in
            
            switch result {
            case .success(let info):
                
                if let info = info as? API.V1.Chain.GetInfo.Response {
                    
                    let expiration = info.headBlockTime.addingTimeInterval(60)
                    let header = TransactionHeader(expiration: TimePointSec(expiration),
                                                   refBlockId: info.lastIrreversibleBlockId)
                    
                    do {

                        self.esr?.resolved = try self.esr?.signingRequest.resolve(using: PermissionLevel(signer.name, Name("active")), abis: abis, tapos: header)
                        guard let _ = self.esr?.resolved else { completion(nil); return }
                        let sig = try privateKey.sign(self.esr!.resolved!.transaction.digest(using: chainId))
                        let signedTransaction = SignedTransaction(self.esr!.resolved!.transaction, signatures: [sig])
                        
                        if self.esr!.signingRequest.broadcast {
                            
                            WebServices.shared.addSeq(PushTransactionOperation(account: signer, chainProvider: chainProvider, signedTransaction: signedTransaction)) { result in
                                
                                switch result {
                                case .success(let res):
                                    
                                    if let res = res as? API.V1.Chain.PushTransaction.Response {
                                        
                                        guard let callback = self.esr!.resolved!.getCallback(using: [sig], blockNum: res.processed.blockNum) else { completion(nil); return }
                                        
                                        self.update { _ in }
                                        
                                        if callback.background {
                                            
                                            WebServices.shared.addSeq(PostBackgroundESROperation(esr: self.esr!, sig: sig, blockNum: res.processed.blockNum)) { result in
                                                
                                                switch result {
                                                case .success:

                                                    completion(nil)
                                                    
                                                case .failure:

                                                    completion(nil)
                                                    
                                                }

                                            }
                                            
                                        } else {
                                            
                                            var newPath = callback.url
                                            newPath = newPath.replacingOccurrences(of: "{{sid}}", with: sid)
                                            print(newPath)
                                            
                                            completion(URL(string: newPath))
                                            
                                        }
                                        
                                    }

                                case .failure:

                                    completion(nil)
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            completion(nil)
                            
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        completion(nil)
                    }

                } else {
                    completion(nil)
                }
                
            case .failure(let error):
                print(error)
                completion(nil)
            }
            
        }

    }
    
    private func handleIdentityESR(completion: @escaping (URL?) -> ()) {
        
        guard let privateKey = esr?.signer.privateKey(forPermissionName: "active") else { completion(nil); return }
        guard let signer = esr?.signer else { completion(nil); return }
        guard let chainId = esr?.signingRequest.chainId else { completion(nil); return }
        guard let sid = esr?.sid else { completion(nil); return }

        do {

            self.esr?.resolved = try esr?.signingRequest.resolve(using: PermissionLevel(signer.name, Name("active")))
            guard let _ = self.esr?.resolved else { completion(nil); return }
            let sig = try privateKey.sign(self.esr!.resolved!.transaction.digest(using: chainId))
            guard let callback = esr!.resolved!.getCallback(using: [sig], blockNum: nil) else { completion(nil); return }
            print(callback.url)
            print(sig)
            
            let session = ESRSession(requestor: self.esr!.requestor, signer: signer.name,
                                     chainId: String(chainId), sid: sid,
                                     callbackUrl: callback.url, rs: self.esr?.signingRequest.getInfo("rs", as: String.self))
            
            if callback.background {
                
                WebServices.shared.addSeq(PostBackgroundESROperation(esr: self.esr!, sig: sig, blockNum: nil)) { result in
                    
                    switch result {
                    case .success:

                        if let idx = self.esrSessions.firstIndex(of: session) {
                            self.esrSessions[idx] = session
                        } else {
                            self.esrSessions.append(session)
                        }
                        
                        completion(nil)
                        
                    case .failure:

                        completion(nil)
                        
                    }

                }

            } else {
                
                var newPath = callback.url
                newPath = newPath.replacingOccurrences(of: "{{sid}}", with: sid)
                print(newPath)
                
                if let idx = self.esrSessions.firstIndex(of: session) {
                    self.esrSessions[idx] = session
                } else {
                    self.esrSessions.append(session)
                }
                
                completion(URL(string: newPath))
                
            }
            
        } catch {
            
            completion(nil)
        }
        
    }
}

public enum ProtonError: Error, LocalizedError {
    
    case error(String)
    case chain(String)
    case history(String)
    case esr(String)

    public var errorDescription: String? {
        switch self {
        case .error(let message):
            return "⚛️ PROTON ERROR\n======================\n\(message)\n======================\n"
        case .chain(let message):
            return "⚛️⛓️ PROTON CHAIN ERROR\n======================\n\(message)\n======================\n"
        case .history(let message):
            return "⚛️📜 PROTON HISTORY ERROR\n======================\n\(message)\n======================\n"
        case .esr(let message):
            return "⚛️✍️ PROTON SIGNING REQUEST ERROR\n======================\n\(message)\n======================\n"
        }
    }
    
}
