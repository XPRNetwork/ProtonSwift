//
//  Account.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
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
Staking is the object which represents the accounts staking info, if any
*/
public struct Staking: Codable {
    /// The amount staked
    public var staked: Asset
    /// Whether or not the account is qualified to receive staking rewards. ie account has to be voting for 4 producers
    public var isQualified: Bool
    /// The reward amount in which the account can claim
    public var claimAmount: Asset
    /// The date of the last reward claim
    public var lastclaim: Date
    /// The list of producers the account has voted for
    public var producers: [Name]
}

/**
StakingRefund shows the amount unstaked and request time it occured
*/
public struct StakingRefund: Codable {
    /// The unstaked amount in which the user will be eligable for after unstaking period
    public var quantity: Asset
    /// The time which the last unstaking action occured
    public var requestTime: Date

}

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
    /// The user defined name
    public var userDefinedName: String
    /// The current key permissions for the account
    public var permissions: [API.V1.Chain.Permission]
    /// The user modified Avatar string
    public var base64Avatar: String
    /// The user modified Avatar string
    public var staking: Staking?
    /// The user modified Avatar string
    public var stakingRefund: StakingRefund?
    
    /// :nodoc:
    public init(chainId: String, name: String, verified: Bool = false,
                userDefinedName: String = "", base64Avatar: String = "", permissions: [API.V1.Chain.Permission] = []) {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.userDefinedName = userDefinedName
        self.base64Avatar = base64Avatar
        self.permissions = permissions
        self.stakingRefund = nil
        self.staking = nil
        
    }
    /// :nodoc:
    static func create(dictionary: [String: Any]?) -> Account? {
        
        guard let dictionary = dictionary else {
            return nil
        }
        
        guard let chainId = dictionary["chainId"] as? String else {
            return nil
        }
        
        guard let name = dictionary["name"] as? String else {
            return nil
        }
        
        return Account(chainId: chainId, name: name, verified: dictionary["verified"] as? Bool ?? false, userDefinedName: dictionary["userDefinedName"] as? String ?? "", base64Avatar: dictionary["base64Avatar"] as? String ?? "", permissions: dictionary["permissions"] as? [API.V1.Chain.Permission] ?? [])
        
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
    /// Name formated with leading @
    public var nameWithAmpersand: String {
        return "@\(name.stringValue)"
    }
    /// Return name if not empty, else use the account name
    public var userDefinedNameOrName: String {
        return userDefinedName.isEmpty == false ? userDefinedName : self.name.stringValue
    }
    /// Return true if account is qualified for rewards by staking and voting
    public var isStakingRewardQualified: Bool {
        if let staking = self.staking {
            return staking.isQualified
        }
        return false
    }
    
    public func totalCurrencyBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US")) -> String {
        
        let tokenBalances = self.tokenBalances
        let amount: Double = tokenBalances.reduce(0.0) { value, tokenBalance in
            value + (tokenBalance.amount.value * tokenBalance.getRate(forCurrencyCode: locale.currencyCode ?? "USD"))
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(for: amount) ?? "$0.00"
        
    }
    
    public func privateKey(forPermissionName: String, completion: @escaping ((Result<PrivateKey?, Error>) -> Void)) {
        
        guard let permission = self.permissions.first(where: { $0.permName.stringValue == forPermissionName }) else {
            completion(.failure(ProtonError.error("Unable to find accout permission of name \(forPermissionName)")))
            return
        }
        
        guard let keyWeight = permission.requiredAuth.keys.first else {
            completion(.failure(ProtonError.error("Unable to find key with permission name \(forPermissionName)")))
            return
        }
        
        DispatchQueue.main.async {
            if let privateKey = Proton.shared.storage.getKeychainItem(String.self, forKey: keyWeight.key.stringValue) {
                completion(.success(try? PrivateKey(stringValue: privateKey)))
            } else {
                completion(.failure(ProtonError.error("Unable to find private key in keychain for \(self.name.stringValue)")))
            }
        }
    }

    /**
     Check if the Account has private key stored within keychain for the passed permission
     - Parameter forPermissionName: Key permission name. ex: active
     - Returns: Bool
     */
    public func hasStoredPrivateKey(forPermissionName permissionName: String) -> Bool {
        if let permission = self.permissions.first(where: { $0.permName.stringValue == permissionName }) {
            if let keyWeight = permission.requiredAuth.keys.first {
                return Proton.shared.storage.keychainContains(key: keyWeight.key.stringValue)
            }
        }
        return false
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
