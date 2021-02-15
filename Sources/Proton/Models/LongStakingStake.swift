//
//  LongStakingStake.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct LongStakingStake: Codable {
    
    let index: UInt64
    let oracleIndex: UInt64
    let account: Name
    let startTime: Date
    let staked: Asset
    let oraclePrice: Float64
    
    init(longStakingStakeABI: LongStakingStakeABI) {
        self.index = longStakingStakeABI.index
        self.oracleIndex = longStakingStakeABI.oracle_index
        self.account = longStakingStakeABI.account
        self.startTime = longStakingStakeABI.start_time.date
        self.staked = longStakingStakeABI.staked
        self.oraclePrice = longStakingStakeABI.oracle_price
    }

}
