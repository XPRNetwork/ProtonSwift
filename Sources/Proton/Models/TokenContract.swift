//
//  TokenContract.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public struct TokenContract: Codable, Identifiable, Hashable {
    
    let chainId: String
    let contract: String
    let description: String
    let iconUrl: String
    let issuer: String
    let maxSupply: String
    let symbol: String
    let url: String
    let precision: Int
    let resourceToken: Bool
    let systemToken: Bool
    
    public var id: String { return chainId+contract+symbol }
    
}
