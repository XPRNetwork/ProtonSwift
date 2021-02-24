//
//  LongStakingPlan.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct LongStakingPlan: Codable, Identifiable {
    
    public static let minimumStake: Double = 100.0
    
    public var id: UInt64 { return index }
    public let index: UInt64
    public let oracleIndex: UInt64
    public let planDays: UInt64
    public let multiplier: UInt64
    public let isStakeActive: Bool
    public let isClaimActive: Bool
    
    init(longStakingPlanABI: LongStakingPlanABI) {
        self.index = longStakingPlanABI.index
        self.oracleIndex = longStakingPlanABI.oracle_index
        self.planDays = longStakingPlanABI.plan_days
        self.multiplier = longStakingPlanABI.multiplier
        self.isStakeActive = longStakingPlanABI.is_stake_active
        self.isClaimActive = longStakingPlanABI.is_claim_active
    }

}
