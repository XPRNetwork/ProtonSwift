//
//  LongStakeClaimABI.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct LongStakeClaimABI: ABICodable {

    public let account: Name
    public let stake_index: UInt64

    public init(account: Name, stake_index: UInt64) {
        self.account = account
        self.stake_index = stake_index
    }

    static let abi = ABI(
        structs: [
            ["claimstake": [
                ["account", "name"],
                ["stake_index", "uint64"]
            ]],
        ],
        actions: ["claimstake"]
    )

}
