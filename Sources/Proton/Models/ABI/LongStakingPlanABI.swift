//
//  LongStakingPlanABI.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct LongStakingPlanABI: ABICodable {

    let index: UInt64
    let oracle_index: UInt64
    let plan_days: UInt64
    let multiplier: UInt64
    let is_stake_active: Bool
    let is_claim_active: Bool

}
