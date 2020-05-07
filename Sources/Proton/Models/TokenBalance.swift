//
//  TokenBalance.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

protocol TokenBalancesProtocol {
    var tokenBalances: [TokenBalance] { get }
}

protocol TokenBalanceProtocol {
    var tokenBalance: TokenBalance? { get }
}

public struct TokenBalance: Codable, Identifiable, Hashable, TokenContractProtocol, TokenTransferActionsProtocol, AccountProtocol {
    
    public var id: String { return "\(self.accountId):\(self.contract):\(self.amount.symbol.name)" }
    
    public let accountId: String
    public let tokenContractId: String
    public let chainId: String
    public let contract: Name
    
    public var amount: Asset
    
    public init?(accountId: String, contract: Name, amount: Double, precision: UInt8, symbol: String) {
        
        do {
            
            let assetSymbol = try Asset.Symbol(precision, symbol)
            self.accountId = accountId
            self.chainId = accountId.components(separatedBy: ":").first ?? ""
            self.contract = contract
            self.amount = Asset(amount, assetSymbol)
            self.tokenContractId = "\(self.chainId):\(contract):\(self.amount.symbol.name)"
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    public static func == (lhs: TokenBalance, rhs: TokenBalance) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public var tokenContract: TokenContract? {
        return Proton.shared.tokenContracts.first(where: { $0.id == self.tokenContractId })
    }
    
    public var tokenTransferActions: [TokenTransferAction] {
        return Proton.shared.tokenTransferActions.filter { $0.accountId == self.accountId && $0.tokenBalanceId == self.id }
    }
    
    public var account: Account? {
        if let acc = Proton.shared.activeAccount, acc.id == self.accountId {
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
