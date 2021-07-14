//
//  TokenBalance.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

/**
ChainProvider the object that provides chain related configuration aspects of the Proton objects
*/
public struct TokenBalance: Codable, Identifiable, Hashable, TokenContractProtocol, TokenTransferActionsProtocol, AccountProtocol {
    /// This is used as the primary key for storing the account
    public var id: String { return "\(self.accountId):\(self.contract.stringValue):\(self.amount.symbol.name)" }
    /// accountId is used to link Account
    public let accountId: String
    /// tokenContractId is used to link TokenContract.
    public let tokenContractId: String
    /// The chainId associated with the TokenBalance
    public let chainId: String
    /// The Name of the contract. You can get the string value via contract.stringValue
    public let contract: Name
    /// The Asset amount. See EOSIO type Asset for more info
    public var amount: Asset
    /// When the tokebalance was updated. This will also be updated after tokenContract exchange rate was updated
    public var updatedAt: Date
    /// :nodoc:
    public init?(account: Account, contract: Name, amount: Double, precision: UInt8?, symbol: String, updatedAt: Date = Date()) {
        
        do {
            
            let assetSymbol = try Asset.Symbol(precision ?? 0, symbol)
            self.accountId = account.id
            self.chainId = account.chainId
            self.contract = contract
            self.amount = Asset(amount, assetSymbol)
            self.tokenContractId = "\(contract.stringValue):\(self.amount.symbol.name)"
            self.updatedAt = updatedAt
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            return nil
        }
        
    }
    /// :nodoc:
    public static func == (lhs: TokenBalance, rhs: TokenBalance) -> Bool {
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
    /// TokenContracts associated with this TokenBalance
    public var tokenContract: TokenContract? {
        return Proton.shared.tokenContracts.first(where: { $0.id == self.tokenContractId })
    }
    /// TokenTransferActions associated with this TokenBalance
    public var tokenTransferActions: [TokenTransferAction] {
        if let actions = Proton.shared.tokenTransferActions[self.tokenContractId]?.filter({ $0.accountId == self.accountId && $0.tokenBalanceId == self.id }) {
            return actions.sorted { $0.date == $1.date ? $0.globalSequence > $1.globalSequence : $0.date > $1.date }
        }
        return []
    }
    /// Account associated with this TokenBalance
    public var account: Account? {
        if let acc = Proton.shared.account, acc.id == self.accountId {
            return acc
        }
        return nil
    }
    
    public func getRate(forCurrencyCode currencyCode: String) -> Double {
        return self.tokenContract?.getRate(forCurrencyCode: currencyCode) ?? 0.0
    }
    /// Currency balance
    public func currencyBalance(forLocale locale: Locale = Locale(identifier: "en_US"), withStakedXPR: Bool = false) -> Double {
        let rate = getRate(forCurrencyCode: locale.currencyCode ?? "USD")
        if self.tokenContractId == "eosio.token:XPR" && withStakedXPR {
            let totalSystemBalance = self.account?.totalSystemBalance().value ?? 0.0
            return totalSystemBalance * rate
        }
        return self.amount.value * rate
    }
    /// Formated currency balance
    public func currencyBalanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US"), withStakedXPR: Bool = false) -> String {
        if self.tokenContractId == "eosio.token:XPR" && withStakedXPR {
            return self.account?.totalSystemBalance().formattedAsCurrency(forLocale: locale, withRate: getRate(forCurrencyCode: locale.currencyCode ?? "USD")) ?? self.amount.formattedAsCurrency(forLocale: locale, withRate: getRate(forCurrencyCode: locale.currencyCode ?? "USD"))
        }
        return self.amount.formattedAsCurrency(forLocale: locale, withRate: getRate(forCurrencyCode: locale.currencyCode ?? "USD"))
    }
    /// Formated balance without symbol and precision
    public func balanceFormatted(forLocale locale: Locale = Locale(identifier: "en_US"),
                                 withSymbol symbol: Bool = false, andPrecision precision: Bool = false,
                                 withStakedXPR: Bool = false) -> String {
        if self.tokenContractId == "eosio.token:XPR" && withStakedXPR {
            return self.account?.totalSystemBalanceFormatted(forLocale: locale, withSymbol: symbol, andPrecision: precision) ?? self.amount.formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
        }
        return self.amount.formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
    
}
