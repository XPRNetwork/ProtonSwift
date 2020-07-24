//
//  VotersABI.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct VotersABI: ABICodable {

    let owner: Name
    let proxy: Name?
    let producers: [Name]
    let staked: Int64
    let last_vote_weight: Double
    let proxied_vote_weight: Double
    let is_proxy: Bool
    let flags1: UInt32
    let reserved2: UInt32
    let reserved3: Asset

}
