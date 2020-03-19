//
//  TokenBalance.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public class TokenBalance: Codable, Identifiable, Hashable {

    public var id: String { return chainId+contract+symbol+accountId }
    
    public let accountId: String
    public let chainId: String
    public let contract: String
    public let symbol: String
    public let precision: Int
    
    public var amount: Double
    
    public init(accountId: String, chainId: String, contract: String, symbol: String,
                precision: Int, amount: Double) {
        
        self.accountId = accountId
        self.chainId = chainId
        self.contract = contract
        self.symbol = symbol
        self.precision = precision
        self.amount = amount
        
    }
    
}
