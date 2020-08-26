//
//  GlobalsXPRABI.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct GlobalsXPRABI: ABICodable {

    let max_bp_per_vote: UInt64
    let min_bp_reward: UInt64
    let unstake_period: UInt64
    let process_by: UInt64
    let process_interval: UInt64
    let voters_claim_interval: UInt64

}
