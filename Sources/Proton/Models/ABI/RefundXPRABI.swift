//
//  RefundXPRABI.swift
//  
//
//  Created by Jacob Davis on 8/26/20.
//

import EOSIO
import Foundation

public struct RefundXPRABI: ABICodable {

    public let owner: Name

    public init(owner: Name) {
        self.owner = owner
    }

    static let abi = ABI(
        structs: [
            ["refundxpr": [
                ["owner", "name"],
            ]],
        ],
        actions: ["refundxpr"]
    )

}
