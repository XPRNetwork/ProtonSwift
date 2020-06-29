//
//  TokenContractABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import EOSIO
import Foundation

struct TokenContractABI: ABICodable {

    let id: UInt64
    let tcontract: Name
    let tname: String
    let url: String
    let desc: String
    let iconurl: String
    let symbol: Asset.Symbol
    let blisted: Bool

}
