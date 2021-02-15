//
//  TokenContractCurrencyStatsABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct TokenContractCurrencyStatsABI: ABICodable {
    let supply: Asset
    let max_supply: Asset
    let issuer: Name
}
