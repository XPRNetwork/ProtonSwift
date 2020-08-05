//
//  StakeXPRABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct StakeXPRABI: ABICodable {

    public let from: Name
    public let receiver: Name
    public let stake_xpr_quantity: Asset

    public init(from: Name, stake_xpr_quantity: Asset) {
        self.from = from
        self.receiver = from
        self.stake_xpr_quantity = stake_xpr_quantity
    }

    static let abi = ABI(
        structs: [
            ["stakexpr": [
                ["from", "name"],
                ["receiver", "name"],
                ["stake_xpr_quantity", "asset"]
            ]],
        ],
        actions: ["stakexpr"]
    )

}
