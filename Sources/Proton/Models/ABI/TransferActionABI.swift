//
//  TransferActionABI.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

public struct TransferActionABI: ABICodable {

    public let from: Name
    public let to: Name
    public let quantity: Asset
    public let memo: String

    public init(from: Name, to: Name, quantity: Asset, memo: String = "") {
        self.from = from
        self.to = to
        self.quantity = quantity
        self.memo = memo
    }

    static let abi = ABI(
        structs: [
            ["transfer": [
                ["from", "name"],
                ["to", "name"],
                ["quantity", "asset"],
                ["memo", "string"],
            ]],
        ],
        actions: ["transfer"]
    )

}
