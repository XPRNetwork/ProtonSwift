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
public struct TokenContract: Codable, Identifiable, Hashable, ChainProviderProtocol, TokenBalanceProtocol {
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
    public var rates: [ExchangeRate.Rate] {
        didSet {
            self.updatedAt = Date()
        }
    }
    /// :nodoc:
    public init(chainId: String, contract: Name, issuer: Name, resourceToken: Bool,
                  systemToken: Bool, name: String, desc: String, iconUrl: String,
                  supply: Asset, maxSupply: Asset, symbol: Asset.Symbol, url: String, isBlacklisted: Bool,
                  updatedAt: Date = Date(), rates: [ExchangeRate.Rate] = [], priceChangePercent: Double? = nil) {
        
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
    /// Determine if token is a Liquidity token from swaps
    public var isLiquidityToken: Bool {
        return contract.stringValue == "proton.swaps"
    }
    /// ChainProvider associated with the Account
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProvider?.chainId == self.chainId ? Proton.shared.chainProvider : nil
    }
    /// TokenBalance associated with the Account
    public var tokenBalance: TokenBalance? {
        if let account = Proton.shared.account {
            return Proton.shared.tokenBalances.first(where: { $0.accountId == account.id && $0.tokenContractId == self.id })
        }
        return nil
    }
    
    public func getPriceChangePercent(forCurrencyCode currencyCode: String = "USD") -> Double {
        if let rate = self.rates.first(where: { $0.counterCurrency == currencyCode }) {
            return rate.priceChangePercent
        }
        return 0.0
    }
    
    public func getRate(forCurrencyCode currencyCode: String = "USD") -> Double {
        if let rate = self.rates.first(where: { $0.counterCurrency == currencyCode }) {
            return rate.price
        }
        return 0.0
    }
    public func getMarketCap(forCurrencyCode currencyCode: String = "USD") -> Double {
        if let rate = self.rates.first(where: { $0.counterCurrency == currencyCode }) {
            return rate.marketCap
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
    public func priceChangePercentFormatted(forCurrencyCode currencyCode: String = "USD") -> String? {
        let priceChangePercent = getPriceChangePercent(forCurrencyCode: currencyCode)
        return "\(priceChangePercent)%"
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
