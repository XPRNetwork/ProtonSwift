//
//  SwapPoolsABI.swift
//  
//
//  Created by Jacob Davis on 12/8/20.
//

import EOSIO
import Foundation

struct SwapPoolsABI: ABICodable {
    let lt_symbol: Asset.Symbol
    let creator: Name
    let memo: String
    let pool1: ExtendedAsset
    let pool2: ExtendedAsset
    let hash: Checksum256
    let fee: SwapPoolFeeABI
    let active: Bool
    let reserved: UInt16
}

struct SwapPoolFeeABI: ABICodable {
    let exchange_fee: UInt64
    let add_liquidity_fee: UInt64
    let remove_liquidity_fee: UInt64
}
