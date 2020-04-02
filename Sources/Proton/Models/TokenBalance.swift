//
//  TokenBalance.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

protocol TokenBalancesProtocol {
    var tokenBalances: Set<TokenBalance> { get }
}

public struct TokenBalance: Codable, Identifiable, Hashable, TokenContractProtocol, TokenTransferActionsProtocol, AccountProtocol {

    public var id: String { return "\(accountId):\(contract):\(amount.symbol.name)" }
    
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
    
    public var tokenTransferActions: Set<TokenTransferAction> {
        return Proton.shared.tokenTransferActions.filter({ $0.accountId == self.accountId && $0.tokenBalanceId == self.id })
    }
    
    public var account: Account? {
        return Proton.shared.accounts.first(where: { $0.id == self.accountId })
    }
    
}
