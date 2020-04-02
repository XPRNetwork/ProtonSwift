//
//  Account.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import EOSIO
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

protocol AccountProtocol {
    var account: Account? { get }
}

public struct Account: Codable, Identifiable, Hashable, ChainProviderProtocol, TokenBalancesProtocol {

    public var id: String { return "\(chainId):\(name.stringValue)" }
    public var chainId: String
    public var name: Name
    public var verified: Bool
    public var fullName: String
    public var permissions: [API.V1.Chain.Permission]
    
    var base64Avatar: String
    var defaultBase64Avatar: String = "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"
    
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
    
    public var tokenBalances: Set<TokenBalance> {
        return Proton.shared.tokenBalances.filter({ $0.accountId == self.id })
    }
    
    public var avatarImage: Image {
        
        #if os(macOS)
        
        return Image(nsImage: self.avatarNSImage)
        
        #elseif os(iOS)

        return Image(uiImage: self.avatarUIImage)

        #endif
        
    }
    
    #if os(macOS)
    
    public var avatarNSImage: NSImage {
        
        let defaultAvatar = NSImage(data: Data(base64Encoded: self.defaultBase64Avatar)!)!
        
        if self.base64Avatar.isEmpty {
            return defaultAvatar
        }
        
        if let data = Data(base64Encoded: self.base64Avatar), let image = NSImage(data: data) {
            return image
        }
        
        return defaultAvatar

    }
    
    #endif
    
    #if os(iOS)
    
    public var avatarUIImage: UIImage {
        
        let defaultAvatar = UIImage(data: Data(base64Encoded: self.defaultBase64Avatar)!)!
        
        if self.base64Avatar.isEmpty {
            return defaultAvatar
        }
        
        if let data = Data(base64Encoded: self.base64Avatar), let image = UIImage(data: data) {
            return image
        }
        
        return defaultAvatar
        
    }
    
    #endif
    
    public func totalUSDBalanceFormatted(adding: Double = 0.0) -> String {

        let tokenBalances = self.tokenBalances
        let amount: Double = tokenBalances.reduce(0.0) { value, tokenBalance in
            value + (tokenBalance.amount.value * tokenBalance.usdRate)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(for: amount) ?? "$0.00"

    }
    
    public func privateKey(forPermissionName: String) -> PrivateKey? {
        
        if let permission = self.permissions.first(where: { $0.permName.stringValue == forPermissionName }) {
            
            if let keyWeight = permission.requiredAuth.keys.first {
                
                if let privateKeyString = Proton.shared.storage.getKeychainItem(String.self, forKey: keyWeight.key.stringValue) {
                    return PrivateKey(privateKeyString)
                }
                
            }
            
        }
        
        return nil
        
    }

}
