//
//  OracleDataABI.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct OracleDataABI: ABICodable {
    
    struct DataVariant: ABICodable {
        let d_string: String?
        let d_uint64_t: UInt64?
        let d_double: Float64?
    }

    let feed_index: UInt64
    let aggregate: DataVariant

}

public struct OracleData: Codable {
    
    public let feedIndex: UInt64
    public let dDouble: Float64?
    
    public init(oracleDataABI: OracleDataABI) {
        self.feedIndex = oracleDataABI.feed_index
        self.dDouble = oracleDataABI.aggregate.d_double
    }
    
}
