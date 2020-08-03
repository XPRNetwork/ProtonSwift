//
//  VoteProducersABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct VoteProducersABI: ABICodable {

    public let voter: Name
    public let proxy: Name
    public let producers: [Name]

    public init(voter: Name, proxy: Name = Name(""), producers: [Name]) {
        self.voter = voter
        self.proxy = proxy
        self.producers = producers
    }

    static let abi = ABI(
        structs: [
            ["voteproducer": [
                ["voter", "name"],
                ["proxy", "name"],
                ["producers", "name[]"],
            ]],
        ],
        actions: ["voteproducer"]
    )

}
