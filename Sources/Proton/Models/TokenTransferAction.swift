//
//  TokenTransferAction.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation
/**
The TokenTransferAction object provide information about a transfer action
*/
public struct TokenTransferAction: Codable, Identifiable, Hashable, ContactProtocol {
    /// id is the accountId + ":" + name + ":" + contract.stringValue + ":" + trxId
    public var id: String { return "\(accountId):\(name):\(contract.stringValue):\(trxId)" }
    /// The chainId associated with the TokenTransferAction
    public let chainId: String
    /// accountId is used to link Account. It is the chainId + ":" + name.stringValue.
    public let accountId: String
    /// tokenBalanceId is used to link TokenBalance. It is the accoutId + ":" + contract.stringValue + ":" + symbol
    public let tokenBalanceId: String
    /// tokenContractId is used to link TokenContract. It is the chainId + ":" + contract.stringValue + ":" + symbol
    public let tokenContractId: String
    /// The action name performed on the contract
    public let name: String
    /// The Name of the contract. You can get the string value via contract.stringValue
    public let contract: Name
    /// The transaction Id from the chain
    public let trxId: String
    /// The date in which the action was executed on chain
    public let date: Date
    /// Whether or not the action was sent based on the current account
    public let sent: Bool
    /// The Name of the receiving Account. You can get the string value via from.stringValue
    public let from: Name
    /// The Name of the sending Account. You can get the string value via from.stringValue
    public let to: Name
    /// The Asset quantity of the transfer. See EOSIO type Asset for more info
    public let quantity: Asset
    /// The memo string associated with the transfer
    public let memo: String
    /// :nodoc:
    public static func == (lhs: TokenTransferAction, rhs: TokenTransferAction) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    /// :nodoc:
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
    /// :nodoc:
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
    /// Returns the other Account Name whether it be sender or receiver
    public var other: Name {
        return self.sent ? self.to : self.from
    }
    /// Returns the other Account as a Contact whether it be sender or receiver
    public var contact: Contact? {
        return Proton.shared.contacts.first(where: { $0.chainId == self.chainId && $0.name == self.other })
    }

}
