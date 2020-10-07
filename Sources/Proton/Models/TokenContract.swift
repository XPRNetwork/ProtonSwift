//
//  TokenContract.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
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
    public func currencyRateFormatted(forLocale locale: Locale = Locale(identifier: "en_US")) -> String {
        let rate = getRate(forCurrencyCode: locale.currencyCode ?? "USD")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(for: rate) ?? "$0.00"
    }
    // 24hr price change formatted
    public func priceChangePercentFormatted() -> String? {
        if let priceChangePercent = self.priceChangePercent {
            return "\(priceChangePercent)%"
        }
        return nil
    }
    
}
