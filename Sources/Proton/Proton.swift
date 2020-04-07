//
//  Proton.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Combine
import EOSIO
import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public final class Proton: ObservableObject {
    
    public struct ESR: Equatable {
        public var requestor: Account
        public var signer: Account
        public var signingRequest: SigningRequest
        public var sid: String
        public var resolved: ResolvedSigningRequest?
        public var actions: [ESRAction]
        
        public var basicTransfer: Bool {
            if let action = self.actions.first, actions.count == 1 {
                return action.basicDisplay.actiontype == ESRAction.ActionType.transfer ? true : false
            }
            return false
        }
        
        public static var testObject: ESR {
            
            return ESR(requestor: Account(chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd", name: "requestor"),
                        signer: Account(chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd", name: "signer"),
                        signingRequest: try! SigningRequest("esr://gmMsfNe856ui0zUByZvxc446VS9bcP1_15mbjzi6Hq1-9fnyXWZGRgYEWPHWyIjJJqOkpKDYSl-_tFg3OTWvpCgxx1C3PDEnJ7VENyczL1s3JTU3Xy85J780Ja00L7kkMz-vWC8vtUQ_sbQkg5k9MTk5vzSvhK0ksTg7p5K5ODNFJS3ZJNki0dRE1yjVyFDXxMTIWDfROMVENyXJxMI00dAwOcU4lamo2I5ci4tSQVYDAA"),
                        sid: "123", resolved: nil, actions: [ESRAction(account: Name("eosio.token"), name: Name("transfer"),
                        chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd",
                        basicDisplay: ESRAction.BasicDisplay(actiontype: .transfer, name: "Proton", secondary: "1 XPT",
                        extra: "", tokenContract: TokenContract.testObject))])
            
        }
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
        return self.shared
    }
    
    public static let shared = Proton()
    
    var storage: Persistence!
    var publicKeys = [String]()
    
    /**
     Live updated set of chainProviders. Subscribe to this for your chainProviders
     */
    @Published public var chainProviders: [ChainProvider] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenContracts. Subscribe to this for your tokenContracts
     */
    @Published public var tokenContracts: [TokenContract] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of accounts. Subscribe to this for your accounts
     */
    @Published public var accounts: [Account] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenBalances. Subscribe to this for your tokenBalances
     */
    @Published public var tokenBalances: [TokenBalance] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenTransferActions. Subscribe to this for your tokenTransferActions
     */
    @Published public var tokenTransferActions: [TokenTransferAction] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenTransferActions. Subscribe to this for your tokenTransferActions
     */
    @Published public var esrSessions: [ESRSession] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated esr signing request. This will be initialized when a signing request is made
     */
    @Published public var esr: ESR? = nil {
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
        
        self.publicKeys = self.storage.getKeychainItem([String].self, forKey: "publicKeys") ?? []
        self.chainProviders = self.storage.getDefaultsItem([ChainProvider].self, forKey: "chainProviders") ?? []
        self.tokenContracts = self.storage.getDefaultsItem([TokenContract].self, forKey: "tokenContracts") ?? []
        self.accounts = self.storage.getDefaultsItem([Account].self, forKey: "accounts") ?? []
        self.tokenBalances = self.storage.getDefaultsItem([TokenBalance].self, forKey: "tokenBalances") ?? []
        self.tokenTransferActions = self.storage.getDefaultsItem([TokenTransferAction].self, forKey: "tokenTransferActions") ?? []
        self.esrSessions = self.storage.getDefaultsItem([ESRSession].self, forKey: "esrSessions") ?? []
        
        print("🧑‍💻 LOAD COMPLETED")
        print("ACCOUNTS => \(self.accounts.count)")
        print("TOKEN CONTRACTS => \(self.tokenContracts.count)")
        print("TOKEN BALANCES => \(self.tokenBalances.count)")
        print("TOKEN TRANSFER ACTIONS => \(self.tokenTransferActions.count)")
        print("ESR SESSIONS => \(self.esrSessions.count)")
        
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
        self.storage.setDefaultsItem(self.esrSessions, forKey: "esrSessions")
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
                        if let idx = self.chainProviders.firstIndex(of: chainProvider) {
                            self.chainProviders[idx] = chainProvider
                        } else {
                            self.chainProviders.append(chainProvider)
                        }
                    }
                    
                }
                
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
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
            
            if let idx = self.accounts.firstIndex(of: account) {
                self.accounts[idx] = account
            } else {
                self.accounts.append(account)
            }
            
            self.fetchAccountUserInfo(forAccount: account) { returnAccount in
                
                account = returnAccount
                
                if let idx = self.accounts.firstIndex(of: account) {
                    self.accounts[idx] = account
                } else {
                    self.accounts.append(account)
                }
                
                self.fetchBalances(forAccount: account) { tokenBalances in
                    
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
                            
                            self.fetchTransferActions(forTokenBalance: tokenBalance) { transferActions in
                                
                                tokenBalancesProcessed += 1
                                
                                for transferAction in transferActions {
                                    
                                    if let idx = self.tokenTransferActions.firstIndex(of: transferAction) {
                                        self.tokenTransferActions[idx] = transferAction
                                    } else {
                                        self.tokenTransferActions.append(transferAction)
                                    }
                                    
                                }
                                
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
    #if os(iOS)
    public func parseESR(openURLContext: UIOpenURLContext, completion: @escaping (ESR?) -> ()) {
        
        do {
            
            let signingRequest = try SigningRequest(openURLContext.url.absoluteString)
            let chainId = signingRequest.chainId
            
            guard let requestingAccountName = signingRequest.getInfo("account", as: String.self) else { completion(nil); return }
            guard let sid = signingRequest.getInfo("sid", as: String.self) else { completion(nil); return }
            guard let account = self.accounts.first(where: { $0.chainId == String(chainId) }) else { completion(nil); return }
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
                                            
                                            if let _ = rawAbis[account.stringValue]?.decodedAbi { // TODO
                                                
                                                if let transferActionABI = try? abidecoder.decode(TransferActionABI.self, from: $0.data) {
                                                    
                                                    let symbol = transferActionABI.quantity.symbol
                                                    
                                                    if let tokenContract = self.tokenContracts.first(where: { $0.chainId == String(chainId)
                                                                                                                && $0.symbol == symbol && $0.contract == account }) {
                                                        
                                                        let formatter = NumberFormatter()  // TODO: make this more effiecent
                                                        formatter.numberStyle = .currency
                                                        formatter.locale = Locale(identifier: "en_US")
                                                        let extra = formatter.string(for: transferActionABI.quantity.value * tokenContract.usdRate) ?? "$0.00"
                                                        
                                                        
                                                        let basicDisplay = ESRAction.BasicDisplay(actiontype: .transfer, name: tokenContract.name,
                                                                                                  secondary: transferActionABI.quantity.stringValue, extra: extra, tokenContract: tokenContract)
                                                        
                                                        return ESRAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay)
                                                        
                                                    }

                                                } else {
                                                    
                                                    let basicDisplay = ESRAction.BasicDisplay(actiontype: .custom, name: $0.name.stringValue.uppercased(),
                                                                                              secondary: nil, extra: nil, tokenContract: nil)
                                                    
                                                    return ESRAction(account: $0.account, name: $0.name, chainId: String(chainId), basicDisplay: basicDisplay)
                                                    
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
    #endif
    /**
     Use this to decline signing request
     - Parameter completion: Closure thats called when the function is complete.
     */
    public func declineESR(completion: @escaping () -> ()) {
        
        self.esr = nil
        completion()
        
    }
    
    /**
     Use this to accept signing request
     - Parameter completion: Closure thats called when the function is complete.
     */
    public func acceptESR(completion: @escaping (URL?) -> ()) {
        
        guard let esr = self.esr else { completion(nil); return }
        
        Authentication.shared.authenticate { success, _, error in
            
            if success {
                
                if esr.signingRequest.isIdentity {
                    
                    self.handleIdentityESR { url in
                        self.esr = nil
                        self.saveAll()
                        print(self.esrSessions.count)
                        completion(url)
                    }
                    
                } else if esr.signingRequest.actions.count > 0 {

                    self.handleActionsESR { url in
                        self.esr = nil
                        self.saveAll()
                        completion(url)
                    }
                    
                } else {
                    
                    self.esr = nil
                    self.saveAll()
                    
                    completion(nil)
                    
                }

            } else {
                self.esr = nil
                self.saveAll()
                completion(nil) // return error
            }
            
        }
        
    }
    
    /**
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
                
                WebServices.shared.addSeq(PostIdentityESROperation(esr: self.esr!, sig: sig)) { result in
                    
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
                
                WebServices.shared.addSeq(PostIdentityESROperation(esr: self.esr!, sig: sig)) { result in
                    
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
    
    private func fetchTransferActions(forTokenBalance tokenBalance: TokenBalance, completion: @escaping (Set<TokenTransferAction>) -> ()) {
        
        var retval = Set<TokenTransferAction>()
        
        guard let account = tokenBalance.account else {
            completion(retval)
            return
        }
        
        guard let chainProvider = account.chainProvider else {
            completion(retval)
            return
        }
        
        guard let tokenContract = tokenBalance.tokenContract else {
            completion(retval)
            return
        }
        
        WebServices.shared.addMulti(FetchTokenTransferActionsOperation(account: account, tokenContract: tokenContract,
                                                                       chainProvider: chainProvider, tokenBalance: tokenBalance)) { result in
            
            switch result {
            case .success(let transferActions):
                
                if let transferActions = transferActions as? Set<TokenTransferAction> {
                    retval = transferActions
                }

            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
            }
                                                                        
            completion(retval)
            
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
                    
                    if let accountNames = accountNames as? Set<String>, accountNames.count > 0 {
                        
                        for accountName in accountNames {
                            
                            let account = Account(chainId: chainProvider.chainId, name: accountName)
                            if self.accounts.firstIndex(of: account) == nil {
                                accounts.update(with: account)
                            }
                            
                        }
                        self.publicKeys.append(publicKey)
                        self.publicKeys = self.publicKeys.unique()
                        
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
        
        if let chainProvider = account.chainProvider {
            
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
        
        if let chainProvider = account.chainProvider {
            
            WebServices.shared.addMulti(FetchUserAccountInfoOperation(account: account, chainProvider: chainProvider)) { result in
                
                switch result {
                case .success(let updatedAccount):
                    
                    if let updatedAccount = updatedAccount as? Account {
                        account = updatedAccount
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
    
    private func fetchBalances(forAccount account: Account, completion: @escaping (Set<TokenBalance>) -> ()) {
        
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
                                                                         description: "", iconUrl: "", supply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         maxSupply: Asset(0.0, tokenBalance.amount.symbol),
                                                                         symbol: tokenBalance.amount.symbol, url: "", blacklisted: true)
                                
                                self.tokenContracts.append(unknownTokenContract)
                                
                            }
                            
                        }
                        
                        retval = tokenBalances
                        
                    }
                    
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                }
                
                completion(retval)
                
            }
            
        }
        
    }
    
}
