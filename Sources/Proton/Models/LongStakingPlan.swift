//
//  LongStakingPlan.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct LongStakingPlan: Codable {
    
    let index: UInt64
    let oracleIndex: UInt64
    let planDays: UInt64
    let multiplier: UInt64
    let isStakeActive: Bool
    let isClaimActive: Bool
    
    init(longStakingPlanABI: LongStakingPlanABI) {
        self.index = longStakingPlanABI.index
        self.oracleIndex = longStakingPlanABI.oracle_index
        self.planDays = longStakingPlanABI.plan_days
        self.multiplier = longStakingPlanABI.multiplier
        self.isStakeActive = longStakingPlanABI.is_stake_active
        self.isClaimActive = longStakingPlanABI.is_claim_active
    }

}
