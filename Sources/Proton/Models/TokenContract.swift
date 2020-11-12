//
//  TokenContract.swift
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
The TokenContract object provides chain information about a token contract from the Proton chain
*/
public struct TokenContract: Codable, Identifiable, Hashable, ChainProviderProtocol {
    /// This is used as the primary key for storing the account
    public var id: String { return "\(self.contract.stringValue):\(self.symbol.name)" }
    /// The chainId associated with the TokenBalance
    public var chainId: String
    /// The Name of the contract. You can get the string value via contract.stringValue
    public var contract: Name
    /// The Name of the issuer. You can get the string value via issuer.stringValue
    public var issuer: Name
    /// Indicates whether or not this token is the resource token. ex: SYS
    public var resourceToken: Bool
    /// Indicates whether or not this token is the system token. ex: XPR
    public var systemToken: Bool
    /// The human readable name of the token registered by the token owner
    public var name: String
    /// The human readable description of the token registered by the token owner
    public var desc: String
    /// Icon url of the token registered by the token owner
    public var iconUrl: String
    /// The Asset supply of the token. See EOSIO type Asset for more info
    public var supply: Asset
    /// The Asset max supply of the token. See EOSIO type Asset for more info
    public var maxSupply: Asset
    /// The Symbol of the token. See EOSIO type Asset.Symbol for more info
    public var symbol: Asset.Symbol
    /// The url to the homepage of the token registered by the token owner
    public var url: String
    /// Is the token blacklisted. This is a value set by the blockproducers
    public var isBlacklisted: Bool
    /// When the tokebalance was updated. This will also be updated after tokenContract exchange rate was updated
    public var updatedAt: Date
    /// Exchange rates
    public var rates: [String: Double] {
        didSet {
            self.updatedAt = Date()
        }
    }
    /// 24 price change percent
    public var priceChangePercent: Double?
    /// :nodoc:
    public init(chainId: String, contract: Name, issuer: Name, resourceToken: Bool,
                  systemToken: Bool, name: String, desc: String, iconUrl: String,
                  supply: Asset, maxSupply: Asset, symbol: Asset.Symbol, url: String, isBlacklisted: Bool,
                  updatedAt: Date = Date(), rates: [String: Double] = ["USD": 0.0], priceChangePercent: Double? = nil) {
        
        self.chainId = chainId
        self.contract = contract
        self.issuer = issuer
        self.resourceToken = resourceToken
        self.systemToken = systemToken
        self.name = name
        self.desc = desc
        self.iconUrl = iconUrl
        self.supply = supply
        self.maxSupply = maxSupply
        self.symbol = symbol
        self.url = url
        self.isBlacklisted = isBlacklisted
        self.updatedAt = updatedAt
        self.rates = rates
        
    }
    /// :nodoc:
    public static func == (lhs: TokenContract, rhs: TokenContract) -> Bool {
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
    
    public func getRate(forCurrencyCode currencyCode: String = "USD") -> Double {
        if let rate = self.rates[currencyCode] {
            return rate
        }
        return 0.0
    }
    /// Currency rate
    public func currencyRateFormatted(forLocale locale: Locale = Locale(identifier: "en_US"), maximumFractionDigits: Int = 2) -> String {
        let rate = getRate(forCurrencyCode: locale.currencyCode ?? "USD")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(for: rate) ?? "$0.00"
    }
    // 24hr price change formatted
    public func priceChangePercentFormatted() -> String? {
        if let priceChangePercent = self.priceChangePercent {
            return "\(priceChangePercent)%"
        }
        return nil
    }
  
    public var defaultBase64Icon: String { "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" }
    
    public var defaultImage: Image {
        
        #if os(macOS)
        
        return Image(nsImage: self.defaultNSImage)
        
        #elseif os(iOS)
        
        return Image(uiImage: self.defaultUIImage)
        
        #endif
        
    }
    
    #if os(macOS)
    
    public var defaultNSImage: NSImage {
        return NSImage(data: Data(base64Encoded: self.defaultBase64Icon)!)!
    }
    
    #endif
    
    #if os(iOS)
    
    public var defaultUIImage: UIImage {
        return UIImage(data: Data(base64Encoded: self.defaultBase64Icon)!)!
    }
    
    #endif
}

