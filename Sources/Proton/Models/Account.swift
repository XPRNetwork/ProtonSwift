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

public struct Account: Codable, Identifiable, Hashable, ChainProviderProtocol, TokenBalancesProtocol, AvatarProtocol {
    
    public var id: String { return "\(self.chainId):\(self.name.stringValue)" }
    public var chainId: String
    public var name: Name
    public var verified: Bool
    public var fullName: String
    public var permissions: [API.V1.Chain.Permission]
    
    public var base64Avatar: String
    
    public init(chainId: String, name: String, verified: Bool = false,
                fullName: String = "", base64Avatar: String = "", permissions: [API.V1.Chain.Permission] = []) {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.fullName = fullName
        self.base64Avatar = base64Avatar
        self.permissions = permissions
        
    }
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProviders.first(where: { $0.chainId == self.chainId })
    }
    
    public var tokenBalances: [TokenBalance] {
        return Proton.shared.tokenBalances.filter { $0.accountId == self.id }
    }
    
    public func totalUSDBalanceFormatted(adding: Double = 0.0) -> String {
        
        let tokenBalances = self.tokenBalances
        let amount: Double = tokenBalances.reduce(0.0) { value, tokenBalance in
            value + (tokenBalance.amount.value * tokenBalance.usdRate)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(for: amount + adding) ?? "$0.00"
        
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
