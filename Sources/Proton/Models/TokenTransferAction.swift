//
//  TokenTransferAction.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public class TokenTransferAction: Codable, Identifiable, Hashable {

    public var id: String { return "\(accountId):\(name):\(contract):\(trxId)" }
    
    public let chainId: String
    public let accountId: String
    public let tokenBalanceId: String
    public let tokenContractId: String

    public let precision: Int
    public let name: String
    public let contract: String
    public let trxId: String
    public let date: Date
    public let sent: Bool
    
    public let from: String
    public let to: String
    public let ammount: Double
    public let symbol: String
    public let quantity: String
    public let memo: String?

    public static func == (lhs: TokenTransferAction, rhs: TokenTransferAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public convenience init?(account: Account, tokenBalance: TokenBalance,
                             tokenContract: TokenContract, dictionary: [String: Any]) {

        guard let act = dictionary["act"] as? [String: Any] else { return nil }
        guard let data = act["data"] as? [String: Any] else { return nil }

        guard let name = act["name"] as? String else { return nil }
        guard let contract = act["account"] as? String else { return nil }
        guard let trxId = dictionary["trx_id"] as? String else { return nil }
        guard let timestamp = dictionary["@timestamp"] as? String,
            let date = Date.dateFromAction(timeStamp: timestamp) else { return nil }

        guard let from = data["from"] as? String else { return nil }
        guard let to = data["to"] as? String else { return nil }
        guard let ammount = data["amount"] as? Double else { return nil }
        guard let quantity = data["quantity"] as? String else { return nil }
        
        self.init(chainId: account.chainId, accountId: account.id, tokenBalanceId: tokenBalance.id,
                  tokenContractId: tokenContract.id, precision: tokenContract.precision, name: name,
                  contract: contract, trxId: trxId, date: date, sent: account.name == from ? true : false,
                  from: from, to: to, ammount: ammount, symbol: tokenContract.symbol, quantity: quantity,
                  memo: act["memo"] as? String)

    }
    
    private init(chainId: String, accountId: String, tokenBalanceId: String, tokenContractId: String,
                 precision: Int, name: String, contract: String, trxId: String, date: Date, sent: Bool,
                 from: String, to: String, ammount: Double, symbol: String, quantity: String, memo: String?) {
        
        self.chainId = chainId
        self.accountId = accountId
        self.tokenBalanceId = tokenBalanceId
        self.tokenContractId = tokenContractId
        self.precision = precision
        self.name = name
        self.contract = contract
        self.trxId = trxId
        self.date = date
        self.sent = sent
        self.from = from
        self.to = to
        self.ammount = ammount
        self.symbol = symbol
        self.quantity = quantity
        self.memo = memo
        
    }
    
}
