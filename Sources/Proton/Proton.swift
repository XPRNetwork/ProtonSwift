//
//  Proton.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import secp256k1
import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import KeychainAccess
import WebOperations
import LocalAuthentication
import CommonCrypto

/**
 The Proton class is the heart of the ProtonSwift SDK.
 */
public class Proton: ObservableObject {
    
    /**
     The proton config object which is a required param for initialisation of Proton
    */
    public struct Config {
        
        public enum Environment: String {
            case testnet = "https://api-dev.protonchain.com"
            case mainnet = "https://api.protonchain.com"
        }
        
        /// The base url used for api requests to proton sdk api's
        public var baseUrl: String
        
        /**
         Use this function as your starting point to initialize the singleton class Proton
         - Parameter baseUrl: The base url used for api requests to proton sdk api's
         */
        public init(baseUrl: String = Environment.testnet.rawValue) {
            self.baseUrl = baseUrl
        }
        
        /**
         Use this function as your starting point to initialize the singleton class Proton
         - Parameter environment: The environment used for api requests to proton sdk api's
         */
        public init(environment: Environment = Environment.testnet) {
            self.baseUrl = environment.rawValue
        }
        
    }
    
    /**
     Proton typealias of the EOSIO.Name
    */
    public typealias Name = EOSIO.Name
    
    /**
     Proton typealias of the EOSIO.PrivateKey
    */
    public typealias PrivateKey = EOSIO.PrivateKey
    
    /**
     Proton typealias of the EOSIO.Asset
    */
    public typealias Asset = EOSIO.Asset
    
    /**
     Proton typealias of the EOSIO.Asset.Symbol
    */
    public typealias Symbol = EOSIO.Asset.Symbol
    
    /**
     Proton typealias of the of WebOperations WebError
    */
    public typealias ProtonError = WebError
    
    /**
     The proton config which gets set during initialisation
    */
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
    
    /**
     The shared instance of the Proton class.
     Use this for accessing functionality after initialisation of Proton
    */
    public static let shared = Proton()
    
    /**
     Internal pointer to various storage structures
    */
    var storage: Persistence!
    
    static let operationQueueSeq = "proton.swift.seq"
    static let operationQueueMulti = "proton.swift.multi"
    
    private struct StakingFetchResult {
        var staking: Staking?
        var stakingRefund: StakingRefund?
    }
    
    /**
     Private init
     */
    private init() {
        
        guard let _ = Proton.config else {
            fatalError("ERROR: You must call setup before accessing Proton.shared")
        }
        
        let operationQueueSeq = OperationQueue()
        operationQueueSeq.qualityOfService = .utility
        operationQueueSeq.maxConcurrentOperationCount = 1
        
        let operationQueueMulti = OperationQueue()
        operationQueueMulti.qualityOfService = .utility
        
        WebOperations.shared.addCustomQueue(operationQueueSeq, forKey: Proton.operationQueueSeq)
        WebOperations.shared.addCustomQueue(operationQueueMulti, forKey: Proton.operationQueueMulti)
        
        self.storage = Persistence()
        
        self.loadAll()
        
        print("🧑‍💻 LOAD COMPLETED")
        print("ACTIVE ACCOUNT => \(String(describing: self.account?.name.stringValue))")
        print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
        print("TOKEN BALANCES => \(self.tokenBalances.count)")
        print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
        print("SIGNING REQUEST SESSIONS => \(self.protonSigningRequestSessions.count)")
        
    }
    
    /**
     Checks if user has authentication enabled. At least passcode set is required
     - Returns: Bool
     */
    public func authenticationEnabled() -> Bool {
        let context = LAContext()
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            return true
        }
        return false
    }

    // MARK: - Data Containers
    
    /**
     Live updated chainProvider.
     */
    @Published public var chainProvider: ChainProvider? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }

    /**
     Live updated array of tokenContracts
     */
    @Published public var tokenContracts: [TokenContract] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated array of tokenBalances.
     */
    @Published public var tokenBalances: [TokenBalance] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated array of tokenTransferActions.
     */
    @Published public var tokenTransferActions: [String: [TokenTransferAction]] = [:] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated array of contacts.
     */
    @Published public var contacts: [Contact] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated array of producers.
     */
    @Published public var producers: [Producer] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated array of protonSigningRequestSessions.
     */
    @Published public var protonSigningRequestSessions: [ProtonSigningRequestSession] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated protonSigningRequest.
     */
    @Published public var protonSigningRequest: ProtonSigningRequest? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated account.
     */
    @Published public var account: Account? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated GlobalsXPR.
     */
    @Published public var globalsXPR: GlobalsXPR? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Data Functions
    
    /**
     Loads all data objects from disk into memory
     */
    public func loadAll() {

        self.account = Account.create(dictionary: self.storage.getDefaultsItem(forKey: "account"))
        self.chainProvider = self.storage.getDefaultsItem(ChainProvider.self, forKey: "chainProvider") ?? nil
        self.tokenContracts = self.storage.getDefaultsItem([TokenContract].self, forKey: "tokenContracts") ?? []
        self.tokenBalances = self.storage.getDefaultsItem([TokenBalance].self, forKey: "tokenBalances") ?? []
        self.tokenTransferActions = self.storage.getDefaultsItem([String: [TokenTransferAction]].self, forKey: "tokenTransferActions") ?? [:]
        self.protonSigningRequestSessions = self.storage.getDefaultsItem([ProtonSigningRequestSession].self, forKey: "protonSigningRequestSessions") ?? []
        self.contacts = self.storage.getDefaultsItem([Contact].self, forKey: "contacts") ?? []
        self.producers = self.storage.getDefaultsItem([Producer].self, forKey: "contacts") ?? []
        self.globalsXPR = self.storage.getDefaultsItem(GlobalsXPR.self, forKey: "globalsXPR") ?? nil
        
    }
    
    /**
     Saves all current data objects that are in memory to disk
     */
    public func saveAll() {
        
        self.storage.setDefaultsItem(self.account, forKey: "account")
        self.storage.setDefaultsItem(self.chainProvider, forKey: "chainProvider")
        self.storage.setDefaultsItem(self.tokenContracts, forKey: "tokenContracts")
        self.storage.setDefaultsItem(self.tokenBalances, forKey: "tokenBalances")
        self.storage.setDefaultsItem(self.tokenTransferActions, forKey: "tokenTransferActions")
        self.storage.setDefaultsItem(self.protonSigningRequestSessions, forKey: "protonSigningRequestSessions")
        self.storage.setDefaultsItem(self.contacts, forKey: "contacts")
        self.storage.setDefaultsItem(self.producers, forKey: "producers")
        self.storage.setDefaultsItem(self.globalsXPR, forKey: "globalsXPR")
        
    }
    
    /**
     Use this to force storing the key into the keychain.
     - Parameter privateKey: PrivateKey
     - Parameter chainId: chainId for the account
     - Parameter completion: Closure returning Result
     */
    public func store(privateKey: PrivateKey,
                      completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        do {
            
            let publicKey = try privateKey.getPublic()
            
            self.storage.setKeychainItem(privateKey.stringValue, forKey: publicKey.stringValue) { result in
                
                switch result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }

        } catch {
            completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
        }
        
    }
    
    /**
     Fetches the account from the chain, the stores private key and sets account active
     - Parameter withName: Proton account name not including @
     - Parameter andPrivateKey: PrivateKey
     - Parameter chainId: chainId for the account
     - Parameter completion: Closure returning Result
     */
    public func setAccount(withName accountName: String, andPrivateKey privateKey: PrivateKey,
                           completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        self.fetchAccount(Account(chainId: chainProvider.chainId, name: accountName)) { result in
            switch result {
            case .success(let account):
                self.setAccount(account, withPrivateKeyString: privateKey.stringValue) { result in
                    completion(result)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     Sets the active account, fetchs and updates. This includes, account names, avatars, balances, etc
      Use this for switching accounts when you know the private key has already been stored.
     - Parameter withName: Proton account name not including @
     - Parameter chainId: chainId for the account
     - Parameter completion: Closure returning Result
     */
    public func setAccount(withName accountName: String, chainId: String,
                           completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        self.setAccount(Account(chainId: chainId, name: accountName)) { result in
            switch result {
            case .success(let account):
                completion(.success(account))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     Use this function to store the private key and set the account after finding the account you want to save via findAccounts
     - Parameter account: Account object, normally retrieved via findAccounts
     - Parameter withPrivateKeyString: Wif formated private key
     - Parameter completion: Closure returning Result
     */
    public func setAccount(_ account: Account, withPrivateKeyString privateKey: String, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            if account.isKeyAssociated(publicKey: publicKey) {
                
                self.storage.setKeychainItem(privateKey, forKey: publicKey.stringValue) { result in
                    
                    switch result {
                    case .success:
                        self.setAccount(account) { result in
                            switch result {
                            case .success(let account):
                                completion(.success(account))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }

            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with Account")))
            }

        } catch {
            completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
        }
        
    }
    
    /**
     Fetchs all required data objects from external data sources. This should be done at startup
     - Parameter completion: Closure returning Result
     */
    public func updateDataRequirements(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        WebOperations.shared.add(FetchChainProviderOperation(), toCustomQueueNamed: Proton.operationQueueSeq) { result in
            
            switch result {
                
            case .success(let chainProvider):
                
                if let chainProvider = chainProvider as? ChainProvider {
                    
                    self.chainProvider = chainProvider
                    let tokenContracts = chainProvider.tokenContracts
                    
                    WebOperations.shared.add(FetchTokenContractsOperation(chainProvider: chainProvider, tokenContracts: tokenContracts),
                                             toCustomQueueNamed: Proton.operationQueueSeq) { result in
                        
                        switch result {
                            
                        case .success(let tokenContracts):
                            
                            if let tokenContracts = tokenContracts as? [TokenContract] {
                                
                                for var tokenContract in tokenContracts {
                                    if let idx = self.tokenContracts.firstIndex(of: tokenContract) {
                                        tokenContract.rates = self.tokenContracts[idx].rates
                                        self.tokenContracts[idx] = tokenContract
                                    } else {
                                        self.tokenContracts.append(tokenContract)
                                    }
                                }
                                
                            }
                            
                        case .failure: break
                        }
                        
                        self.updateExchangeRates { _ in }
                        self.updateProducers { _ in }
                        self.updateGlobalsXPR { _ in }
                        
                        completion(.success(true))
                        
                    }
                    
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        
    }
    
    /**
     Updates the GlobalsXPR object. This has information like min required bp votes, staking period, etc.
     - Parameter completion: Closure returning Result
     */
    public func updateGlobalsXPR(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchGlobalsXPROperation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {
                
            case .success(let globalsXPRABI):
                
                if let globalsXPRABI = globalsXPRABI as? GlobalsXPRABI {
                    self.globalsXPR = GlobalsXPR(globalsXPRABI: globalsXPRABI)
                }
                
            case .failure: break
            }
            
            completion(.success(true))
            
        }
        
    }
    
    /**
     Updates all TokenContract data objects with latest exchange rates from external data sources.
     - Parameter completion: Closure returning Result
     */
    public func updateExchangeRates(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchExchangeRatesOperation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {
                
            case .success(let tokens):
                
                if let tokens = tokens as? [[String: Any]] {
                    
                    for token in tokens {
                        
                        guard let contract = token["contract"] as? String else { return }
                        guard let symbol = token["symbol"] as? String else { return }
                        guard let rates = token["rates"] as? [String: Double] else { return }
                        if let idx = self.tokenContracts.firstIndex(where: { $0.id == "\(contract):\(symbol)" }) {
                            self.tokenContracts[idx].rates = rates
                            if let iid = self.tokenBalances.firstIndex(where: { $0.tokenContractId == "\(contract):\(symbol)" }) {
                                self.tokenBalances[iid].updatedAt = self.tokenContracts[idx].updatedAt
                            }
                        }
                        
                    }
                    
                }
                
            case .failure: break
            }
            
            completion(.success(true))
            
        }
        
    }
    
    /**
     Fetchs and updates the active account. This includes, account names, avatars, balances, etc
     - Parameter completion: Closure returning Result
     */
    public func updateAccount(completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard var account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        self.fetchAccount(account) { result in
            
            switch result {
            case .success(let returnAccount):
                
                account = returnAccount
                self.account = account
                
                self.fetchAccountUserInfo(forAccount: account) { result in
                    
                    switch result {
                    case .success(let returnAccount):
                        
                        account = returnAccount
                        self.account = account
                        
                        self.fetchAccountVotingAndStakingInfo(forAccount: account) { result in
                            
                            switch result {
                            case .success(let stakingFetchResult):
                                
                                account.staking = stakingFetchResult.staking
                                account.stakingRefund = stakingFetchResult.stakingRefund
                                
                                self.account = account
                                
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
                                                        
                                                        var tokenTransferActions = self.tokenTransferActions[tokenBalance.tokenContractId] ?? []

                                                        for transferAction in transferActions {
                                                            
                                                            if let idx = tokenTransferActions.firstIndex(of: transferAction) {
                                                                tokenTransferActions[idx] = transferAction
                                                            } else {
                                                                tokenTransferActions.append(transferAction)
                                                            }
                                                            
                                                        }
                                                        
                                                        if tokenTransferActions.count > 0 {
                                                            tokenTransferActions.sort(by: {  $0.date > $1.date })
                                                            self.tokenTransferActions[tokenBalance.tokenContractId] = Array(tokenTransferActions.prefix(100))
                                                        }

                                                    case .failure: break
                                                    }
                                                    
                                                    if tokenBalancesProcessed == tokenBalancesCount {

                                                        self.fetchContacts(forAccount: account) { result in
                                                            
                                                            switch result {
                                                            case .success(let contacts):
                                                                
                                                                for contact in contacts {
                                                                    if let idx = self.contacts.firstIndex(of: contact) {
                                                                        self.contacts[idx] = contact
                                                                    } else {
                                                                        self.contacts.append(contact)
                                                                    }
                                                                }
                                                                
                                                            case .failure: break
                                                            }

                                                            completion(.success(account))
                                                            self.saveAll()
                                                            
                                                        }

                                                    }

                                                }
                                                
                                            }
                                            
                                        } else {
                                            completion(.failure(Proton.ProtonError(message: "No TokenBalances found for account: \(account.name)")))
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
                
            case .failure(let error):
                completion(.failure(error))
            }

        }
        
    }
    
    /**
     Changes the account's userdefined name on chain
     - Parameter userDefinedName: New user defined name
     - Parameter andPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func changeAccountUserDefinedName(withUserDefinedName userDefinedName: String, andPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard var account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let chainProvider = self.account?.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        signforAccountUpdate(withPrivateKey: privateKey) { result in
            
            switch result {
            case .success(let signature):
                
                WebOperations.shared.add(ChangeUserAccountNameOperation(account: account, chainProvider: chainProvider, signature: signature.stringValue, userDefinedName: userDefinedName), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                    
                    switch result {
                    case .success:
                        
                        self.fetchAccountUserInfo(forAccount: account) { result in
                            switch result {
                            case .success(let returnAccount):
                                account = returnAccount
                                self.account = account
                                completion(.success(account))
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
     Changes the account's avatar on chain
     - Parameter withImage: AvatarImage which is platform dependent alias. UIImage for iOS, NSImage for macOS
     - Parameter andPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func changeAccountAvatar(withImage image: AvatarImage, andPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard var account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let chainProvider = account.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        signforAccountUpdate(withPrivateKey: privateKey) { result in
            
            switch result {
            case .success(let signature):
                
                WebOperations.shared.add(ChangeUserAccountAvatarOperation(account: account, chainProvider: chainProvider, signature: signature.stringValue, image: image), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                    
                    switch result {
                    case .success:
                        
                        self.fetchAccountUserInfo(forAccount: account) { result in
                            switch result {
                            case .success(let returnAccount):
                                account = returnAccount
                                self.account = account
                                completion(.success(account))
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
     Changes the account's userdefined name and avatar on chain
     - Parameter withUserDefinedName: New user defined name
     - Parameter image: AvatarImage
     - Parameter andPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func changeAccountUserDefinedNameAndAvatar(withUserDefinedName userDefinedName: String, image: AvatarImage, andPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        guard var account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let chainProvider = self.account?.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        signforAccountUpdate(withPrivateKey: privateKey) { result in
            
            switch result {
            case .success(let signature):
                
                WebOperations.shared.add(ChangeUserAccountNameOperation(account: account, chainProvider: chainProvider, signature: signature.stringValue, userDefinedName: userDefinedName), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                    
                    switch result {
                    case .success:
                        
                        WebOperations.shared.add(ChangeUserAccountAvatarOperation(account: account, chainProvider: chainProvider, signature: signature.stringValue, image: image), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                            
                            switch result {
                            case .success:
                                
                                self.fetchAccountUserInfo(forAccount: account) { result in
                                    switch result {
                                    case .success(let returnAccount):
                                        account = returnAccount
                                        self.account = account
                                        completion(.success(account))
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
                
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        
    }
    
    /**
     Use this function to obtain a list of Accounts which match a given private key. These accounts are not stored. If you want to store the Account and private key, you should then call storePrivateKey function
     - Parameter forPrivateKeyString: Wif formated private key
     - Parameter completion: Closure returning Result
     */
    public func findAccounts(forPrivateKeyString privateKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            findAccounts(forPublicKeyString: publicKey.stringValue) { result in
                switch result {
                case .success(let accounts):
                    completion(.success(accounts))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Unable to parse Private Key")))
        }
        
    }
    
    /**
     Checks the chain for presence of account by name
     - Parameter hasAccountWithName: String account name
     - Parameter completion: Closure returning Result
     */
    public func chain(hasAccountWithName accountName: String, completion: @escaping ((Result<Bool, Error>) -> Void)) {

        if let chainProvider = self.chainProvider {
            
            WebOperations.shared.add(FetchAccountOperation(accountName: accountName, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                
                switch result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Missing chainProvider")))
        }
        
    }
    
    /**
     Creates a transfer, signs and pushes that transfer to the chain
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter to: The account to be transfered to
     - Parameter quantity: The amount to be transfered
     - Parameter tokenContract: The TokenContract that's being transfered
     - Parameter memo: The memo for the transfer
     - Parameter completion: Closure returning Result
     */
    public func transfer(withPrivateKey privateKey: PrivateKey, to: Name, quantity: Double, tokenContract: TokenContract, memo: String = "", completion: @escaping ((Result<TokenTransferAction, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let chainProvider = account.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        guard var tokenBalance = self.tokenBalances.first(where: { $0.tokenContractId == tokenContract.id }) else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for \(tokenContract.name)")))
            return
        }
        
        if quantity > tokenBalance.amount.value {
            completion(.failure(Proton.ProtonError(message: "Account balance insufficient")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let transfer = TransferActionABI(from: account.name, to: to, quantity: Asset(quantity, tokenContract.symbol), memo: memo)
                
                guard let action = try? Action(account: tokenContract.contract, name: "transfer", authorization: [PermissionLevel(account.name, "active")], value: transfer) else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                self.signAndPushTransaction(withActions: [action], andPrivateKey: privateKey) { result in
                    
                    switch result {
                    case .success(let response):
                        
                        let tokenTransferAction = TokenTransferAction(chainId: chainProvider.chainId, accountId: account.id, tokenBalanceId: tokenBalance.id, tokenContractId: tokenContract.id, name: action.name.stringValue, contract: action.account, trxId: String(response.transactionId), date: Date(), sent: true, from: account.name, to: to, quantity: transfer.quantity, memo: transfer.memo)
                        
                        var tokenTransferActions = self.tokenTransferActions[tokenBalance.tokenContractId] ?? []
                        
                        tokenTransferActions.append(tokenTransferAction)
                        tokenTransferActions.sort(by: {  $0.date > $1.date })
                        self.tokenTransferActions[tokenBalance.tokenContractId] = Array(tokenTransferActions.prefix(100))
                        
                        if tokenTransferAction.sent {
                            tokenBalance.amount -= tokenTransferAction.quantity
                        } else {
                            tokenBalance.amount += tokenTransferAction.quantity
                        }
                        
                        if let index = self.tokenBalances.firstIndex(of: tokenBalance) {
                            self.tokenBalances[index] = tokenBalance
                        }

                        completion(.success(tokenTransferAction))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Key not valid for transaction")))
        }

    }
    
    /**
     Stakes XPR
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter quantity: Amount to added or removed from stake. Postive for adding stake, Negative for removing stake. Cannot be zero
     - Parameter completion: Closure returning Result
     */
    public func stake(withPrivateKey privateKey: PrivateKey, quantity: Double, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard var tokenBalance = account.systemTokenBalance else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        guard var tokenContract = tokenBalance.tokenContract else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        if quantity == Double.zero {
            completion(.failure(Proton.ProtonError(message: "Cannot stake zero value")))
            return
        }
        
        let availableBalance = account.availableSystemBalance().value
        
        if availableBalance < quantity {
            completion(.failure(Proton.ProtonError(message: "Not enough availbe balance to stake \(quantity)")))
            return
        }
        
        func getActionData(account: Account, quantity: Double, symbol: Asset.Symbol) -> ABICodable {
            if quantity > 0 {
                return StakeXPRABI(from: account.name, stake_xpr_quantity: Asset(quantity, tokenContract.symbol))
            } else {
                return UnStakeXPRABI(from: account.name, unstake_xpr_quantity: Asset(quantity * -1.0, tokenContract.symbol))
            }
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {
                
                let data = try ABIEncoder.encode(getActionData(account: account, quantity: quantity, symbol: tokenContract.symbol)) as Data
                let action = Action(account: Name("eosio"), name: quantity > 0 ? "stakexpr" : "unstakexpr", authorization: [PermissionLevel(account.name, "active")], data: data)
                
                self.signAndPushTransaction(withActions: [action], andPrivateKey: privateKey) { result in
                    
                    switch result {
                    case .success(let response):
                        
                        if let actions = response.processed["actions"] as? [[String: Any]] {
                            
                            for action in actions {
                                
                                print(action)
                                
                                if let act = action["act"] as? [String: Any], let name = act["name"] as? String, let acc = act["account"] as? String {
                                    
                                    if name == "transfer" && acc == "eosio.token" {
                                        
                                        if let stakeAction = TokenTransferAction(account: account, tokenBalance: tokenBalance, dictionary: action) {
                                            
                                            var tokenTransferActions = self.tokenTransferActions[tokenBalance.tokenContractId] ?? []
                                            tokenTransferActions.append(stakeAction)
                                            tokenTransferActions.sort(by: {  $0.date > $1.date })
                                            self.tokenTransferActions[tokenBalance.tokenContractId] = Array(tokenTransferActions.prefix(100))
                                            
                                            if quantity > 0 {
                                                tokenBalance.amount -= stakeAction.quantity
                                            } else {
                                                tokenBalance.amount += stakeAction.quantity
                                            }
                                            
                                            if let index = self.tokenBalances.firstIndex(of: tokenBalance) {
                                                self.tokenBalances[index] = tokenBalance
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        completion(.success(response))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Key not valid for transaction")))
        }
        
    }
    
    /**
     Claims XPR staking rewards
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func claimRewards(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let staking = self.account?.staking, staking.isQualified else {
            completion(.failure(Proton.ProtonError(message: "Account has no rewards to claim")))
            return
        }
        
        guard var tokenBalance = self.tokenBalances.first(where: { $0.tokenContract?.systemToken == true }) else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        if staking.claimAmount.value == .zero {
            completion(.failure(Proton.ProtonError(message: "Account has no rewards to claim")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let claim = ClaimRewardsABI(owner: account.name)
                
                guard let action = try? Action(account: Name("eosio"), name: "voterclaim", authorization: [PermissionLevel(account.name, "active")], value: claim) else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                self.signAndPushTransaction(withActions: [action], andPrivateKey: privateKey) { result in
                    
                    switch result {
                    case .success(let response):
                        
                        if let actions = response.processed["actions"] as? [[String: Any]] {
                            
                            for action in actions {
                                
                                print(action)
                                
                                if let act = action["act"] as? [String: Any], let name = act["name"] as? String, let acc = act["account"] as? String {
                                    
                                    if name == "transfer" && acc == "eosio.token" {
                                        
                                        if let claimReceivedAction = TokenTransferAction(account: account, tokenBalance: tokenBalance, dictionary: action) {
                                            
                                            var tokenTransferActions = self.tokenTransferActions[tokenBalance.tokenContractId] ?? []
                                            tokenTransferActions.append(claimReceivedAction)
                                            tokenTransferActions.sort(by: {  $0.date > $1.date })
                                            self.tokenTransferActions[tokenBalance.tokenContractId] = Array(tokenTransferActions.prefix(100))
                                            
                                            tokenBalance.amount += claimReceivedAction.quantity
                                            
                                            if let index = self.tokenBalances.firstIndex(of: tokenBalance) {
                                                self.tokenBalances[index] = tokenBalance
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        completion(.success(response))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Key not valid for transaction")))
        }
        
    }
    
    /**
     Refunds unstaking amount if the deferred action did not complete
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func refund(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard var tokenBalance = self.tokenBalances.first(where: { $0.tokenContract?.systemToken == true }) else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let refund = RefundXPRABI(owner: account.name)
                
                guard let action = try? Action(account: Name("eosio"), name: "refundxpr", authorization: [PermissionLevel(account.name, "active")], value: refund) else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                self.signAndPushTransaction(withActions: [action], andPrivateKey: privateKey) { result in
                    
                    switch result {
                    case .success(let response):
                        
                        if let actions = response.processed["actions"] as? [[String: Any]] {
                            
                            for action in actions {
                                
                                print(action)
                                
                                if let act = action["act"] as? [String: Any], let name = act["name"] as? String, let acc = act["account"] as? String {
                                    
                                    if name == "transfer" && acc == "eosio.token" {
                                        
                                        if let claimReceivedAction = TokenTransferAction(account: account, tokenBalance: tokenBalance, dictionary: action) {
                                            
                                            var tokenTransferActions = self.tokenTransferActions[tokenBalance.tokenContractId] ?? []
                                            tokenTransferActions.append(claimReceivedAction)
                                            tokenTransferActions.sort(by: {  $0.date > $1.date })
                                            self.tokenTransferActions[tokenBalance.tokenContractId] = Array(tokenTransferActions.prefix(100))
                                            
                                            tokenBalance.amount += claimReceivedAction.quantity
                                            
                                            if let index = self.tokenBalances.firstIndex(of: tokenBalance) {
                                                self.tokenBalances[index] = tokenBalance
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        completion(.success(response))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Key not valid for transaction")))
        }
        
    }
    
    /**
     Votes for block producers
     - Parameter forProducers: Array of producer Names
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func vote(forProducers producerNames: [Name], withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Any?, Error>) -> Void)) {

        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let producerNames = producerNames.sorted { $0.stringValue < $1.stringValue }
                
                let vote = VoteProducersABI(voter: account.name, producers: producerNames)
                
                guard let action = try? Action(account: Name("eosio"), name: "voteproducer", authorization: [PermissionLevel(account.name, "active")], value: vote) else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                self.signAndPushTransaction(withActions: [action], andPrivateKey: privateKey) { result in
                    
                    switch result {
                    case .success(let response):
                        completion(.success(response))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
            
        } catch {
            completion(.failure(Proton.ProtonError(message: "Key not valid for transaction")))
        }

    }
    
    /**
     Use this function generate a k1 PrivateKey object. See PrivateKey inside of EOSIO for more details
     */
    public func generatePrivateKey() -> PrivateKey? {
        var bytes = [UInt8](repeating: 0, count: 33)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            fatalError("Unable to create secure random data")
        }
        bytes[0] = 0x80
        return try? PrivateKey(fromK1Data: Data(bytes))
    }
    
    /**
    Creates signature by signing arbitrary string
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func signArbitrary(string: String, withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Signature, Error>) -> Void)) {
                
        guard let signingData = string.data(using: String.Encoding.utf8) else {
            completion(.failure(Proton.ProtonError(message: "Unable generate signing string data")))
            return
        }
        
        do {
            let signature = try privateKey.sign(signingData)
            completion(.success(signature))
            return
        } catch {
            completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
            return
        }

    }
    
    /**
    Signs and pushes transaction
     - Parameter withActions: [Actions]
     - Parameter andPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func signAndPushTransaction(withActions actions: [Action], andPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<API.V1.Chain.PushTransaction.Response, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        WebOperations.shared.add(SignTransactionOperation(chainProvider: chainProvider, actions: actions, privateKey: privateKey), toCustomQueueNamed: Proton.operationQueueSeq) { result in
            
            switch result {
            case .success(let signedTransaction):
                
                if let signedTransaction = signedTransaction as? SignedTransaction {
                    
                    WebOperations.shared.add(PushTransactionOperation(chainProvider: chainProvider, signedTransaction: signedTransaction), toCustomQueueNamed: Proton.operationQueueSeq) { result in

                        switch result {
                        case .success(let response):
                            if let response = response as? API.V1.Chain.PushTransaction.Response {
                                completion(.success(response))
                            } else {
                                completion(.failure(Proton.ProtonError(message: "Unable to push transaction")))
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                        
                    }
                    
                } else {
                    completion(.failure(Proton.ProtonError(message: "Unable to sign transaction")))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        
    }
    
    /**
     :nodoc:
    Creates signature for updating avatar and userdefined name
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    private func signforAccountUpdate(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Signature, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let signingData = account.name.stringValue.data(using: String.Encoding.utf8) else {
            completion(.failure(Proton.ProtonError(message: "Unable generate signing string data")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {
                let signature = try privateKey.sign(signingData)
                completion(.success(signature))
                return
            } else {
                completion(.failure(Proton.ProtonError(message: "Key not associated with active permissions for account")))
            }
    
        } catch {
            completion(.failure(Proton.ProtonError(message: error.localizedDescription)))
            return
        }

    }
    
    /**
     :nodoc:
     Use this function to obtain a list of Accounts which match a given public key. These accounts are not stored. If you want to store the Account and private key, you should then call storePrivateKey function
     - Parameter forPublicKeyString: Wif formated public key
     - Parameter completion: Closure returning Result
     */
    private func findAccounts(forPublicKeyString publicKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        self.fetchKeyAccounts(forPublicKey: publicKey) { result in
            
            switch result {
            case .success(var accounts):
                
                if accounts.count > 0 {
                    
                    let accountCount = accounts.count
                    var accountsProcessed = 0
                    
                    for var account in accounts {
                        
                        self.fetchAccount(account) { result in
                            
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
                    completion(.failure(Proton.ProtonError(message: "No accounts found for publicKey: \(publicKey)")))
                }
            case .failure(let error):
                completion(.failure(error))
            }

        }
        
    }
    
    /**
     :nodoc:
     Sets the active account, fetchs and updates. This includes, account names, avatars, balances, etc
     - Parameter account: Account
     - Parameter completion: Closure returning Result
     */
    private func setAccount(_ account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let activeAccount = self.account, activeAccount == account {
            account = activeAccount
        } else {
            self.account = account
            self.tokenBalances.removeAll()
            self.tokenTransferActions.removeAll()
            self.protonSigningRequestSessions.removeAll()
            self.protonSigningRequest = nil
            self.contacts.removeAll()
        }

        self.updateAccount { result in
            switch result {
            case .success(let account):
                self.account = account
                completion(.success(account))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     :nodoc:
     Fetches token balance for the active account
     - Parameter forTokenBalance: TokenBalance
     - Parameter completion: Closure returning Result
     */
    private func fetchTransferActions(forTokenBalance tokenBalance: TokenBalance, completion: @escaping ((Result<Set<TokenTransferAction>, Error>) -> Void)) {
        
        var retval = Set<TokenTransferAction>()
        
        guard let account = tokenBalance.account else {
            completion(.failure(Proton.ProtonError(message: "TokenBalance missing Account")))
            return
        }
        
        guard let chainProvider = account.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Account missing ChainProvider")))
            return
        }
        
        guard let tokenContract = tokenBalance.tokenContract else {
            completion(.failure(Proton.ProtonError(message: "TokenBalance missing TokenContract")))
            return
        }
        
        WebOperations.shared.add(FetchTokenTransferActionsOperation(account: account, tokenContract: tokenContract,
                                                                       chainProvider: chainProvider, tokenBalance: tokenBalance), toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
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
    
    /**
     :nodoc:
     Fetches the accounts found for the publickey passed
     - Parameter forPublicKey: Wif formated public key
     - Parameter completion: Closure returning Result
     */
    private func fetchKeyAccounts(forPublicKey publicKey: String, completion: @escaping ((Result<Set<Account>, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchKeyAccountsOperation(publicKey: publicKey,
                                                              chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            var accounts = Set<Account>()
                                                                
            switch result {
            case .success(let accountNames):
                
                if let accountNames = accountNames as? Set<String>, accountNames.count > 0 {
                    for accountName in accountNames {
                        accounts.update(with: Account(chainId: chainProvider.chainId, name: accountName))
                    }
                }
                
            case .failure: break
            }
            
            if accounts.count > 0 {
                completion(.success(accounts))
            } else {
                completion(.failure(Proton.ProtonError(message: "No accounts found for \(publicKey)")))
            }
            
        }
        
    }
    
    /**
     :nodoc:
     Fetches the basic account info from chain
     - Parameter account: Account object
     - Parameter completion: Closure returning Result
     */
    private func fetchAccount(_ account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let chainProvider = account.chainProvider {
            
            WebOperations.shared.add(FetchAccountOperation(accountName: account.name.stringValue, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
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
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     :nodoc:
     Fetches the account info from chain table rows.
     This includes stuff like avatar base64 string, name, etc
     - Parameter forAccount: Account
     - Parameter completion: Closure returning Result
     */
    private func fetchAccountUserInfo(forAccount account: Account, completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        var account = account
        
        if let chainProvider = account.chainProvider {
            
            WebOperations.shared.add(FetchUserAccountInfoOperation(account: account, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                
                switch result {
                case .success(let updatedAccount):
                    
                    if var updatedAccount = updatedAccount as? Account {
                        updatedAccount.staking = account.staking
                        updatedAccount.stakingRefund = account.stakingRefund
                        account = updatedAccount
                    }
                    
                    completion(.success(account))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     :nodoc:
     Fetches all balances for the active account.
     - Parameter forAccount: Account
     - Parameter completion: Closure returning Result
     */
    private func fetchBalances(forAccount account: Account, completion: @escaping ((Result<Set<TokenBalance>, Error>) -> Void)) {
        
        var retval = Set<TokenBalance>()
        
        if let chainProvider = account.chainProvider {
            
            WebOperations.shared.add(FetchTokenBalancesOperation(account: account, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let tokenBalances):
                    
                    if let tokenBalances = tokenBalances as? Set<TokenBalance> {
                        
                        for tokenBalance in tokenBalances {
                            
                            if self.tokenContracts.first(where: { $0.id == tokenBalance.tokenContractId }) == nil {
                                
                                let unknownTokenContract = TokenContract(chainId: tokenBalance.chainId, contract: tokenBalance.contract, issuer: "",
                                                                         resourceToken: false, systemToken: false, name: tokenBalance.amount.symbol.name,
                                                                         desc: "", iconUrl: "", supply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         maxSupply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         symbol: tokenBalance.amount.symbol, url: "", isBlacklisted: true)
                                
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
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     :nodoc:
     Fetches all known accounts in which the active account has interated with via transfers, etc.
     - Parameter forAccount: Account
     - Parameter completion: Closure returning Result
     */
    private func fetchContacts(forAccount account: Account, completion: @escaping ((Result<Set<Contact>, Error>) -> Void)) {
        
        var retval = Set<Contact>()

        guard let chainProvider = account.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
            return
        }
        
        let tokenTransferActions = self.tokenTransferActions.flatMap { $0.value }

        let contactNames: [String] = tokenTransferActions.map { transferAction in
            return transferAction.other.stringValue
        }.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
        
        
        if contactNames.count == 0 {
            completion(.success(retval))
            return
        }
        
        var contactNamesProcessed = 0
        
        for contactName in contactNames {
            
            WebOperations.shared.add(FetchContactInfoOperation(account: account, contactName: contactName, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let contact):
                    if let contact = contact as? Contact {
                        retval.update(with: contact)
                    }
                case .failure: break
                }
                
                contactNamesProcessed += 1
                
                if contactNamesProcessed == contactNames.count {
                    completion(.success(retval))
                }
                
            }
            
        }

    }
    
    /**
     :nodoc:
     Fetches the accounts voting info
     This includes stuff like amount staked, claim amount , etc
     - Parameter forAccount: Account
     - Parameter completion: Closure returning Result
     */
    private func fetchAccountVotingAndStakingInfo(forAccount account: Account, completion: @escaping ((Result<StakingFetchResult, Error>) -> Void)) {

        if let chainProvider = account.chainProvider {
            
            var retval = StakingFetchResult()
            
            let operationCount = 2
            var operationsProcessed = 0
            
            WebOperations.shared.add(FetchUserVotersOperation(account: account, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                var votedForProducers = [Name]()
                
                switch result {
                case .success(let votersABI):
                    if let votersABI = votersABI as? VotersABI {
                        votedForProducers = votersABI.producers
                    }
                case .failure: break
                }
                
                WebOperations.shared.add(FetchUserVotersXPROperation(account: account, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                    
                    switch result {
                    case .success(let votersXPRABI):

                        if let votersXPRABI = votersXPRABI as? VotersXPRABI {
                            do {
                                let staked = Asset.init(units: Int64(votersXPRABI.staked), symbol: try Asset.Symbol(stringValue: "4,XPR"))
                                let claimAmount = Asset.init(units: Int64(votersXPRABI.claimamount), symbol: try Asset.Symbol(stringValue: "4,XPR"))
                                let staking = Staking(staked: staked, isQualified: votersXPRABI.isqualified, claimAmount: claimAmount, lastclaim: Date(timeIntervalSince1970: TimeInterval(votersXPRABI.lastclaim)), producerNames: votedForProducers)
                                retval.staking = staking
                            } catch {
                                print("error decoding votersxprabi")
                            }
                        }
                        
                    case .failure: break
                    }
                    
                    operationsProcessed += 1
                    
                    if operationCount == operationsProcessed {
                        completion(.success(retval))
                    }
                    
                }
                
                WebOperations.shared.add(FetchUserRefundsXPROperation(account: account, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                    
                    switch result {
                    case .success(let refundsXPRABI):

                        if let refundsXPRABI = refundsXPRABI as? RefundsXPRABI {
                            retval.stakingRefund = StakingRefund(quantity: refundsXPRABI.quantity, requestTime: refundsXPRABI.request_time.date)
                        }
                        
                    case .failure: break
                    }
                    
                    operationsProcessed += 1
                    
                    if operationCount == operationsProcessed {
                        completion(.success(retval))
                    }
                    
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     :nodoc:
     Fetches block producers for chain as well as each producers bp.json
     - Parameter completion: Closure returning Result
     */
    private func updateProducers(completion: @escaping ((Result<[Producer]?, Error>) -> Void)) {
        
        if let chainProvider = self.chainProvider {

            var producerSet = Set<Producer>()

            WebOperations.shared.add(FetchProducersOperation(chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let producers):
                    
                    if let producers = producers as? [ProducerABI] {
                        for producer in producers {
                            producerSet.insert(Producer(chainId: chainProvider.chainId, name: producer.owner.stringValue, isActive: producer.is_active == 0x01, totalVotes: producer.total_votes, url: producer.url))
                        }
                    }

                    if producerSet.count > 0 {
                        
                        self.producers = Array(producerSet)
                        
                        let operationCount = producerSet.count
                        var operationsProcessed = 0
                        
                        for producer in producerSet {
                            
                            WebOperations.shared.add(FetchProducerOrgOperation(producer: producer), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                                
                                switch result {
                                case .success(let updatedProducer):
                                    if let updatedProducer = updatedProducer as? Producer {
                                        if let idx = self.producers.firstIndex(of: updatedProducer) {
                                            self.producers[idx] = updatedProducer
                                        } else {
                                            self.producers.append(updatedProducer)
                                        }
                                    }
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                                
                                operationsProcessed += 1
                                
                                if operationCount == operationsProcessed {
                                    completion(.success(self.producers))
                                }

                            }
                            
                        }
                        
                    } else {
                        completion(.failure(Proton.ProtonError(message: "Error fetching producers")))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    // MARK: - ESR Functions 🚧 UNDER CONSTRUCTION. DO NOT USE YET
    
    public func decodeAndPrepareProtonSigningRequest(withURL url: URL, completion: @escaping ((Result<ProtonSigningRequest?, Error>) -> Void)) {

        do {
            
            let signingRequest = try SigningRequest(url.absoluteString)
            let chainId = signingRequest.chainId

            guard let account = self.account, account.chainId == String(chainId) else {
                completion(.failure(ProtonError.init(message: "No account or chainId valid for Proton Signing Request")))
                return
            }
            guard let chainProvider = account.chainProvider else {
                completion(.failure(ProtonError.init(message: "No valid chainProvider for Proton Signing Request")))
                return
            }
            
            var requestAccount: Account?
            var requestKey: PublicKey?
            
            if let psr_request_account = signingRequest.getInfo("psr_request_account", as: String.self) {
                requestAccount = Account(chainId: account.chainId, name: psr_request_account)
            }
            
            if let psr_request_key = signingRequest.getInfo("psr_request_key", as: String.self) {
                requestKey = PublicKey(stringLiteral: psr_request_key)
            }
            
            if requestKey == nil {
                completion(.failure(ProtonError.init(message: "Expected psr_request_key")))
                return
            }

            if var requestAccount = requestAccount {
                
                WebOperations.shared.add(FetchUserAccountInfoOperation(account: requestAccount, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                    
                    switch result {
                    case .success(let returnAccount):

                        if let returnAccount = returnAccount as? Account {
                            requestAccount = returnAccount
                        }
                        
                        if signingRequest.isIdentity {
                            
                            self.protonSigningRequest = ProtonSigningRequest(requestKey: requestKey!, signer: account, signingRequest: signingRequest, requestor: requestAccount, actions: [])
                            completion(.success(self.protonSigningRequest))
                            
                        } else {

                            self.prepareActionsforSigningRequest(signingRequest, requestKey: requestKey!, requestAccount: requestAccount) { result in
                                switch result {
                                case .success(let protonSigningRequest):
                                    self.protonSigningRequest = protonSigningRequest
                                    completion(.success(protonSigningRequest))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                            
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                
            } else {
                
                if signingRequest.isIdentity {
                    
                    self.protonSigningRequest = ProtonSigningRequest(requestKey: requestKey!, signer: account, signingRequest: signingRequest, actions: [])
                    completion(.success(self.protonSigningRequest))
                    
                } else {
                    
                    self.prepareActionsforSigningRequest(signingRequest, requestKey: requestKey!, requestAccount: requestAccount) { result in
                        switch result {
                        case .success(let protonSigningRequest):
                            self.protonSigningRequest = protonSigningRequest
                            completion(.success(protonSigningRequest))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                    
                }
                
            }

        } catch {
            completion(.failure(error))
        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    private func prepareActionsforSigningRequest(_ signingRequest: SigningRequest,
                                                 requestKey: PublicKey,
                                                 requestAccount: Account?,
                                                 completion: @escaping ((Result<ProtonSigningRequest?, Error>) -> Void)) {
        
        let chainId = signingRequest.chainId
        
        guard let account = self.account, account.chainId == String(chainId) else {
            completion(.failure(ProtonError.init(message: "No account or chainId valid for Proton Signing Request")))
            return
        }
        guard let chainProvider = account.chainProvider else {
            completion(.failure(ProtonError.init(message: "No valid chainProvider for Proton Signing Request")))
            return
        }

        let abiAccounts = signingRequest.actions.map { $0.account }.unique()
        var abiAccountsProcessed = 0
        var rawAbis: [String: API.V1.Chain.GetRawAbi.Response] = [:]

        if abiAccounts.count == 0 {
            completion(.failure(ProtonError.init(message: "No actions on request")));
            return
        }

        let abidecoder = ABIDecoder()
        
        for abiAccount in abiAccounts {
            
            WebOperations.shared.addSeq(FetchRawAbiOperation(account: abiAccount, chainProvider: chainProvider)) { result in
                
                abiAccountsProcessed += 1
                
                switch result {
                case .success(let rawAbi):

                    if let rawAbi = rawAbi as? API.V1.Chain.GetRawAbi.Response {
                        rawAbis[abiAccount.stringValue] = rawAbi
                    }
                    
                case .failure:
                    break
                }
                
                if abiAccountsProcessed == abiAccounts.count && abiAccounts.count == rawAbis.count {

                    let actions: [ProtonSigningRequestAction] = signingRequest.actions.compactMap {

                        let account = $0.account

                        if let abi = rawAbis[account.stringValue]?.decodedAbi { // TODO

                            if let transferActionABI = try? abidecoder.decode(TransferActionABI.self, from: $0.data) {

                                let symbol = transferActionABI.quantity.symbol

                                if let tokenContract = self.tokenContracts.first(where: { $0.chainId == String(chainId)
                                                                                            && $0.symbol == symbol && $0.contract == account }) {

                                    let quantityAsset = Asset(transferActionABI.quantity.value * tokenContract.getRate(forCurrencyCode: "USD"), tokenContract.symbol)

                                    let basicDisplay = ProtonSigningRequestAction.BasicDisplay(actiontype: .transfer, name: tokenContract.name,
                                                                              secondary: transferActionABI.quantity.stringValue,
                                                                              extra: "-\(quantityAsset.formattedAsCurrency())", tokenContract: tokenContract)

                                    return ProtonSigningRequestAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay, abi: abi)

                                }

                            } else {

                                let basicDisplay = ProtonSigningRequestAction.BasicDisplay(actiontype: .custom, name: $0.name.stringValue.uppercased(),
                                                                          secondary: nil, extra: nil, tokenContract: nil)

                                return ProtonSigningRequestAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay, abi: abi)

                            }

                        }

                        return nil

                    }

                    print("ESR ACTIONS => \(actions.count)")

                    if actions.count > 0 {
                        completion(.success(ProtonSigningRequest(requestKey: requestKey, signer: account, signingRequest: signingRequest, requestor: requestAccount, actions: actions)))
                    } else {
                        completion(.failure(ProtonError.init(message: "No actions to sign")))
                    }

                }

            }
            
        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    private func decryptProtonSigningRequest(withData: Data, completion: @escaping ((Result<URL?, Error>) -> Void)) {
        
        
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    public func declineProtonSigningRequest(completion: @escaping () -> ()) {
        self.protonSigningRequest = nil
        completion()
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    public func acceptProtonSigningRequest(privateKey: PrivateKey, completion: @escaping ((Result<URL?, Error>) -> Void)) {

        guard let protonSigningRequest = self.protonSigningRequest else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        if protonSigningRequest.signingRequest.isIdentity {

            self.handleIdentityProtonSigningRequest(withPrivateKey: privateKey) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.protonSigningRequest = nil
                        completion(.success(url))
                    }
                case .failure(let error):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.protonSigningRequest = nil
                        completion(.failure(error))
                    }
                }
            }

        } else if protonSigningRequest.signingRequest.actions.count > 0 {
            
            self.handleActionsProtonSigningRequest(withPrivateKey: privateKey) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.protonSigningRequest = nil
                        completion(.success(url))
                    }
                case .failure(let error):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.protonSigningRequest = nil
                        completion(.failure(error))
                    }
                }
            }

        } else { // TODO: Need to handle full transaction type ESR

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.protonSigningRequest = nil
                completion(.failure(ProtonError.init(message: "Unable to accept signing request")))
            }

        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    private func handleActionsProtonSigningRequest(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<URL?, Error>) -> Void)) {
        
        guard let protonSigningRequest = self.protonSigningRequest else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        let chainId = protonSigningRequest.signingRequest.chainId
        
        guard let chainProvider = protonSigningRequest.signer.chainProvider else {
            completion(.failure(ProtonError.init(message: "No chainprovider found")))
            return
        }
        
        guard let session = self.protonSigningRequestSessions.first(where: { $0.id == protonSigningRequest.requestKey.stringValue }) else {
            completion(.failure(ProtonError.init(message: "Unable to find session")))
            return
        }

        let actions = protonSigningRequest.actions

        var abis: [Name: ABI] = [:]

        for action in actions {
            if let abi = action.abi {
                abis[action.account] = abi
            }
        }

        if abis.count == 0 {
            completion(.failure(ProtonError.init(message: "No action abi's")))
            return
        }
        
        WebOperations.shared.add(FetchChainInfoOperation(chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueSeq) { result in
            
            switch result {
            case .success(let info):

                guard let info = info as? API.V1.Chain.GetInfo.Response else {
                    completion(.failure(ProtonError.init(message: "Unable to fetch chain info")))
                    return
                }
                
                let expiration = info.headBlockTime.addingTimeInterval(60)
                let header = TransactionHeader(expiration: TimePointSec(expiration),
                                               refBlockId: info.lastIrreversibleBlockId)
                
                do {
                    
                    guard let resolvedSigningRequest = try? protonSigningRequest.signingRequest.resolve(using: PermissionLevel(protonSigningRequest.signer.name, Name("active")),
                                                                                                        abis: abis, tapos: header) else
                    { completion(.failure(ProtonError.init(message: "Unable to resolve signing request"))); return }

                    self.protonSigningRequest?.resolvedSigningRequest = resolvedSigningRequest

                    let sig = try privateKey.sign(resolvedSigningRequest.transaction.digest(using: chainId))
                    let signedTransaction = SignedTransaction(resolvedSigningRequest.transaction, signatures: [sig])
                    
                    if protonSigningRequest.signingRequest.broadcast {
                        
                        WebOperations.shared.add(PushTransactionOperation(chainProvider: chainProvider, signedTransaction: signedTransaction),
                                                 toCustomQueueNamed: Proton.operationQueueSeq) { result in

                            switch result {
                            case .success(let res):

                                guard let res = res as? API.V1.Chain.PushTransaction.Response, let blockNum = res.processed["blockNum"] as? Int else {
                                    completion(.failure(ProtonError.init(message: "Unable to res or block num")))
                                    return
                                }
                                
                                guard let callback = resolvedSigningRequest.getCallback(using: [sig], blockNum: UInt32(blockNum)) else {
                                    completion(.failure(ProtonError.init(message: "Unable to get callback")))
                                    return
                                }

                                self.updateAccount { _ in }

                                if callback.background {
                                    
                                    WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonSigningRequest: protonSigningRequest, sig: sig, session: session, blockNum: UInt32(blockNum)), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                                        completion(.success(nil))
                                    }

                                } else {
                                    
                                    var newPath = callback.url
                                    
                                    guard let publicReceiveKey = try? session.getReceiveKey()?.getPublic().stringValue else {
                                        completion(.failure(ProtonError.init(message: "Unable to get psr_receive_key")))
                                        return
                                    }

                                    newPath = newPath.replacingOccurrences(of: "{{psr_request_key}}", with: publicReceiveKey)
                                    newPath = newPath.replacingOccurrences(of: "{{psr_receive_key}}", with: session.id)
                                    
                                    completion(.success(URL(string: newPath)))

                                }

                            case .failure(let error):
                                completion(.failure(error))
                            }

                        }
                        
                    } else {
                        
                        guard let callback = resolvedSigningRequest.getCallback(using: [sig], blockNum: nil) else { // CHECK: Might need blocknum here....
                            completion(.failure(ProtonError.init(message: "Unable to get callback")))
                            return
                        }
                        
                        if callback.background {
                            
                            WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonSigningRequest: protonSigningRequest, sig: sig, session: session, blockNum: nil), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                                completion(.success(nil))
                            }
                            
                        } else {
                            
                            var newPath = callback.url
                            
                            guard let publicReceiveKey = try? session.getReceiveKey()?.getPublic().stringValue else {
                                completion(.failure(ProtonError.init(message: "Unable to get psr_receive_key")))
                                return
                            }

                            newPath = newPath.replacingOccurrences(of: "{{psr_request_key}}", with: publicReceiveKey)
                            newPath = newPath.replacingOccurrences(of: "{{psr_receive_key}}", with: session.id)
                            
                            completion(.success(URL(string: newPath)))
                        }
                        
                    }
                    
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    private func handleIdentityProtonSigningRequest(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<URL?, Error>) -> Void)) {

        guard let protonSigningRequest = self.protonSigningRequest else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        let chainId = protonSigningRequest.signingRequest.chainId

        do {

            guard let resolvedSigningRequest = try? protonSigningRequest.signingRequest.resolve(using: PermissionLevel(protonSigningRequest.signer.name, Name("active"))) else {             completion(.failure(ProtonError.init(message: "Unable to resolve signing request")))
                return
            }

            self.protonSigningRequest?.resolvedSigningRequest = resolvedSigningRequest

            let sig = try privateKey.sign(resolvedSigningRequest.transaction.digest(using: chainId))
            guard let callback = resolvedSigningRequest.getCallback(using: [sig], blockNum: nil) else {
                completion(.failure(ProtonError.init(message: "Unable to resolve callback")))
                return
            }

            print(callback.url)
            print(sig)
            
            guard let sessionKey = generatePrivateKey() else {
                completion(.failure(ProtonError.init(message: "Unable to resolve callback")))
                return
            }
            
            guard let sessionChannel = URL(string: "https://cb.anchor.link/\(UUID())") else {
                completion(.failure(ProtonError.init(message: "Unable to generate session channel")))
                return
            }
            
            let session = ProtonSigningRequestSession(id: protonSigningRequest.requestKey.stringValue,
                                                      signer: protonSigningRequest.signer.name,
                                                      callbackUrlString: callback.url,
                                                      receiveKeyString: sessionKey.stringValue,
                                                      receiveChannel: sessionChannel,
                                                      requestor: protonSigningRequest.requestor)

            if callback.background {

                WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonSigningRequest: protonSigningRequest, sig: sig, session: session, blockNum: nil), toCustomQueueNamed: Proton.operationQueueSeq) { result in

                    switch result {
                    case .success:

                        if let idx = self.protonSigningRequestSessions.firstIndex(of: session) {
                            self.protonSigningRequestSessions[idx] = session
                        } else {
                            self.protonSigningRequestSessions.append(session)
                        }

                        completion(.success(nil))

                    case .failure(let error):

                        completion(.failure(error))

                    }

                }

            } else {

                var newPath = callback.url
                
                guard let publicReceiveKey = try session.getReceiveKey()?.getPublic().stringValue else {
                    completion(.failure(ProtonError.init(message: "Unable to get psr_receive_key")))
                    return
                }

                newPath = newPath.replacingOccurrences(of: "{{psr_request_key}}", with: publicReceiveKey)
                newPath = newPath.replacingOccurrences(of: "{{psr_receive_key}}", with: session.id)

                if let idx = self.protonSigningRequestSessions.firstIndex(of: session) {
                    self.protonSigningRequestSessions[idx] = session
                } else {
                    self.protonSigningRequestSessions.append(session)
                }

                completion(.success(URL(string: newPath)))

            }

        } catch {
            completion(.failure(error))
        }

    }

}
