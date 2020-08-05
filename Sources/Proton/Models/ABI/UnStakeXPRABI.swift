//
//  UnStakeXPRABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation


public struct UnStakeXPRABI: ABICodable {

    public let from: Name
    public let receiver: Name
    public let unstake_xpr_quantity: Asset

    public init(from: Name, unstake_xpr_quantity: Asset) {
        self.from = from
        self.receiver = from
        self.unstake_xpr_quantity = unstake_xpr_quantity
    }

    static let abi = ABI(
        structs: [
            ["unstakexpr": [
                ["from", "name"],
                ["receiver", "name"],
                ["unstake_xpr_quantity", "asset"]
            ]],
        ],
        actions: ["unstakexpr"]
    )

}
