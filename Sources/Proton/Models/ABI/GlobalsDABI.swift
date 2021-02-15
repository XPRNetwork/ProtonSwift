//
//  GlobalsDABI.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct GlobalsDABI: ABICodable {
    
    let totalstaked: Int64
    let totalrstaked: Int64
    let totalrvoters: Int64
    let notclaimed: Int64
    let pool: Int64
    let processtime: Int64
    let processtimeupd: Int64
    let isprocessing: Bool
    let processFrom: Name
    let processQuant: UInt64
    let processrstaked: UInt64
    let processed: UInt64
    let spare1: Int64
    let spare2: Int64
    
}
