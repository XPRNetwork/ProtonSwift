//
//  ProtonObservable.swift
//  
//
//  Created by Jacob Davis on 5/7/20.
//

import Foundation

@available(iOS 13, *)
public final class ProtonObservable: ObservableObject {
    
    /**
     Live updated set of chainProviders. Subscribe to this for your chainProviders
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var chainProviders: [ChainProvider] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenContracts. Subscribe to this for your tokenContracts
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var tokenContracts: [TokenContract] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live active account. Subscribe to this for your account
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var activeAccount: Account? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenBalances. Subscribe to this for your tokenBalances
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var tokenBalances: [TokenBalance] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenTransferActions. Subscribe to this for your tokenTransferActions
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var tokenTransferActions: [TokenTransferAction] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated set of tokenTransferActions. Subscribe to this for your tokenTransferActions
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var esrSessions: [ESRSession] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    /**
     Live updated esr signing request. This will be initialized when a signing request is made
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var esr: ESR? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(chainProvidersWillSet(_:)),
                                               name: Proton.Notifications.chainProvidersWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenContractsWillSet(_:)),
                                               name: Proton.Notifications.tokenContractsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenBalancesWillSet(_:)),
                                               name: Proton.Notifications.tokenBalancesWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenTransferActionsWillSet),
                                               name: Proton.Notifications.tokenTransferActionsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(esrSessionsWillSet(_:)),
                                               name: Proton.Notifications.esrSessionsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(esrWillSet),
                                               name: Proton.Notifications.esrWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(activeAccountWillSet),
                                               name: Proton.Notifications.activeAccountWillSet, object: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func chainProvidersWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [ChainProvider] else {
            return
        }
        self.chainProviders = newValue
    }
    
    @objc func tokenContractsWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [TokenContract] else {
            return
        }
        self.tokenContracts = newValue
    }
    
    @objc func tokenBalancesWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [TokenBalance] else {
            return
        }
        self.tokenBalances = newValue
    }
    
    @objc func tokenTransferActionsWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [TokenTransferAction] else {
            return
        }
        self.tokenTransferActions = newValue
    }
    
    @objc func esrSessionsWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [ESRSession] else {
            return
        }
        self.esrSessions = newValue
    }
    
    @objc func esrWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? ESR else {
            return
        }
        self.esr = newValue
    }
    
    @objc func activeAccountWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? Account else {
            return
        }
        self.activeAccount = newValue
    }

}
