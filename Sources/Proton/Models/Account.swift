//
//  Account.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//
#if os(macOS)
import AppKit
#endif
import EOSIO
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/**
Account is the Proton chain account object.
*/
public struct Account: Codable, Identifiable, Hashable, ChainProviderProtocol, TokenBalancesProtocol, AvatarProtocol {
    /// This is used as the primary key for storing the account
    public var id: String { return self.name.stringValue }
    /// The chainId associated with the account
    public var chainId: String
    /// The Name of the account. You can get the string value via name.stringValue
    public var name: Name
    /// Is the account KYC verified
    public var verified: Bool
    /// The user modified name
    public var nickName: String
    /// The current key permissions for the account
    public var permissions: [API.V1.Chain.Permission]
    /// The user modified Avatar string
    public var base64Avatar: String
    /// :nodoc:
    public init(chainId: String, name: String, verified: Bool = false,
                nickName: String = "", base64Avatar: String = "", permissions: [API.V1.Chain.Permission] = []) {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.nickName = nickName
        self.base64Avatar = base64Avatar
        self.permissions = permissions
        
    }
    /// :nodoc:
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    /// ChainProvider associated with the Account
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProvider?.chainId == self.chainId ? Proton.shared.chainProvider : nil
    }
    /// TokenBalances associated with the Account
    public var tokenBalances: [TokenBalance] {
        return Proton.shared.tokenBalances.filter { $0.accountId == self.id }
    }

    public func totalBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US")) -> String {
        
        let tokenBalances = self.tokenBalances
        let amount: Double = tokenBalances.reduce(0.0) { value, tokenBalance in
            value + (tokenBalance.amount.value * tokenBalance.getRate(forCurrencyCode: locale.currencyCode ?? "USD"))
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(for: amount) ?? "$0.00"
        
    }

    public func privateKey(forPermissionName: String) -> PrivateKey? {
        
        if let permission = self.permissions.first(where: { $0.permName.stringValue == forPermissionName }) {
            
            if let keyWeight = permission.requiredAuth.keys.first {
                // TODO: - KEYCHAIN
//                if let privateKeyString = Proton.shared.storage.getKeychainItem(String.self, forKey: keyWeight.key.stringValue) {
//                    return PrivateKey(privateKeyString)
//                }
                
            }
            
        }
        
        return nil
        
    }
    /**
     Check if the publickey is associated with the Account
     - Parameter publicKey: Wif formated public key
     - Returns: Bool
     */
    public func isKeyAssociated(publicKey: String) -> Bool {
        
        for permission in self.permissions {
            for key in permission.requiredAuth.keys {
                if key.key.stringValue == publicKey {
                    return true
                }
            }
        }
        
        return false
        
    }
    /**
     Returns a set of keys associated with the Account
     - Returns: Set\<PublicKey\>
     */
    public func uniquePublicKeys() -> Set<PublicKey> {
        
        var retval = Set<PublicKey>()
        
        for permission in self.permissions {
            for requiredAuth in permission.requiredAuth.keys {
                retval.update(with: requiredAuth.key)
            }
        }
        
        return retval
        
    }
    
}
