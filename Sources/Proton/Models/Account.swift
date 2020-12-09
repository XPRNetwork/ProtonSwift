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
public struct Staking: Codable, GlobalsXPRProtocol {
    
    /// The amount staked
    public var staked: Asset
    /// Whether or not the account is qualified to receive staking rewards. ie account has to be voting for 4 producers
    public var isQualified: Bool
    /// The reward amount in which the account can claim
    public var claimAmount: Asset
    /// The date of the last reward claim
    public var lastclaim: Date
    /// The list of producer names the account has voted for
    public var producerNames: [Name]
    /// Get globalsXPR settings
    public var globalsXPR: GlobalsXPR? {
        return Proton.shared.globalsXPR ?? nil
    }
    public var producers: [Producer] {
        return Proton.shared.producers.filter({ producerNames.contains($0.name) })
    }
    /// Formated staked without symbol and precision
    public func stakedFormatted(forLocale locale: Locale = Locale(identifier: "en_US"),
                                withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return self.staked.formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
    /// Formated claimAmount without symbol and precision
    public func claimAmountFormatted(forLocale locale: Locale = Locale(identifier: "en_US"),
                                     withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return self.claimAmount.formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
}

/**
StakingRefund shows the amount unstaked and request time it occured
*/
public struct StakingRefund: Codable, GlobalsXPRProtocol {
    /// The unstaked amount in which the user will be eligable for after unstaking period
    public var quantity: Asset
    /// The time which the last unstaking action occured
    public var requestTime: Date
    /// Get globalsXPR settings
    public var globalsXPR: GlobalsXPR? {
        return Proton.shared.globalsXPR ?? nil
    }
    /// Formated quantity without symbol and precision
    public func quantityFormated(forLocale locale: Locale = Locale(identifier: "en_US"),
                                 withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return self.quantity.formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
}

/**
KYC is a entry provided by a kyc provider
*/
public struct KYC: Codable {
    /// The account name of the kyc provider
    public var provider: Name
    /// The time which this kyc was last updated
    public var date: Date
    /// Comma seperated list of kyc'd items. prefixed with source:
    public var level: String
}

/**
Account is the Proton chain account object.
*/
public struct Account: Codable, Identifiable, Hashable, ChainProviderProtocol, TokenBalancesProtocol, AvatarProtocol, GlobalsXPRProtocol {
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
    /// The KYC entries
    public var kyc: [KYC]?
    /// :nodoc:
    public init(chainId: String, name: String, verified: Bool = false,
                userDefinedName: String = "", base64Avatar: String = "", permissions: [API.V1.Chain.Permission] = [],
                staking: Staking? = nil, stakingRefund: StakingRefund? = nil, kyc: [KYC]? = nil) {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.userDefinedName = userDefinedName
        self.base64Avatar = base64Avatar
        self.permissions = permissions
        self.staking = staking
        self.stakingRefund = stakingRefund
        
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
        
        var staking: Staking?
        
        if let stakingDictionary = dictionary["staking"] as? [String: Any] {
            if let data = try? JSONSerialization.data(withJSONObject: stakingDictionary, options: .prettyPrinted) {
                do {
                    staking = try JSONDecoder().decode(Staking.self, from: data)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        var stakingRefund: StakingRefund?
        
        if let stakingRefundDictionary = dictionary["stakingRefund"] as? [String: Any] {
            if let data = try? JSONSerialization.data(withJSONObject: stakingRefundDictionary, options: .prettyPrinted) {
                do {
                    stakingRefund = try JSONDecoder().decode(StakingRefund.self, from: data)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        var permissions: [API.V1.Chain.Permission]?
        
        if let permissionsDictionary = dictionary["permissions"] as? [[String: Any]] {
            if let data = try? JSONSerialization.data(withJSONObject: permissionsDictionary, options: .prettyPrinted) {
                do {
                    permissions = try JSONDecoder().decode([API.V1.Chain.Permission].self, from: data)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        return Account(chainId: chainId, name: name, verified: dictionary["verified"] as? Bool ?? false,
                       userDefinedName: dictionary["userDefinedName"] as? String ?? "",
                       base64Avatar: dictionary["base64Avatar"] as? String ?? "",
                       permissions: permissions ?? [],
                       staking: staking, stakingRefund: stakingRefund)
        
    }
    /// :nodoc:
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    /// Get globalsXPR settings
    public var globalsXPR: GlobalsXPR? {
        return Proton.shared.globalsXPR ?? nil
    }
    /// ChainProvider associated with the Account
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProvider?.chainId == self.chainId ? Proton.shared.chainProvider : nil
    }
    /// TokenBalances associated with the Account
    public var tokenBalances: [TokenBalance] {
        return Proton.shared.tokenBalances.filter { $0.accountId == self.id }
    }
    /// XPR TokenBalance associated with the Account
    public var systemTokenBalance: TokenBalance? {
        return tokenBalances.first(where: { $0.tokenContractId == "eosio.token:XPR" })
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
    /// Returns the max staking amount for the account.
    public var maxStakingAmount: Asset {
        let systemBalance = self.availableSystemBalance().value
        let stakingAmount = self.staking?.staked.value ?? 0.0
        let stakingRefundAmount = self.stakingRefund?.quantity.value ?? 0.0
        return Asset(stakingAmount+stakingRefundAmount+systemBalance, Asset.Symbol(stringLiteral: "4,XPR"))
    }
    /// Returns the first tokenBalance that has more than zero balance. System balance always takes precedence.
    public var firstAvailableTokenBalance: TokenBalance? {
        if self.availableSystemBalance().value > 0 {
            return self.systemTokenBalance
        } else {
            return self.tokenBalances.first(where: { $0.amount.value > 0 })
        }
    }
    /// Returns the first tokenBalance that has more than zero balance. System balance always takes precedence.
    public var firstSwappableAvailableTokenBalance: TokenBalance? {
        if self.availableSystemBalance().value > 0 {
            return self.systemTokenBalance
        } else {
            return self.tokenBalances.first(where: { $0.amount.value > 0 && $0.tokenContract?.contract.stringValue == "xtokens" })
        }
    }
    
    public func totalCurrencyBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US"), withStakedXPR: Bool = false) -> String {
        
        let tokenBalances = self.tokenBalances
        let amount: Double = tokenBalances.reduce(0.0) { value, tokenBalance in
            var value = value
            let rate = tokenBalance.getRate(forCurrencyCode: locale.currencyCode ?? "USD")
            if withStakedXPR && tokenBalance.tokenContractId == "eosio.token:XPR" {
                let staked = self.staking?.staked.value ?? 0.0
                let refund = self.stakingRefund?.quantity.value ?? 0.0
                let amount = tokenBalance.amount.value
                let total = (amount+staked+refund) * rate
                value += total
            } else {
                value += (tokenBalance.amount.value * rate)
            }
            return value
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(for: amount) ?? "$0.00"
        
    }
    
    public func availableSystemBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US"), withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return availableSystemBalance().formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
    
    public func totalSystemBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US"), withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return totalSystemBalance().formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
    
    public func availableSystemBalance() -> Asset {
        return self.systemTokenBalance?.amount ?? Asset(0.0, try! Asset.Symbol(stringValue: "4,XPR"))
    }
    
    public func totalSystemBalance() -> Asset {
        let available = self.systemTokenBalance?.amount ?? Asset(0.0, try! Asset.Symbol(stringValue: "4,XPR"))
        let staked = self.staking?.staked ?? Asset(0.0, try! Asset.Symbol(stringValue: "4,XPR"))
        let refund = self.stakingRefund?.quantity ?? Asset(0.0, try! Asset.Symbol(stringValue: "4,XPR"))
        return available+staked+refund
    }

    public func privateKey(forPermissionName: String, completion: @escaping ((Result<PrivateKey?, Error>) -> Void)) {
        
        guard let permission = self.permissions.first(where: { $0.permName.stringValue == forPermissionName }) else {
            completion(.failure(Proton.ProtonError(message: "Unable to find accout permission of name \(forPermissionName)")))
            return
        }
        
        guard let keyWeight = permission.requiredAuth.keys.first else {
            completion(.failure(Proton.ProtonError(message: "Unable to find key with permission name \(forPermissionName)")))
            return
        }
        
        DispatchQueue.global().async {
            if let privateKey = Proton.shared.storage.getKeychainItem(String.self, forKey: keyWeight.key.stringValue) {
                completion(.success(try? PrivateKey(stringValue: privateKey)))
            } else {
                completion(.failure(Proton.ProtonError(message: "Unable to find private key in keychain for \(self.name.stringValue)")))
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
     - Parameter publicKey: PublicKey
     - Returns: Bool
     */
    public func isKeyAssociated(publicKey: PublicKey) -> Bool {
        
        for permission in self.permissions {
            for key in permission.requiredAuth.keys {
                if key.key.stringValue == publicKey.stringValue || key.key.stringValue == publicKey.legacyStringValue {
                    return true
                }
            }
        }
        
        return false
        
    }
    /**
     Check if the publickey is associated with the Account
     - Parameter withPermissionName: The permission name. ex: active
     - Parameter publicKey: PublicKey
     - Returns: Bool
     */
    public func isKeyAssociated(withPermissionName permissionName: String, forPublicKey publicKey: PublicKey) -> Bool {
        
        if let permission = self.permissions.first(where: { $0.permName.stringValue == permissionName }) {
            for key in permission.requiredAuth.keys {
                if key.key.stringValue == publicKey.stringValue || key.key.stringValue == publicKey.legacyStringValue {
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
