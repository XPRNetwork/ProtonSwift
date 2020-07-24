//
//  VotersXPRABI.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct VotersXPRABI: ABICodable {

    let owner: Name
    let staked: UInt64
    let isqualified: Bool
    let claimamount: UInt64
    let lastclaim: UInt64
    
    let startstake: UInt64?
    let startqualif: Bool?

}
