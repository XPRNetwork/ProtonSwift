//
//  VoterClaimstABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct VoterClaimstABI: ABICodable {

    public let owner: Name

    public init(owner: Name) {
        self.owner = owner
    }

    static let abi = ABI(
        structs: [
            ["voterclaimst": [
                ["owner", "name"],
            ]],
        ],
        actions: ["voterclaimst"]
    )

}
