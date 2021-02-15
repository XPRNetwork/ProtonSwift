//
//  LongStakingPlanABI.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct LongStakingStakeABI: ABICodable {

    let index: UInt64
    let oracle_index: UInt64
    let account: Name
    let start_time: TimePoint
    let staked: Asset
    let oracle_price: Float64

}
