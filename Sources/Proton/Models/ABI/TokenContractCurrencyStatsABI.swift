//
//  TokenContractCurrencyStatsABI.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

struct TokenContractCurrencyStatsABI: ABICodable {
    
    let supply: Asset
    let maxSupply: Asset
    let issuer: Name
    
}
