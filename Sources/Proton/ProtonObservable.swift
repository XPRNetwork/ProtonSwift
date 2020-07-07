//
//  ProtonObservable.swift
//  Proton
//  
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

/**
The ProtonObeservable class is helpful when you want to take advantage of iOS13+ Combine, etc functionality.
*/
@available(iOS 13, *)
public final class ProtonObservable: ObservableObject {
    
    /**
     Live updated set of chainProviders. Subscribe to this for your chainProviders
     Important: This is a copy of the source from Proton.shared. Modifications should
     be made there.
     */
    @Published public private(set) var chainProvider: ChainProvider? = nil {
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
    @Published public private(set) var contacts: [Contact] = [] {
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
    
    /// :nodoc:
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(chainProviderWillSet(_:)),
                                               name: Proton.Notifications.chainProviderWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenContractsWillSet(_:)),
                                               name: Proton.Notifications.tokenContractsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenBalancesWillSet(_:)),
                                               name: Proton.Notifications.tokenBalancesWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tokenTransferActionsWillSet(_:)),
                                               name: Proton.Notifications.tokenTransferActionsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contactsWillSet(_:)),
                                               name: Proton.Notifications.contactsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(esrSessionsWillSet(_:)),
                                               name: Proton.Notifications.esrSessionsWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(esrWillSet),
                                               name: Proton.Notifications.esrWillSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountWillSet),
                                               name: Proton.Notifications.accountWillSet, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func chainProviderWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? ChainProvider else {
            return
        }
        self.chainProvider = newValue
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
    
    @objc func contactsWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? [Contact] else {
            return
        }
        self.contacts = newValue
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
    
    @objc func accountWillSet(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let newValue = userInfo["newValue"] as? Account else {
            return
        }
        self.activeAccount = newValue
    }

}
