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
import Starscream

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
        
        /// The name of your app. This will be used in certain places like handling Signing requests
        public var appDisplayName: String
        
        /// Custom uri schemes that your app has registered
        public var signingRequestSchemes: [String]
        
        /**
         Use this function as your starting point to initialize the singleton class Proton
         - Parameter baseUrl: The base url used for api requests to proton sdk api's
         - Parameter appDisplayName: The name of your app. This will be used in certain places like handling Signing requests
         - Parameter signingRequestSchemes: An array of custom schemes that your app has registered for siging requests
         */
        public init(baseUrl: String = Environment.testnet.rawValue, appDisplayName: String = "", signingRequestSchemes: [String]) {
            self.baseUrl = baseUrl
            self.appDisplayName = appDisplayName
            self.signingRequestSchemes = signingRequestSchemes
        }
        
        /**
         Use this function as your starting point to initialize the singleton class Proton
         - Parameter environment: The environment used for api requests to proton sdk api's
         - Parameter appDisplayName: The name of your app. This will be used in certain places like handling Signing requests
         - Parameter signingRequestSchemes: An array of custom schemes that your app has registered for siging requests
         */
        public init(environment: Environment = Environment.testnet, appDisplayName: String = "", signingRequestSchemes: [String]) {
            self.baseUrl = environment.rawValue
            self.appDisplayName = appDisplayName
            self.signingRequestSchemes = signingRequestSchemes
        }
        
    }
    
    private static let disallowedActions: [Name] = [
        Name("updateauth"),
        Name("deleteauth"),
        Name("linkauth"),
        Name("unlinkauth"),
        Name("setabi"),
        Name("setcode")
    //    Name("newaccount")
    ]
    
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
    
    private struct LongStakingFetchResult {
        var longStakingStakes: [LongStakingStake]?
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
        
        self.enableProtonESRWebSocketConnections()
        
        print("⚛️ [ACTIVE ACCOUNT - \(self.account?.name.stringValue ?? "No active account")]")
        
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
    @Published public var chainProvider: ChainProvider? = nil

    /**
     Live updated array of tokenContracts
     */
    @Published public var tokenContracts: [TokenContract] = []
    
    /**
     Live updated array of tokenBalances.
     */
    @Published public var tokenBalances: [TokenBalance] = []
    
    /**
     Live updated array of tokenTransferActions.
     */
    @Published public var tokenTransferActions: [String: [TokenTransferAction]] = [:]
    
    /**
     Live updated array of contacts.
     */
    @Published public var contacts: [Contact] = []
    
    /**
     Live updated array of producers.
     */
    @Published public var producers: [Producer] = []
    
    /**
     Live updated array of producers.
    */
    @Published public var swapPools: [SwapPool] = []
    
    /**
     Live updated array of protonESRSessions.
     */
    @Published public var protonESRSessions: [ProtonESRSession] = []
    
    /**
     Live updated protonESR.
     */
    @Published public var protonESR: ProtonESR? = nil {
        willSet {
            if newValue == nil {
                self.protonESRAvailable = false
            }
            self.objectWillChange.send()
        }
        didSet {
            if self.protonESR != nil {
                self.protonESRAvailable = true
            }
        }
    }
    
    /**
     Live updated protonESR.
     */
    @Published public var protonESRAvailable: Bool = false
    
    /**
     Live updated account.
     */
    @Published public var account: Account? = nil
    
    /**
     Live updated GlobalsXPR.
     */
    @Published public var globalsXPR: GlobalsXPR? = nil
    /**
     Live updated Global4.
     */
    @Published public var global4: Global4? = nil
    /**
     Live updated GlobalsD.
     */
    @Published public var globalsD: GlobalsD? = nil
    /**
     Live updated array of long staking plans.
    */
    @Published public var longStakingPlans: [LongStakingPlan] = []
    /**
     Live updated array of orcale data
    */
    @Published public var oracleData: [OracleData] = []
    /**
     Live updated array of kyc providers
    */
    @Published public var kycProviders: [KYCProvider] = []
    /**
     Live updated autoSelectChainEndpoints flag which indicates whether or not the sdk should auto choose the best endpoints.
     */
    @Published public var autoSelectChainEndpoints: Bool = true
    
    /**
     This lets you know if the data requriements have been fetched yet
     */
    @Published public var dataRequirementsReady: Bool = true
    
    private var protonESRSessionWebSocketWrappers: Set<ProtonESRSessionWebSocketWrapper> = []
    
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
        self.protonESRSessions = self.storage.getDefaultsItem([ProtonESRSession].self, forKey: "protonESRSessions") ?? []
        self.contacts = self.storage.getDefaultsItem([Contact].self, forKey: "contacts") ?? []
        self.producers = self.storage.getDefaultsItem([Producer].self, forKey: "contacts") ?? []
        self.swapPools = self.storage.getDefaultsItem([SwapPool].self, forKey: "swapPools") ?? []
        self.globalsXPR = self.storage.getDefaultsItem(GlobalsXPR.self, forKey: "globalsXPR") ?? nil
        self.global4 = self.storage.getDefaultsItem(Global4.self, forKey: "global4") ?? nil
        self.globalsD = self.storage.getDefaultsItem(GlobalsD.self, forKey: "globalsD") ?? nil
        self.longStakingPlans = self.storage.getDefaultsItem([LongStakingPlan].self, forKey: "longStakingPlans") ?? []
        self.oracleData = self.storage.getDefaultsItem([OracleData].self, forKey: "oracleData") ?? []
        self.kycProviders = self.storage.getDefaultsItem([KYCProvider].self, forKey: "kycProviders") ?? []
        self.autoSelectChainEndpoints = self.storage.getDefaultsItem(Bool.self, forKey: "autoSelectChainEndpoints") ?? true
        
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
        self.storage.setDefaultsItem(self.protonESRSessions, forKey: "protonESRSessions")
        self.storage.setDefaultsItem(self.contacts, forKey: "contacts")
        self.storage.setDefaultsItem(self.producers, forKey: "producers")
        self.storage.setDefaultsItem(self.swapPools, forKey: "swapPools")
        self.storage.setDefaultsItem(self.globalsXPR, forKey: "globalsXPR")
        self.storage.setDefaultsItem(self.global4, forKey: "global4")
        self.storage.setDefaultsItem(self.globalsD, forKey: "globalsD")
        self.storage.setDefaultsItem(self.longStakingPlans, forKey: "longStakingPlans")
        self.storage.setDefaultsItem(self.oracleData, forKey: "oracleData")
        self.storage.setDefaultsItem(self.kycProviders, forKey: "kycProviders")
        self.storage.setDefaultsItem(self.autoSelectChainEndpoints, forKey: "autoSelectChainEndpoints")
        
    }
    
    /**
     Connects/Reconnects websocket connections needed for ESR requests
     */
    public func enableProtonESRWebSocketConnections() {
        
        for protonESRSession in self.protonESRSessions {
            
            if let _ = self.protonESRSessionWebSocketWrappers.firstIndex(where: { $0.id == protonESRSession.id }) {
                continue
            }
            
            var request = URLRequest(url: protonESRSession.receiveChannel)
            request.timeoutInterval = 5
            
            let socket = WebSocket(request: request)
            socket.onData = { [weak self] data in
                
                if let url = URL(string: String(decoding: data, as: UTF8.self)) {
                    self?.decodeAndPrepareProtonSigningRequest(withURL: url,
                                                               sessionId: protonESRSession.id, completion: { result in })
                } else {

                    do {
                        let sealedMessage = try ABIDecoder().decode(SealedMessage.self, from: data)
                        
                        self?.decryptProtonSigningRequest(withSealedMessage: sealedMessage, andSession: protonESRSession, completion: { result in
                            switch result {
                            case .success(let url):
                                if let url = url {
                                    self?.decodeAndPrepareProtonSigningRequest(withURL: url,
                                                                               sessionId: protonESRSession.id, completion: { result in })
                                }
                            case .failure(let error):
                                print(error)
                            }
                        })
                    } catch {
                        print(error)
                    }
                    
                }
                
            }
            socket.onConnect = {
                print("⚛️ [PSR SOCKET SESSION CONNECTED - \(socket.currentURL)]")
            }
            socket.onDisconnect = { error in
                if let error = error {
                    print("⚛️ [PSR SOCKET SESSION DISSCONNECTED - \(socket.currentURL), for reason: \(error)]")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        socket.connect()
                    }
                }
            }
            
            socket.connect()
            
            let protonESRSessionWrapper = ProtonESRSessionWebSocketWrapper(id: protonESRSession.id, socket: socket)
            self.protonESRSessionWebSocketWrappers.insert(protonESRSessionWrapper)

        }
        
    }
    
    /**
     Use this to force storing the key into the keychain.
     - Parameter privateKey: PrivateKey
     - Parameter chainId: chainId for the account
     - Parameter completion: Closure returning Result
     */
    public func store(privateKey: PrivateKey, synchronizable: Bool = false,
                      completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        do {
            
            let publicKey = try privateKey.getPublic()
            
            self.storage.setKeychainItem(privateKey.stringValue, forKey: publicKey.stringValue,
                                         synchronizable: synchronizable) { result in
                
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
    public func setAccount(withName accountName: String, chainId: String, synchronizable: Bool = false,
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
    public func setAccount(_ account: Account, withPrivateKeyString privateKey: String, synchronizable: Bool = false,
                           completion: @escaping ((Result<Account, Error>) -> Void)) {
        
        do {
            
            let pk = try PrivateKey(stringValue: privateKey)
            let publicKey = try pk.getPublic()
            
            if account.isKeyAssociated(publicKey: publicKey) {
                
                self.storage.setKeychainItem(privateKey, forKey: publicKey.stringValue, synchronizable: synchronizable) { result in
                    
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
     - Parameter removingPrivateKey: NOT WORKING YET
     */
    public func clearAccount(removingPrivateKey: Bool = false) {
        
        self.account = nil
        self.contacts.removeAll()
        self.tokenBalances.removeAll()
        self.tokenTransferActions.removeAll()

        DispatchQueue.global().async {
            _ = self.protonESRSessionWebSocketWrappers.map({ $0.socket.disconnect() })
        }

        self.protonESRSessions.removeAll()
        self.protonESR = nil
        
        self.storage.deleteDefaultsItem(forKey: "account")
        self.storage.deleteDefaultsItem(forKey: "tokenBalances")
        self.storage.deleteDefaultsItem(forKey: "tokenTransferActions")
        self.storage.deleteDefaultsItem(forKey: "protonESRSessions")
        self.storage.deleteDefaultsItem(forKey: "contacts")
        self.storage.deleteDefaultsItem(forKey: "protonESRSessions")
        
    }
    
    /**
     Fetchs all required data objects from external data sources. This should be done at startup
     - Parameter completion: Closure returning Result
     */
    public func updateDataRequirements(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        dataRequirementsReady = false
        
        WebOperations.shared.add(FetchChainProviderOperation(), toCustomQueueNamed: Proton.operationQueueSeq) { result in
            
            var chainProvider = self.chainProvider
            var error: Error?
            
            switch result {
            case .success(let returnChainProvider):
                
                if var returnChainProvider = returnChainProvider as? ChainProvider {

                    // remove any chain endpoints that arent in the return chain provider
                    // append any that arent in local chain provider
                    var chainUrls = chainProvider?.chainUrls.filter({ returnChainProvider.chainUrls.contains($0) })
                    let remainingChainUrls = returnChainProvider.chainUrls.filter({ chainUrls?.contains($0) == false })
                    chainUrls?.append(contentsOf: remainingChainUrls)
                    
                    // remove any history endpoints that arent in the return chain provider
                    // append any that arent in local chain provider
                    var hyperionHistoryUrls = chainProvider?.hyperionHistoryUrls.filter({ returnChainProvider.hyperionHistoryUrls.contains($0) })
                    let remaininghyperionHistoryUrls = returnChainProvider.hyperionHistoryUrls.filter({ hyperionHistoryUrls?.contains($0) == false })
                    hyperionHistoryUrls?.append(contentsOf: remaininghyperionHistoryUrls)
                    
                    returnChainProvider.chainUrls = chainUrls ?? returnChainProvider.chainUrls
                    returnChainProvider.hyperionHistoryUrls = hyperionHistoryUrls ?? returnChainProvider.hyperionHistoryUrls
                    
                    returnChainProvider.chainUrlResponses = chainProvider?.chainUrlResponses.filter({ returnChainProvider.chainUrls.contains($0.url) }) ?? []
                    returnChainProvider.hyperionHistoryUrlResponses = chainProvider?.hyperionHistoryUrlResponses.filter({ returnChainProvider.hyperionHistoryUrls.contains($0.url) }) ?? []
                    
                    chainProvider = returnChainProvider
                }
                
            case .failure(let err):
                error = err
            }
            
            if let chainProvider = chainProvider {
                
                self.chainProvider = chainProvider
                self.tokenContracts = chainProvider.tokenContracts.unique()
                
                self.optimizeChainProvider {
                    
                    WebOperations.shared.add(FetchTokenContractsOperation(chainProvider: chainProvider, tokenContracts: self.tokenContracts),
                                             toCustomQueueNamed: Proton.operationQueueSeq) { result in
                        
                        switch result {
                            
                        case .success(let tokenContracts):
                            
                            if let tokenContracts = tokenContracts as? [TokenContract] {
                                self.tokenContracts = tokenContracts
                            }
                            
                            if let account = self.account {

                                var updatedTokenContracts = [TokenContract]()
                                var operationCount = 0
                                
                                for tokenContract in self.tokenContracts {
                                    
                                    // Create tokenBalances for xtoken contracts even if the user doesnt have a balance.
                                    if tokenContract.contract == "xtokens" && !self.tokenBalances.contains(where: { $0.tokenContractId == tokenContract.id }) {
                                        if let tokenBalance = TokenBalance(account: account, contract: tokenContract.contract, amount: 0.0, precision: tokenContract.symbol.precision, symbol: tokenContract.symbol.name) {
                                            self.tokenBalances.append(tokenBalance)
                                        }
                                    }
                                    
                                    // Grab token stats
                                    WebOperations.shared.add(FetchTokenContractCurrencyStat(tokenContract: tokenContract, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                                        
                                        operationCount += 1
                                        
                                        switch result {
                                        case .success(let tc):
                                            if let tc = tc as? TokenContract {
                                                updatedTokenContracts.append(tc)
                                            }
                                        case .failure(let error): // Operation designed to not error. Will pass back tokencontract no matter what
                                            print(error.localizedDescription)
                                        }
                                        
                                        if operationCount == self.tokenContracts.count {
                                            self.tokenContracts = updatedTokenContracts
                                        }
                                        
                                    }
                                    
                                }
                                
                            }

                        case .failure: break
                        }
                        
                        self.updateGlobal4 { _ in } // make sequential?
                        self.updateGlobalsXPR { _ in } // make sequential?
                        self.updateLongStakingPlans { _ in } // make sequential?
                        self.updateOracleData { _ in }
                        self.updateKYCProviders { _ in }
                        self.updateExchangeRates { _ in }
                        self.updateProducers { _ in }
                        self.updateSwapPools { _ in }
                        
                        self.dataRequirementsReady = true
                        completion(.success(true))
                        
                    }
                    
                }

            } else {
                completion(.failure(error ?? ProtonError.init(message: "An error occured fetching config")))
            }
            
        }
        
    }
    
    /**
    Checks latency of all chainUrls & hyperionHistoryUrls to determing the best endpoint
     - Parameter completion: Closure returning Result
     */
    public func optimizeChainProvider(completion: @escaping (() -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            print("Missing ChainProvider")
            completion()
            return
        }
        
        var chainUrls = chainProvider.chainUrls.unique()
        var historyUrls = chainProvider.hyperionHistoryUrls.unique()
        
        var chainUrlResponses = [ChainURLRepsonseTime]()
        var hyperionHistoryUrlResponses = [ChainURLRepsonseTime]()
        
        var chainUrlOperationsCompleted = 0
        var hyperionHistoryUrlOperationsCompleted = 0
        
        for chainUrl in chainUrls {

            WebOperations.shared.add(CheckChainResponseTimeOperation(chainUrl: chainUrl, path: "/v1/chain/get_info"), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                switch result {
                case .success(let urlRepsonseTimeCheck):
                    if let urlRepsonseTimeCheck = urlRepsonseTimeCheck as? ChainURLRepsonseTime {
                        chainUrlResponses.append(urlRepsonseTimeCheck)
                    }
                case .failure: ()
                }
                chainUrlOperationsCompleted += 1
                if chainUrlOperationsCompleted == chainUrls.count && hyperionHistoryUrlOperationsCompleted == historyUrls.count {
                    completeAndReturn()
                }
            }
            
        }

        for historyUrl in historyUrls {

            WebOperations.shared.add(CheckHyperionHistoryResponseTimeOperation(historyUrl: historyUrl, path: "/v2/health"), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                switch result {
                case .success(let urlRepsonseTimeCheck):
                    if let urlRepsonseTimeCheck = urlRepsonseTimeCheck as? ChainURLRepsonseTime {
                        hyperionHistoryUrlResponses.append(urlRepsonseTimeCheck)
                    }
                case .failure: ()
                }
                hyperionHistoryUrlOperationsCompleted += 1
                if chainUrlOperationsCompleted == chainUrls.count && hyperionHistoryUrlOperationsCompleted == historyUrls.count {
                    completeAndReturn()
                }
            }
            
        }
        
        func completeAndReturn() {
            
            if autoSelectChainEndpoints {
                
                chainUrlResponses = chainUrlResponses.unique()
                chainUrlResponses.sort(by: { $0.adjustedResponseTime < $1.adjustedResponseTime })
                chainUrls = chainUrlResponses.map({ $0.url })
                
                hyperionHistoryUrlResponses = hyperionHistoryUrlResponses.unique()
                hyperionHistoryUrlResponses.sort(by: { $0.adjustedResponseTime < $1.adjustedResponseTime })
                historyUrls = hyperionHistoryUrlResponses.map({ $0.url })
                
                self.chainProvider?.chainUrls = chainUrls
                self.chainProvider?.hyperionHistoryUrls = historyUrls
                self.chainProvider?.chainUrlResponses = chainUrlResponses
                self.chainProvider?.hyperionHistoryUrlResponses = hyperionHistoryUrlResponses
                
                print("⚛️ [AUTO ENDPOINT SELECTION]")
                
            } else {
                
                self.chainProvider?.chainUrlResponses.removeAll()
                
                for chainUrl in chainProvider.chainUrls {
                    if let item = chainUrlResponses.first(where: { $0.url == chainUrl }) {
                        self.chainProvider?.chainUrlResponses.append(item)
                    }
                }
                
                self.chainProvider?.hyperionHistoryUrlResponses.removeAll()
                
                for hyperionHistoryUrl in chainProvider.hyperionHistoryUrls {
                    if let item = hyperionHistoryUrlResponses.first(where: { $0.url == hyperionHistoryUrl }) {
                        self.chainProvider?.hyperionHistoryUrlResponses.append(item)
                    }
                }
                
                print("⚛️ [CUSTOM ENDPOINT SELECTION]")
                
            }

            print("⚛️ [CHAIN ENDPOINT SELECTED - \(self.chainProvider?.chainUrlResponses.first?.url ?? "None..."), IN SYNC => \(self.chainProvider?.chainUrlResponses.first?.blockDiff ?? 0 < 350), TIME => \(self.chainProvider?.chainUrlResponses.first?.rawResponseTime.milliseconds ?? 0) ms]")
            print("⚛️ [HISTORY ENDPOINT SELECTED - \(self.chainProvider?.hyperionHistoryUrlResponses.first?.url ?? "None..."), IN SYNC => \(self.chainProvider?.hyperionHistoryUrlResponses.first?.blockDiff ?? 0 < 30), TIME => \(self.chainProvider?.hyperionHistoryUrlResponses.first?.rawResponseTime.milliseconds ?? 0) ms]")

            completion()
            
        }
        
    }
    
    /**
     Updates the LongStakingPlans array.
     - Parameter completion: Closure returning Result
     */
    public func updateLongStakingPlans(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchLongStakingPlansOperation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {
                
            case .success(let longStakingPlans):
                
                self.longStakingPlans = longStakingPlans as? [LongStakingPlan] ?? []
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
            completion(.success(true))

        }
        
    }
    
    /**
     Updates the updateOracleData array.
     - Parameter completion: Closure returning Result
     */
    public func updateOracleData(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchOracleDataOperation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {

            case .success(let oracleData):

                self.oracleData = oracleData as? [OracleData] ?? []

            case .failure(let error):
                print(error.localizedDescription)
            }

            completion(.success(true))

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
                
            case .success(let globalsXPR):
                
                self.globalsXPR = globalsXPR as? GlobalsXPR
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
            completion(.success(true))
            
        }
        
    }
    
    /**
     Updates the Global4 object.
     - Parameter completion: Closure returning Result
     */
    public func updateGlobal4(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchGlobal4Operation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {
                
            case .success(let global4):
                
                self.global4 = global4 as? Global4
                
            case .failure(let error):
                print(error.localizedDescription)
            }
            
            completion(.success(true))
            
        }
        
    }
    
    /**
     Updates the KYC Providers object.
     - Parameter completion: Closure returning Result
     */
    public func updateKYCProviders(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing ChainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchKYCProvidersOperation(chainProvider: chainProvider),
                                 toCustomQueueNamed: Proton.operationQueueMulti) { result in
            
            switch result {
                
            case .success(let kycProviders):
                
                self.kycProviders = kycProviders as? [KYCProvider] ?? []
                
            case .failure(let error):
                print(error.localizedDescription)
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
                
            case .success(let exchangeRates):
                
                if let exchangeRates = exchangeRates as? [ExchangeRate] {
                    
                    for exchangeRate in exchangeRates {
                        
                        let tokenContractId = "\(exchangeRate.contract):\(exchangeRate.symbol)"

                        if let idx = self.tokenContracts.firstIndex(where: { $0.id == tokenContractId }) {
                            self.tokenContracts[idx].rates = exchangeRate.rates
                            if let iid = self.tokenBalances.firstIndex(where: { $0.tokenContractId == tokenContractId }) {
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
        
        var tokenBalances = self.tokenBalances
        var tokenTransferActions = self.tokenTransferActions
        var contacts = self.contacts
        
        self.fetchAccount(account) { result in
            
            switch result {
            case .success(let returnAccount):
                
                account = returnAccount
                //self.account = account
                
                self.fetchAccountUserInfo(forAccount: account) { result in
                    
                    switch result {
                    case .success(let returnAccount):
                        
                        account = returnAccount
                        //self.account = account
                        
                        self.fetchAccountVotingAndShortStakingInfo(forAccount: account) { result in

                            switch result {
                            case .success(let stakingFetchResult):
                                
                                account.staking = stakingFetchResult.staking
                                account.stakingRefund = stakingFetchResult.stakingRefund
                                
                                //self.account = account
                                
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                            
                            self.fetchLongStakingInfo(forAccount: account) { result in
                                
                                switch result {
                                case .success(let longStakingFetchResult):
                                    
                                    account.longStakingStakes = longStakingFetchResult.longStakingStakes ?? []
                                    
                                    //self.account = account
                                    
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }

                                self.fetchBalances(forAccount: account) { result in
                                    
                                    switch result {
                                    case .success(let tb):
                                        
                                        for tokenBalance in tb {
                                            if let idx = tokenBalances.firstIndex(of: tokenBalance) {
                                                tokenBalances[idx] = tokenBalance
                                            } else {
                                                tokenBalances.append(tokenBalance)
                                            }
                                        }
                                        
                                        let tokenBalancesCount = tokenBalances.count
                                        var tokenBalancesProcessed = 0
                                        
                                        if tokenBalancesCount > 0 {
                                            
                                            for tokenBalance in tokenBalances {
                                                
                                                self.fetchTransferActions(forTokenBalance: tokenBalance) { result in
                                                    
                                                    tokenBalancesProcessed += 1
                                                    
                                                    switch result {
                                                    case .success(let transferActions):
                                                        
                                                        var innerTokenTransferActions = tokenTransferActions[tokenBalance.tokenContractId] ?? []

                                                        for transferAction in transferActions {
                                                        
                                                            // remove any actions that where adding using 0 as globalSequence. This
                                                            // happens when manually adding action after transfer, etc.
                                                            if let zeroIdx = innerTokenTransferActions.firstIndex(where: { $0.trxId == transferAction.trxId && $0.globalSequence == 0 }) {
                                                                innerTokenTransferActions.remove(at: zeroIdx)
                                                            }
                                                            
                                                            if let idx = innerTokenTransferActions.firstIndex(of: transferAction) {
                                                                innerTokenTransferActions[idx] = transferAction
                                                            } else {
                                                                innerTokenTransferActions.append(transferAction)
                                                            }
                                                            
                                                        }
                                                        
                                                        if innerTokenTransferActions.count > 0 {
                                                            innerTokenTransferActions.sort(by: {  $0.date > $1.date })
                                                            tokenTransferActions[tokenBalance.tokenContractId] = Array(innerTokenTransferActions.prefix(50))
                                                        }

                                                    case .failure: break
                                                    }
                                                    
                                                    if tokenBalancesProcessed == tokenBalancesCount {
                                                        
                                                        //CHECK
                                                        self.fetchContacts(forAccount: account) { result in
                                                            
                                                            switch result {
                                                            case .success(let c):
                                                                
                                                                for contact in c {
                                                                    if let idx = contacts.firstIndex(of: contact) {
                                                                        contacts[idx] = contact
                                                                    } else {
                                                                        contacts.append(contact)
                                                                    }
                                                                }
                                                                
                                                            case .failure: break
                                                            }
                                                            
                                                            self.account = account
                                                            self.tokenBalances = tokenBalances
                                                            self.tokenTransferActions = tokenTransferActions
                                                            self.contacts = contacts

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
    public func transfer(withPrivateKey privateKey: PrivateKey, to: Name, quantity: Double, tokenContract: TokenContract, memo: String = "", completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let tokenBalance = self.tokenBalances.first(where: { $0.tokenContractId == tokenContract.id }) else {
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
                    
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.updateAccount { _ in }
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
     Creates a transfer, signs and pushes that transfer to the chain
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter quantity: The amount to be transfered
     - Parameter planIndex: The plan index for the long stake
     - Parameter completion: Closure returning Result
     */
    public func longStake(withPrivateKey privateKey: PrivateKey, quantity: Double, planIndex: UInt64, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let systemTokenContract = self.tokenContracts.first(where: { $0.systemToken == true }) else {
            return
        }
        
        guard let tokenBalance = self.tokenBalances.first(where: { $0.tokenContractId == systemTokenContract.id }) else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance of XPR")))
            return
        }
        
        if quantity > tokenBalance.amount.value {
            completion(.failure(Proton.ProtonError(message: "Account balance insufficient")))
            return
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let transfer = TransferActionABI(from: account.name, to: Name("longstaking"), quantity: Asset(quantity, systemTokenContract.symbol), memo: "\(planIndex)")
                
                guard let action = try? Action(account: systemTokenContract.contract, name: "transfer", authorization: [PermissionLevel(account.name, "active")], value: transfer) else {
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
        
        guard let tokenBalance = account.systemTokenBalance else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        guard let tokenContract = tokenBalance.tokenContract else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        if quantity == Double.zero {
            completion(.failure(Proton.ProtonError(message: "Cannot stake zero value")))
            return
        }
        
        let availableBalance = account.availableSystemBalance().value
        
        if availableBalance < quantity {
            completion(.failure(Proton.ProtonError(message: "Not enough available balance to stake \(quantity)")))
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
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.updateAccount { _ in }
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
    public func claimRewards(withPrivateKey privateKey: PrivateKey, restake: Bool, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let staking = self.account?.staking, staking.isQualified else {
            completion(.failure(Proton.ProtonError(message: "Account has no rewards to claim")))
            return
        }
        
        if staking.claimAmount.value == .zero {
            completion(.failure(Proton.ProtonError(message: "Account has no rewards to claim")))
            return
        }

        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                var abiData: Data?
                
                if restake {
                    abiData = try ABIEncoder().encode(VoterClaimstABI(owner: account.name))
                } else {
                    abiData = try ABIEncoder().encode(VoterClaimABI(owner: account.name))
                }
                
                guard let data = abiData else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                let action = Action(account: Name("eosio"), name: restake ? "voterclaimst" : "voterclaim", authorization: [PermissionLevel(account.name, "active")], data: data)
                
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
     Claims long stake by stake index
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter stakeIndex: UInt64
     - Parameter completion: Closure returning Result
     */
    public func claimLongStake(withPrivateKey privateKey: PrivateKey, stakeIndex: UInt64, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let stake = self.account?.longStakingStakes?.first(where: { $0.index == stakeIndex }) else {
            completion(.failure(Proton.ProtonError(message: "Unable to find stake by index")))
            return
        }
        
        if !stake.canClaim() {
            completion(.failure(Proton.ProtonError(message: "Stake not ready to claim")))
            return
        }

        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let abiData: Data = try ABIEncoder().encode(LongStakeClaimABI(account: account.name, stake_index: stakeIndex))
                let action = Action(account: Name("longstaking"), name: "claimstake", authorization: [PermissionLevel(account.name, "active")], data: abiData)
                
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
     Refunds unstaking amount if the deferred action did not complete
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func refund(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<Any?, Error>) -> Void)) {
        
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
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
     Stakes and Votes for block producers. This should only be used when staking value > 0
     - Parameter forProducers: Array of producer Names
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter quantity: Amount to added or removed from stake. Postive for adding stake, Negative for removing stake. Cannot be zero
     - Parameter completion: Closure returning Result
     */
    public func stakeAndvote(forProducers producerNames: [Name], withPrivateKey privateKey: PrivateKey, quantity: Double, completion: @escaping ((Result<Any?, Error>) -> Void)) {

        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }
        
        guard let tokenBalance = account.systemTokenBalance else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        guard let tokenContract = tokenBalance.tokenContract else {
            completion(.failure(Proton.ProtonError(message: "Account has no token balance for XPR")))
            return
        }
        
        if quantity == Double.zero {
            completion(.failure(Proton.ProtonError(message: "Cannot stake zero value")))
            return
        }
        
        let availableBalance = account.availableSystemBalance().value
        
        if availableBalance < quantity {
            completion(.failure(Proton.ProtonError(message: "Not enough available balance to stake \(quantity)")))
            return
        }
        
        func getStakeActionData(account: Account, quantity: Double, symbol: Asset.Symbol) -> ABICodable {
            if quantity > 0 {
                return StakeXPRABI(from: account.name, stake_xpr_quantity: Asset(quantity, tokenContract.symbol))
            } else {
                return UnStakeXPRABI(from: account.name, unstake_xpr_quantity: Asset(quantity * -1.0, tokenContract.symbol))
            }
        }
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let producerNames = producerNames.sorted { $0.stringValue < $1.stringValue }
                
                let vote = VoteProducersABI(voter: account.name, producers: producerNames)
                
                guard let voteAction = try? Action(account: Name("eosio"), name: "voteproducer", authorization: [PermissionLevel(account.name, "active")], value: vote) else {
                    completion(.failure(Proton.ProtonError(message: "Unable to create action")))
                    return
                }
                
                let data = try ABIEncoder.encode(getStakeActionData(account: account, quantity: quantity, symbol: tokenContract.symbol)) as Data
                let stakeAction = Action(account: Name("eosio"), name: quantity > 0 ? "stakexpr" : "unstakexpr", authorization: [PermissionLevel(account.name, "active")], data: data)
                
                self.signAndPushTransaction(withActions: [stakeAction, voteAction], andPrivateKey: privateKey) { result in
                    
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
     Swaps tokens
     - Parameter withPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter quantity: Amount
     - Parameter completion: Closure returning Result
     */
    public func swap(withPrivateKey privateKey: PrivateKey, swapPool: SwapPool,
                     fromTokenContract: TokenContract, toTokenContract: TokenContract,
                     quantity: Double, completion: @escaping ((Result<Any?, Error>) -> Void)) {
    
        guard let account = self.account else {
            completion(.failure(Proton.ProtonError(message: "No active account")))
            return
        }

        let min = swapPool.minimumReceived(toAmount: swapPool.toAmount(fromAmount: quantity, fromSymbol: fromTokenContract.symbol), toSymbol: toTokenContract.symbol)
        let minAsset = Asset(min, toTokenContract.symbol)
        let memo = "\(swapPool.liquidityTokenSymbol.name),\(minAsset.units)"
        
        do {
            
            let publicKey = try privateKey.getPublic()
            if account.isKeyAssociated(withPermissionName: "active", forPublicKey: publicKey) {

                let transfer = TransferActionABI(from: account.name, to: Name("proton.swaps"), quantity: Asset(quantity, fromTokenContract.symbol), memo: memo)
                
                guard let action = try? Action(account: fromTokenContract.contract, name: "transfer", authorization: [PermissionLevel(account.name, "active")], value: transfer) else {
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
    Signs transaction without broadcasting
     - Parameter withActions: [Actions]
     - Parameter andPrivateKey: PrivateKey, FYI, this is used to sign on the device. Private key is never sent.
     - Parameter completion: Closure returning Result
     */
    public func signTransaction(withActions actions: [Action], andPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<SignedTransaction, Error>) -> Void)) {
        
        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Unable to find chain provider")))
            return
        }
        
        WebOperations.shared.add(SignTransactionOperation(chainProvider: chainProvider, actions: actions, privateKey: privateKey), toCustomQueueNamed: Proton.operationQueueSeq) { result in
            
            switch result {
            case .success(let signedTransaction):
                
                if let signedTransaction = signedTransaction as? SignedTransaction {
                    completion(.success(signedTransaction))
                } else {
                    completion(.failure(Proton.ProtonError(message: "Unable to sign transaction")))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
            
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
        
        signTransaction(withActions: actions, andPrivateKey: privateKey) { result in
            
            switch result {
            case .success(let signedTransaction):
                
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
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    /**
     Fetches a single contact's info without saving to contacts
     - Parameter withAccountName: String
     - Parameter completion: Closure returning Result
     */
    public func fetchContact(withAccountName accountName: String, completion: @escaping ((Result<Contact?, Error>) -> Void)) {

        guard let chainProvider = self.chainProvider else {
            completion(.failure(Proton.ProtonError(message: "Missing chainProvider")))
            return
        }
        
        WebOperations.shared.add(FetchContactInfoOperation(contact: Contact(chainId: chainProvider.chainId, name: accountName), chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
            switch result {
            case .success(let contact):
                completion(.success(contact as? Contact))
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
            self.protonESRSessions.removeAll()
            self.protonESR = nil
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
                                                                         symbol: tokenBalance.amount.symbol, url: "", isBlacklisted: false)
                                
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
        
        let tempContacts: [Contact] = tokenTransferActions.map { transferAction in
            return Contact(chainId: transferAction.chainId, name: transferAction.other.stringValue)
        }
        .reduce([]) {
            $0.contains($1) ? $0 : $0 + [$1]
        }.map { contact in
            var contact = contact
            if let lastTransferAction = tokenTransferActions.filter({ $0.other == contact.name }).max(by: {
                $0.date < $1.date
            }) {
                contact.lastTransferDate = lastTransferAction.date
            }
            return contact
        }
        
        if tempContacts.count == 0 {
            completion(.success(retval))
            return
        }
        
        var contactsProcessed = 0
        
        for contact in tempContacts {
            
            WebOperations.shared.add(FetchContactInfoOperation(contact: contact, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let contact):
                    if let contact = contact as? Contact {
                        retval.update(with: contact)
                    }
                case .failure: break
                }
                
                contactsProcessed += 1
                
                if contactsProcessed == tempContacts.count {
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
    private func fetchLongStakingInfo(forAccount account: Account, completion: @escaping ((Result<LongStakingFetchResult, Error>) -> Void)) {
        
        let operationCount = 1
        var operationsProcessed = 0
        
        var retval = LongStakingFetchResult()

        if let chainProvider = account.chainProvider {
            
            WebOperations.shared.add(FetchLongStakingStakesOperation(chainProvider: chainProvider, account: account), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let longStakingStakes):

                    retval.longStakingStakes = longStakingStakes as? [LongStakingStake]
                    
                case .failure: break
                }
                
                operationsProcessed += 1
                
                if operationCount == operationsProcessed {
                    completion(.success(retval))
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     :nodoc:
     Fetches the accounts voting info
     This includes stuff like amount staked, claim amount , etc
     - Parameter forAccount: Account
     - Parameter completion: Closure returning Result
     */
    private func fetchAccountVotingAndShortStakingInfo(forAccount account: Account, completion: @escaping ((Result<StakingFetchResult, Error>) -> Void)) {

        if let chainProvider = account.chainProvider {
            
            var retval = StakingFetchResult()
            
            var operationCount = 3
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
                    case .success(let refundsXPR):

                        retval.stakingRefund = refundsXPR as? StakingRefund
                        
                    case .failure: break
                    }
                    
                    operationsProcessed += 1
                    
                    if operationCount == operationsProcessed {
                        completion(.success(retval))
                    }
                    
                }
                
                WebOperations.shared.add(FetchGlobalsDOperation(chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                    
                    switch result {
                    case .success(let globalsD):
                        self.globalsD = globalsD as? GlobalsD  //CHECK
                    case .failure: break
                    }
                    
                    operationsProcessed += 1
                    
                    if operationCount == operationsProcessed {
                        completion(.success(retval))
                    }
                }
                
                
                // update currency stats for XPR token. Supply, etc //CHECK
                if let xprToken = self.tokenContracts.first(where: { $0.systemToken == true }) {
                    
                    operationCount += 1
                    
                    WebOperations.shared.add(FetchTokenContractCurrencyStat(tokenContract: xprToken, chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                        
                        switch result {
                        case .success(let tokenContract):
                            
                            if let tokenContract = tokenContract as? TokenContract {
                                if let index = self.tokenContracts.firstIndex(of: tokenContract) {
                                    self.tokenContracts[index] = tokenContract
                                }
                            }
                            
                        case .failure: break
                        }
                        
                        operationsProcessed += 1
                        
                        if operationCount == operationsProcessed {
                            completion(.success(retval))
                        }
                    }
                    
                }

            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Account missing chainProvider")))
        }
        
    }
    
    /**
     Fetches and updates the swap pools
     - Parameter completion: Closure returning Result
    */
    public func updateSwapPools(completion: @escaping ((Result<[SwapPool]?, Error>) -> Void)) {

        if let chainProvider = self.chainProvider {
            
            WebOperations.shared.add(FetchSwapPoolsOperation(chainProvider: chainProvider), toCustomQueueNamed: Proton.operationQueueMulti) { result in
                
                switch result {
                case .success(let swapPools):
                    
                    self.swapPools = swapPools as? [SwapPool] ?? []
                    completion(.success(self.swapPools))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
            
        } else {
            completion(.failure(Proton.ProtonError(message: "Missing chainProvider")))
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
                                case .failure: ()
                                    // DEBUG
                                    //print(error.localizedDescription)
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
    
    public func isSigningRequest(withUrl url: URL) -> Bool {
        
        var sigingRequestString = url.absoluteString
        
        guard var prefix = sigingRequestString.popESRPrefix() else {
            return false
        }
        
        prefix = prefix.replacingOccurrences(of: "//", with: "")
        
        if Proton.self.config?.signingRequestSchemes.contains(prefix) == false {
            return false
        }
        
        do {
            let _ = try SigningRequest(sigingRequestString)
            return true
        } catch {
            return false
        }
    }

    public func decodeAndPrepareProtonSigningRequest(withURL url: URL, sessionId: String?, completion: @escaping ((Result<Bool, Error>) -> Void)) {

        do {
            
            var sigingRequestString = url.absoluteString
            
            guard var prefix = sigingRequestString.popESRPrefix() else {
                completion(.failure(ProtonError.init(message: "Unable to determine ESR prefix")))
                return
            }
            
            prefix = prefix.replacingOccurrences(of: "//", with: "")
            
            if Proton.self.config?.signingRequestSchemes.contains(prefix) == false {
                completion(.failure(ProtonError.init(message: "ESR prefix not registered in proton config")))
                return
            }
            
            let signingRequest = try SigningRequest(sigingRequestString)
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
            
            if let sessionId = sessionId, let session = self.protonESRSessions.first(where: { $0.id == sessionId }) {
                requestAccount = session.requestor
                requestKey = session.getRequestKey()
            } else if let psr_request_account = signingRequest.getInfo("req_account", as: String.self) {
                requestAccount = Account(chainId: account.chainId, name: psr_request_account)
            }
            
            if signingRequest.isIdentity {
                
                struct AnchorLinkCreateInfo: ABIDecodable {
                    let session_name: Name
                    let request_key: PublicKey
                }
                
                if let link = signingRequest.getInfo("link", as: AnchorLinkCreateInfo.self) {
                    requestKey = link.request_key
                }

            }
            
            var returnPath: URL?
            
            // used when doing same device
            if let return_path = signingRequest.getInfo("return_path", as: String.self) {
                returnPath = URL(string: return_path)
            }
            
            if requestKey == nil {
                completion(.failure(ProtonError.init(message: "Expected request link object with request key")))
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
                            
                            self.protonESR = ProtonESR(requestKey: requestKey!, signer: account, signingRequest: signingRequest, initialPrefix: prefix, requestor: requestAccount, returnPath: returnPath, actions: [])
                            completion(.success(true))
                            
                        } else {

                            self.prepareActionsforSigningRequest(signingRequest, requestKey: requestKey!, initialPrefix: prefix, requestAccount: requestAccount, returnPath: returnPath) { result in
                                switch result {
                                case .success(let protonESR):
                                    self.protonESR = protonESR
                                    completion(.success(true))
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
                    
                    self.protonESR = ProtonESR(requestKey: requestKey!, signer: account, signingRequest: signingRequest, initialPrefix: prefix, returnPath: returnPath, actions: [])
                    completion(.success(true))
                    
                } else {
                    
                    self.prepareActionsforSigningRequest(signingRequest, requestKey: requestKey!, initialPrefix: prefix, requestAccount: requestAccount, returnPath: returnPath) { result in
                        switch result {
                        case .success(let protonESR):
                            self.protonESR = protonESR
                            completion(.success(true))
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
                                                 initialPrefix: String,
                                                 requestAccount: Account?,
                                                 returnPath: URL?,
                                                 completion: @escaping ((Result<ProtonESR?, Error>) -> Void)) {
        
        let chainId = signingRequest.chainId
        
        guard let account = self.account, account.chainId == String(chainId) else {
            completion(.failure(ProtonError.init(message: "No account or chainId valid for Proton Signing Request")))
            return
        }
        guard let chainProvider = account.chainProvider else {
            completion(.failure(ProtonError.init(message: "No valid chainProvider for Proton Signing Request")))
            return
        }

        let abiAccounts = signingRequest.requiredAbis
        var abiAccountsProcessed = 0
        var rawAbis: [String: API.V1.Chain.GetRawAbi.Response] = [:]

        if abiAccounts.count == 0 {
            completion(.failure(ProtonError.init(message: "No actions on request")));
            return
        }

        //let abidecoder = ABIDecoder()
        
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

                    let actions: [ProtonESRAction] = signingRequest.actions.compactMap {
                        if let abi = rawAbis[$0.account.stringValue]?.decodedAbi { // TODO: Figure out a better way to determine transfer or not...
                            return ProtonESRAction(type: $0.name.stringValue == "transfer" ? .transfer : .custom, account: $0.account, name: $0.name, chainId: chainId, abi: abi, data: $0.data)
                        }
                        return nil
                    }

                    if actions.count > 0 {
                        
                        // check for unauthorized actions
                        for action in actions {
                            if Proton.disallowedActions.contains(action.name) {
                                completion(.failure(ProtonError.init(message: "\(action.name.stringValue) not allowed")))
                                return
                            }
                        }
                        
                        completion(.success(ProtonESR(requestKey: requestKey, signer: account, signingRequest: signingRequest, initialPrefix: initialPrefix, requestor: requestAccount, returnPath: returnPath, actions: actions)))
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
    private func decryptProtonSigningRequest(withSealedMessage sealedMessage: SealedMessage, andSession session: ProtonESRSession, completion: @escaping ((Result<URL?, Error>) -> Void)) {
        
        do {

            guard let key = try session.getReceiveKey()?.getSymmetricKey(sealedMessage.from, sealedMessage.nonce) else {
                completion(.failure(ProtonError.init(message: "Unable to get shared secret")))
                return
            }
            
            let esr = try aesCBCDecrypt(data: sealedMessage.ciphertext, key: key[0..<32], iv: key[32..<48])
            completion(.success(URL(string: (esr))))

        } catch {
            print(error)
            completion(.failure(error))
            return
        }
        
    }

    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    public func declineProtonSigningRequest(autoCompleteRequest: Bool = true, completion: @escaping ((Result<URL?, Error>) -> Void)) {
        
        guard let protonESR = self.protonESR else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }
        
        guard let unresolvedCallback = self.protonESR?.signingRequest.unresolvedCallback else {
            if autoCompleteRequest {
                self.protonESR = nil
            }
            completion(.failure(ProtonError.init(message: "No unresolved callback")))
            return
        }
        
        if unresolvedCallback.background {
            
            WebOperations.shared.add(PostBackgroundCancelProtonSigningRequestOperation(protonESR: protonESR), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                
                switch result {
                case .success:
                    
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.success(protonESR.returnPath))
                    } else {
                        completion(.success(protonESR.returnPath))
                    }
                    
                case .failure(let error):
                    
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.failure(error))
                    } else {
                        completion(.failure(error))
                    }
                    
                }

            }
            
        } else {
            
            if autoCompleteRequest {
                self.completeProtonSigningRequest()
                completion(.success(URL(string: unresolvedCallback.url)))
            } else {
                completion(.success(URL(string: unresolvedCallback.url)))
            }
            
        }
        
    }
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    public func completeProtonSigningRequest() {
        self.protonESR = nil
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    public func acceptProtonSigningRequest(privateKey: PrivateKey, autoCompleteRequest: Bool = true, completion: @escaping ((Result<URL?, Error>) -> Void)) {

        guard let protonESR = self.protonESR else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        if protonESR.signingRequest.isIdentity {

            self.handleIdentityProtonSigningRequest(withPrivateKey: privateKey) { result in
                switch result {
                case .success(let url):
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.success(url))
                    } else {
                        completion(.success(url))
                    }
                case .failure(let error):
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.failure(error))
                    } else {
                        completion(.failure(error))
                    }
                }
            }

        } else if protonESR.signingRequest.actions.count > 0 {
            
            self.handleActionsProtonSigningRequest(withPrivateKey: privateKey) { result in
                switch result {
                case .success(let url):
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.success(url))
                    } else {
                        completion(.success(url))
                    }
                case .failure(let error):
                    if autoCompleteRequest {
                        self.completeProtonSigningRequest()
                        completion(.failure(error))
                    } else {
                        completion(.failure(error))
                    }
                }
            }

        } else { // TODO: Need to handle full transaction type ESR

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.protonESR = nil
                completion(.failure(ProtonError.init(message: "Unable to accept signing request")))
            }

        }
        
    }
    
    /**
     🚧 UNDER CONSTRUCTION: WARNING, DO NOT USE YET
     */
    private func handleActionsProtonSigningRequest(withPrivateKey privateKey: PrivateKey, completion: @escaping ((Result<URL?, Error>) -> Void)) {
        
        guard var protonESR = self.protonESR else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        let chainId = protonESR.signingRequest.chainId
        
        guard let chainProvider = protonESR.signer.chainProvider else {
            completion(.failure(ProtonError.init(message: "No chainprovider found")))
            return
        }
        
        guard var session = self.protonESRSessions.first(where: { $0.id == protonESR.requestKey.stringValue }) else {
            completion(.failure(ProtonError.init(message: "Unable to find session")))
            return
        }

        let abis = protonESR.actions.reduce(into: [Name: ABI]()) { $0[$1.account] = $1.abi }

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
                    
                    guard let resolvedSigningRequest = try? protonESR.signingRequest.resolve(using: PermissionLevel(protonESR.signer.name, Name("active")),
                                                                                             abis: abis, tapos: protonESR.signingRequest.requiresTapos ? header : nil) else
                    { completion(.failure(ProtonError.init(message: "Unable to resolve signing request"))); return }

                    self.protonESR?.resolvedSigningRequest = resolvedSigningRequest
                    protonESR.resolvedSigningRequest = resolvedSigningRequest

                    let sig = try privateKey.sign(resolvedSigningRequest.transaction.digest(using: chainId))
                    let signedTransaction = SignedTransaction(resolvedSigningRequest.transaction, signatures: [sig])
                    
                    if protonESR.signingRequest.broadcast {
                        
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
                                
                                session.updatedAt = Date()
                                
                                if let idx = self.protonESRSessions.firstIndex(of: session) {
                                    self.protonESRSessions[idx] = session
                                    self.saveAll()
                                }

                                if callback.background {
                                    
                                    WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonESR: protonESR, sig: sig, session: session, blockNum: UInt32(blockNum)), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                                        completion(.success(protonESR.returnPath))
                                    }

                                } else {
                                    completion(.success(URL(string: callback.url)))
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
                        
                        session.updatedAt = Date()
                        
                        if let idx = self.protonESRSessions.firstIndex(of: session) {
                            self.protonESRSessions[idx] = session
                            self.saveAll()
                        }
                        
                        if callback.background {
                            
                            WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonESR: protonESR, sig: sig, session: session, blockNum: nil), toCustomQueueNamed: Proton.operationQueueSeq) { result in
                                
                                if protonESR.actions.first(where: { $0.name == "transfer" }) != nil {
                                    // TODO: This is arbitrary wait since we arent sure how long it will take for the originator to push the request
                                    // in the future we will just be listening on a hyperion websocket for this.
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        self.updateAccount { _ in }
                                    }
                                }
                                
                                completion(.success(protonESR.returnPath))
                            }
                            
                        } else {
                            
                            if protonESR.actions.first(where: { $0.name == "transfer" }) != nil {
                                // TODO: This is arbitrary wait since we arent sure how long it will take for the originator to push the request
                                // in the future we will just be listening on a hyperion websocket for this.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.updateAccount { _ in }
                                }
                            }

                            completion(.success(URL(string: callback.url)))
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

        guard var protonESR = self.protonESR else {
            completion(.failure(ProtonError.init(message: "No proton siging request found")))
            return
        }

        let chainId = protonESR.signingRequest.chainId

        do {

            guard let resolvedSigningRequest = try? protonESR.signingRequest.resolve(using: PermissionLevel(protonESR.signer.name, Name("active"))) else {             completion(.failure(ProtonError.init(message: "Unable to resolve signing request")))
                return
            }

            protonESR.resolvedSigningRequest = resolvedSigningRequest
            self.protonESR?.resolvedSigningRequest = resolvedSigningRequest

            let sig = try privateKey.sign(resolvedSigningRequest.transaction.digest(using: chainId))
            guard let callback = resolvedSigningRequest.getCallback(using: [sig], blockNum: nil) else {
                completion(.failure(ProtonError.init(message: "Unable to resolve callback")))
                return
            }
            
            guard let sessionKey = generatePrivateKey() else {
                completion(.failure(ProtonError.init(message: "Unable to resolve callback")))
                return
            }
            
            guard let sessionChannel = URL(string: "https://cb.anchor.link/\(UUID())") else {
                completion(.failure(ProtonError.init(message: "Unable to generate session channel")))
                return
            }
            
            let createdAt = Date()
            
            let session = ProtonESRSession(id: protonESR.requestKey.stringValue,
                                                      signer: protonESR.signer.name,
                                                      callbackUrlString: callback.url,
                                                      receiveKeyString: sessionKey.stringValue,
                                                      receiveChannel: sessionChannel,
                                                      createdAt: createdAt,
                                                      updatedAt: createdAt,
                                                      requestor: protonESR.requestor)

            if callback.background {

                WebOperations.shared.add(PostBackgroundProtonSigningRequestOperation(protonESR: protonESR, sig: sig, session: session, blockNum: nil), toCustomQueueNamed: Proton.operationQueueSeq) { result in

                    switch result {
                    case .success:

                        if let idx = self.protonESRSessions.firstIndex(of: session) {
                            self.protonESRSessions[idx] = session
                        } else {
                            self.protonESRSessions.append(session)
                        }
                        
                        self.enableProtonESRWebSocketConnections()
                        
                        self.saveAll()

                        completion(.success(protonESR.returnPath))

                    case .failure(let error):

                        completion(.failure(error))

                    }

                }

            } else {

                if let idx = self.protonESRSessions.firstIndex(of: session) {
                    self.protonESRSessions[idx] = session
                } else {
                    self.protonESRSessions.append(session)
                }
                
                self.saveAll()

                completion(.success(URL(string: callback.url)))

            }

        } catch {
            completion(.failure(error))
        }

    }
    
    enum AESError: Error {
        case KeyError((String, Int))
        case IVError((String, Int))
        case CryptorError((String, Int))
    }
    
    private func aesCBCDecrypt(data: Data, key: Data, iv: Data) throws -> String {
        
        var buffer = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        var bufferLen: Int = 0

        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            [UInt8](key), kCCKeySizeAES256,
            [UInt8](iv),
            [UInt8](data),
            data.count,
            &buffer,
            buffer.count,
            &bufferLen
        )

        guard status == kCCSuccess,
            let str = String(data: Data(bytes: buffer, count: bufferLen),
                             encoding: .utf8) else {
                                throw NSError(domain: "AES", code: -1, userInfo: nil)
        }

        return str
        
    }

}
