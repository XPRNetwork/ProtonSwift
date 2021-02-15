//
//  Global4.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct Global4: Codable {
    
    public let continuousRate: Float64
    public let inflationPayFactor: Int64
    public let votepayFactor: Int64
    
    init(global4ABI: Global4ABI) {
        self.continuousRate = global4ABI.continuous_rate
        self.inflationPayFactor = global4ABI.inflation_pay_factor
        self.votepayFactor = global4ABI.votepay_factor
    }
}
