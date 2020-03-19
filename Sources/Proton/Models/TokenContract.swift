//
//  TokenContract.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public struct TokenContract: Codable, Identifiable, Hashable {
    
    public let chainId: String
    public let contract: String
    public let description: String
    public let iconUrl: String
    public let issuer: String
    public let maxSupply: String
    public let symbol: String
    public let url: String
    public let precision: Int
    public let resourceToken: Bool
    public let systemToken: Bool
    
    public var id: String { return chainId+contract+symbol }
    
    public init(chainId: String, contract: String, description: String, iconUrl: String,
                  issuer: String, maxSupply: String, symbol: String, url: String, precision: Int,
                  resourceToken: Bool, systemToken: Bool) {
        
        self.chainId = chainId
        self.contract = contract
        self.description = description
        self.iconUrl = iconUrl
        self.issuer = issuer
        self.maxSupply = maxSupply
        self.symbol = symbol
        self.url = url
        self.precision = precision
        self.resourceToken = resourceToken
        self.systemToken = systemToken
        
    }
    
}
