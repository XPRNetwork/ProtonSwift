//
//  Global4ABI.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct Global4ABI: ABICodable {
    
    let continuous_rate: Float64
    let inflation_pay_factor: Int64
    let votepay_factor: Int64
    
}
