//
//  TokenBalance.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
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
    /// :nodoc:
    public init?(account: Account, contract: Name, amount: Double, precision: UInt8, symbol: String) {
        
        do {
            
            let assetSymbol = try Asset.Symbol(precision, symbol)
            self.accountId = account.id
            self.chainId = account.chainId
            self.contract = contract
            self.amount = Asset(amount, assetSymbol)
            self.tokenContractId = "\(contract.stringValue):\(self.amount.symbol.name)"
            
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
    /// TokenContracts associated with this TokenBalance
    public var tokenContract: TokenContract? {
        return Proton.shared.tokenContracts.first(where: { $0.id == self.tokenContractId })
    }
    /// TokenTransferActions associated with this TokenBalance
    public var tokenTransferActions: [TokenTransferAction] {
        return Proton.shared.tokenTransferActions.filter { $0.accountId == self.accountId && $0.tokenBalanceId == self.id }
    }
    /// Account associated with this TokenBalance
    public var account: Account? {
        if let acc = Proton.shared.account, acc.id == self.accountId {
            return acc
        }
        return nil
    }
    
    public var usdRate: Double {
        return tokenContract?.usdRate ?? 0.02 // TODO:
    }
    
    public func usdBalanceFormatted(adding: Double = 0.0) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(for: self.amount.value * self.usdRate + adding) ?? "$0.00"
        
    }
    
}
