//
//  TokenContractCurrencyStatsABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import EOSIO
import Foundation

struct TokenContractCurrencyStatsABI: ABICodable {

    let supply: Asset
    let maxSupply: Asset
    let issuer: Name

}
