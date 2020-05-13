//
//  TokenTransferAction.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

public struct TokenTransferAction: Codable, Identifiable, Hashable, ContactProtocol {

    public var id: String { return "\(accountId):\(name):\(contract.stringValue):\(trxId)" }

    public let chainId: String
    public let accountId: String
    public let tokenBalanceId: String
    public let tokenContractId: String

    public let name: String
    public let contract: Name
    public let trxId: String
    public let date: Date
    public let sent: Bool

    public let from: Name
    public let to: Name
    public let quantity: Asset
    public let memo: String

    public static func == (lhs: TokenTransferAction, rhs: TokenTransferAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init?(account: Account, tokenBalance: TokenBalance,
                 tokenContract: TokenContract, transferActionABI: TransferActionABI,
                 dictionary: [String: Any]) {

        guard let act = dictionary["act"] as? [String: Any] else { return nil }
        guard let name = act["name"] as? String else { return nil }
        guard let contract = act["account"] as? String else { return nil }
        guard let trxId = dictionary["trx_id"] as? String else { return nil }
        guard let timestamp = dictionary["@timestamp"] as? String,
            let date = Date.dateFromAction(timeStamp: timestamp) else { return nil }

        self.init(chainId: account.chainId, accountId: account.id, tokenBalanceId: tokenBalance.id,
                  tokenContractId: tokenContract.id, name: name, contract: Name(contract), trxId: trxId,
                  date: date, sent: account.name.stringValue == transferActionABI.from.stringValue ? true : false,
                  from: transferActionABI.from, to: transferActionABI.to, quantity: transferActionABI.quantity, memo: transferActionABI.memo)

    }

    init(chainId: String, accountId: String, tokenBalanceId: String, tokenContractId: String,
         name: String, contract: Name, trxId: String, date: Date, sent: Bool,
         from: Name, to: Name, quantity: Asset, memo: String) {

        self.chainId = chainId
        self.accountId = accountId
        self.tokenBalanceId = tokenBalanceId
        self.tokenContractId = tokenContractId
        self.name = name
        self.contract = contract
        self.trxId = trxId
        self.date = date
        self.sent = sent
        self.from = from
        self.to = to
        self.quantity = quantity
        self.memo = memo

    }
    
    public var other: Name {
        return self.sent ? self.to : self.from
    }
    
    public var contact: Contact? {
        return Proton.shared.contacts.first(where: { $0.chainId == self.chainId && $0.name == self.other })
    }

}
